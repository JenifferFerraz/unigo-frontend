import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;
  const LoadingScreen({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3C3CC0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/Logo.png',
                height: 120,
                color: Colors.white,
              ),
              onEnd: () {},
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
