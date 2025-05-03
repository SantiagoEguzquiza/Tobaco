import 'package:flutter/material.dart';

class VentaConfirmadaAnimacion extends StatefulWidget {
  final VoidCallback onFinish;

  const VentaConfirmadaAnimacion({super.key, required this.onFinish});

  @override
  State<VentaConfirmadaAnimacion> createState() =>
      _VentaConfirmadaAnimacionState();
}

class _VentaConfirmadaAnimacionState extends State<VentaConfirmadaAnimacion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _radiusAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Espera 2 segundos luego de la animación para continuar
    Future.delayed(const Duration(seconds: 4), () {
      widget.onFinish();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _radiusAnimation,
      builder: (context, child) {
        return SizedBox.expand(
          child: ClipPath(
            clipper: CircleRevealClipper(_radiusAnimation.value),
            child: Container(
              color: Colors.green,
              child: const Center(
                child: Icon(Icons.check, size: 100, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CircleRevealClipper extends CustomClipper<Path> {
  final double scale;

  CircleRevealClipper(this.scale);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final finalRadius = size.longestSide * scale;
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: finalRadius));
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) => true;
}
