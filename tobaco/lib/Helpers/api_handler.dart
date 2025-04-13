import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Apihandler {
  static final HttpClient httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

  static final IOClient client = IOClient(httpClient);

  static final baseUrl =
      Uri.parse('https://10.0.2.2:7148'); // HTTPS con certificado autofirmado

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
}
