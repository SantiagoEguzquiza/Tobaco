import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tobaco/Theme/dialogs.dart';

/// URL del backend. Cambia solo aquí según dónde corras la app.
class ApiConfig {
  /// Backend en tu PC: celular y PC en la misma Wi‑Fi. Reemplaza por la IP de tu PC (ipconfig).
  static const String localUrl = 'http://192.168.0.101:5006';
  /// Backend en producción (Railway).
  static const String productionUrl = 'https://tobacoapi-production.up.railway.app';
}

class Apihandler {
  static final HttpClient httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

  static final IOClient client = IOClient(httpClient);

  /// En debug (celular/emulador): usa backend local. En release: producción.
  /// Para probar en celular: 1) Misma Wi‑Fi. 2) Backend con perfil "http". 3) ApiConfig.localUrl = IP de tu PC.
  static Uri get baseUrl {
    final url = kDebugMode ? ApiConfig.localUrl : ApiConfig.productionUrl;
    return Uri.parse(url);
  }

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
    final msg = error.toString().toLowerCase();
    if (msg.contains('clientexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('connection timed out') ||
        msg.contains('network is unreachable') ||
        msg.contains('software caused connection abort') ||
        msg.contains('timeoutexception') ||
        msg.contains('no se pudo conectar') ||
        msg.contains('conectar al servidor') ||
        msg.contains('disponibles offline') ||
        msg.contains('conecta para sincronizar')) {
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