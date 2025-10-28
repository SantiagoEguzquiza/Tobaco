import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tobaco/Theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Image.asset(
          'Assets/images/LogoIntro.png',
          width: 100,  // Logo más pequeño - 100 píxeles de ancho
          height: 100, // Logo más pequeño - 100 píxeles de alto
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

