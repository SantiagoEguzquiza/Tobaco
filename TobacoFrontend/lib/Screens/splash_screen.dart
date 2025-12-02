import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // Precargar la imagen
    _preloadImage();
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    });
  }

  Future<void> _preloadImage() async {
    try {
      await precacheImage(
        const AssetImage('Assets/images/LogoIntro.png'),
        context,
      );
      debugPrint('LogoIntro.png preloaded successfully');
    } catch (e) {
      debugPrint('Error preloading LogoIntro.png: $e');
      debugPrint('Make sure Assets/images/LogoIntro.png exists in pubspec.yaml');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 167, 55, 55),
      body: Center(
        child: Image.asset(
          'Assets/images/LogoIntro.png',
          width: 250,
          height: 250,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading LogoIntro.png: $error');
            debugPrint('Stack trace: $stackTrace');
            // Si hay error, no mostrar nada en lugar del icono de la app
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

