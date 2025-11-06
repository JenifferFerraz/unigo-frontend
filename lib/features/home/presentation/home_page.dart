import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/atoms/map/map_widget.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import './components/sidebar.dart';
import './components/location_search.dart';


class HomePage extends StatefulWidget {
  final bool showSearch;
  const HomePage({Key? key, this.showSearch = false}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedLayer = 0;
  bool _isFeedbackHovered = false;
  final List<String> _layerNames = [
    '1º Andar',
    '2º Andar',
    '3º Andar',
  ];

  void _toggleLayer() {
    setState(() {
      _selectedLayer = (_selectedLayer + 1) % _layerNames.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se é visitante pelos argumentos OU se não há usuário autenticado
    final hasVisitorArg = (Get.arguments != null && Get.arguments['visitor'] == true);
    final AuthService? authService = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final hasNoUser = authService?.currentUser.value == null;
    final isVisitor = hasVisitorArg || hasNoUser;

    LocationService? controller;
    try {
      controller = Get.find<LocationService>();
    } catch (e) {
      controller = null;
    }
    if (controller == null) {
      Future.microtask(() async {
        final loc = await Get.putAsync(() => LocationService().init());
        final hasPermission = await loc.requestLocationPermission();
        if (hasPermission == true) {
          await loc.getCurrentLocation();
        }
        setState(() {});
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    Future.microtask(() async {
      final hasPermission = await controller?.requestLocationPermission();
      if (hasPermission == true) {
        await controller?.getCurrentLocation();
      }
    });
   
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C3CC0),
        elevation: 0,
        leading: isVisitor
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.offAllNamed(AppRoutes.ACCESS_SELECTION),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset(
              'assets/images/Logo.png',
              height: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
      drawer: isVisitor ? null : Sidebar(),
      body: Stack(
        children: [
          SizedBox.expand(
            child: MapWidget(
              zoom: 15.0,
              showUserLocation: true,
              selectedLayer: _selectedLayer,
            ),
          ),
          if (widget.showSearch)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: LocationSearch(),
            ),
          // Visitor-only lateral Feedback tab
          if (isVisitor)
            Positioned(
              left: 0,
              top: MediaQuery.of(context).size.height * 0.60,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _isFeedbackHovered = true),
                onExit: (_) => setState(() => _isFeedbackHovered = false),
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed(AppRoutes.FEEDBACK, arguments: {'visitor': true});
                  },
                  onTapDown: (_) => setState(() => _isFeedbackHovered = true),
                  onTapUp: (_) => setState(() => _isFeedbackHovered = false),
                  onTapCancel: () => setState(() => _isFeedbackHovered = false),
                  child: AnimatedScale(
                    scale: _isFeedbackHovered ? 1.20 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3C3CC0),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(width: 6),
                            Text(
                              'Feedback',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btnLayer",
            onPressed: _toggleLayer,
            backgroundColor: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers, color: Colors.blue),
                Text(_layerNames[_selectedLayer], style: TextStyle(fontSize: 10, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "btnLocation",
            onPressed: () => controller?.getCurrentLocation(),
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

}
