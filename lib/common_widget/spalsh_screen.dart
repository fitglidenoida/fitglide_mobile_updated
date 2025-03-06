import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  final Future<void> Function() onLoadComplete;

  const SplashScreen({super.key, required this.onLoadComplete});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      onLoadComplete();
    });

    return Scaffold(
      backgroundColor: TColor.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/img/fitglide_logo.png",
              width: 350,
              height: 114,
              fit: BoxFit.contain,
            ).animate(
              effects: [
                FadeEffect(duration: 1000.ms, curve: Curves.easeInOut),
                ScaleEffect(
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TColor.primary),
            ).animate(
              effects: [
                FadeEffect(
                    duration: 800.ms, delay: 200.ms, curve: Curves.easeIn),
              ],
            ),
          ],
        ),
      ),
    );
  }
}