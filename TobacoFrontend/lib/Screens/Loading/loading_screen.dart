import 'package:flutter/material.dart';
import '../../Widgets/custom_loading_widget.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final bool showLogo;

  const LoadingScreen({
    super.key,
    this.message,
    this.backgroundColor,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomLoadingWidget(
        message: message ?? 'Cargando...',
        backgroundColor: backgroundColor,
        showLogo: showLogo,
        size: 120.0,
      ),
    );
  }
}

// Pantalla de carga para autenticación
class AuthLoadingScreen extends StatelessWidget {
  final String? message;

  const AuthLoadingScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 197, 197, 197),
              Color.fromARGB(255, 16, 58, 18),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomLoadingWidget(
          message: message ?? 'Verificando credenciales...',
          backgroundColor: Colors.transparent,
          showLogo: true,
          size: 120.0,
        ),
      ),
    );
  }
}

// Pantalla de carga para datos
class DataLoadingScreen extends StatelessWidget {
  final String? message;

  const DataLoadingScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomLoadingWidget(
        message: message ?? 'Cargando datos...',
        backgroundColor: Colors.grey.shade50,
        showLogo: true,
        size: 100.0,
      ),
    );
  }
}

// Pantalla de carga para operaciones
class OperationLoadingScreen extends StatelessWidget {
  final String? message;

  const OperationLoadingScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomLoadingWidget(
        message: message ?? 'Procesando...',
        backgroundColor: Colors.white,
        showLogo: false,
        size: 80.0,
      ),
    );
  }
}
