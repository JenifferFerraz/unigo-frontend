import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed(AppRoutes.ACCESS_SELECTION);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.7, end: 1.1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Opacity(
              opacity: scale.clamp(0.7, 1.0),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: Image.asset(
            'assets/images/Logo.png',
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
} 