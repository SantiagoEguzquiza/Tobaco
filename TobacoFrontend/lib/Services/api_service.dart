import '../Helpers/api_handler.dart';
import 'Auth_Service/auth_service.dart';

class ApiService {
  final Uri baseUrl = Apihandler.baseUrl;

  // Get authenticated headers for API requests
  Future<Map<String, String>> getAuthHeaders() async {
    return await AuthService.getAuthHeaders();
  }
}
