import 'package:flutter/material.dart';
import '../../features/home/presentation/components/sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const MainLayout({
    Key? key,
    required this.child,
    required this.title,
    this.actions,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 1000;

    Widget mainContent = Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3C3CC0),
        elevation: 0,
        title: Text(title),
        leading: isLargeScreen
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
        actions: actions ??
            [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 32,
                  color: Colors.white,
                ),
              ),
            ],
      ),
      body: child,
      floatingActionButton: floatingActionButton,
    );

    if (isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 300,
              child: Sidebar(),
            ),
            Expanded(child: mainContent),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Sidebar(),
      body: mainContent,
    );
  }
}
