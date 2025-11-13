import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tobaco/Theme/dialogs.dart';

class Apihandler {
  static final HttpClient httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

  static final IOClient client = IOClient(httpClient);

  static final baseUrl = Uri.parse(
      'https://10.0.2.2:7148'); // URL si es en emulador android usar 10.0.2.2:7148 
      //conexionSanti = https://192.168.1.10:7148

  static Future<bool> checkTokenAndFetchData(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tokenExpiryStr = prefs.getString('tokenExpiry');

    if (tokenExpiryStr != null) {
      DateTime tokenExpiry = DateTime.parse(tokenExpiryStr);

      if (DateTime.now().isAfter(tokenExpiry)) {
        return false;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  /// Verifica si un error es un error de conexión con el servidor
  static bool isConnectionError(dynamic error) {
    if (error is SocketException) {
      return true;
    }
    if (error is TimeoutException) {
      return true;
    }
    if (error is HandshakeException) {
      return true;
    }
    if (error.toString().contains('Failed host lookup') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Connection timed out') ||
        error.toString().contains('Network is unreachable') ||
        error.toString().contains('Software caused connection abort') ||
        error.toString().contains('TimeoutException')) {
      return true;
    }
    return false;
  }

  /// Maneja errores de conexión mostrando un diálogo al usuario
  static Future<void> handleConnectionError(BuildContext context, dynamic error) async {
    if (isConnectionError(error)) {
      await AppDialogs.showServerErrorDialog(context: context);
    } else {
      // Para otros tipos de errores, mostrar el diálogo de error genérico
      await AppDialogs.showErrorDialog(
        context: context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}