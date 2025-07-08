import '../Helpers/api_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _apiKey = '8a18a0587d4729f9a7e113f354d296b1';
  static const String _interzoidUrl =
      'https://api.interzoid.com/convertcurrency';

  // Mantenemos tu baseUrl para otras llamadas
  final Uri baseUrl = Apihandler.baseUrl;

  Future<double> getUsdToUyuRate() async {
    final url =
        Uri.parse('$_interzoidUrl?license=$_apiKey&from=USD&to=UYU&amount=1');

    // Usamos el cliente seguro de ApiHandler
    final response = await Apihandler.client.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Manejo seguro de conversión
      if (data['Converted'] != null) {
        return double.tryParse(data['Converted'].toString()) ?? 0.0;
      } else {
        throw Exception('Formato de respuesta inválido: ${data}');
      }
    } else {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
