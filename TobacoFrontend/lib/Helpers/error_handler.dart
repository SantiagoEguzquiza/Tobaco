import 'package:flutter/material.dart';

class ErrorHandler {
  static void mostrarError(BuildContext context, Object error) {
    final mensaje = error is Exception
        ? error.toString().replaceFirst('Exception: ', '')
        : 'Ocurrió un error inesperado en el servidor.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }
}