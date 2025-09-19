import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Helpers/api_handler.dart';
import '../../Models/User.dart';
import '../Auth_Service/auth_service.dart';

class UserService {
  static const String _usersEndpoint = '/api/User';

  // Get all users (Admin only)
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await Apihandler.client.get(
        Apihandler.baseUrl.resolve('$_usersEndpoint/all'),
        headers: await _getAuthHeaders(),
      );

      print('UserService: Response status: ${response.statusCode}');
      print('UserService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        print('UserService: Parsed ${usersJson.length} users from JSON');
        final users = usersJson.map((json) => User.fromJson(json)).toList();
        for (var user in users) {
          print('UserService: User ${user.userName} - Active: ${user.isActive}');
        }
        return users;
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para acceder a esta funcionalidad');
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      print('UserService: Error getting users: $e');
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  // Create a new user (Admin only)
  static Future<User> createUser({
    required String userName,
    required String password,
    required String role,
    String? email,
  }) async {
    try {
      final userData = {
        'userName': userName,
        'password': password,
        'role': role,
        if (email != null) 'email': email,
      };

      final response = await Apihandler.client.post(
        Apihandler.baseUrl.resolve('$_usersEndpoint/create'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para crear usuarios');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al crear usuario';
        print('Backend error response: ${response.body}'); // Debug log
        print('Extracted error message: $errorMessage'); // Debug log
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  // Update a user (Admin only)
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? userName,
    String? password,
    String? role,
    String? email,
    bool? isActive,
  }) async {
    try {
      final userData = <String, dynamic>{};
      if (userName != null) userData['userName'] = userName;
      if (password != null) userData['password'] = password;
      if (role != null) userData['role'] = role;
      if (email != null) userData['email'] = email;
      if (isActive != null) userData['isActive'] = isActive;

      final response = await Apihandler.client.put(
        Apihandler.baseUrl.resolve('$_usersEndpoint/update/$userId'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'user': User.fromJson(responseData['user']),
          'currentUserAffected': responseData['currentUserAffected'] ?? false,
          'message': responseData['message'] ?? 'Usuario actualizado exitosamente',
        };
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para actualizar usuarios');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar usuario');
      }
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  // Delete a user (Admin only)
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final response = await Apihandler.client.delete(
        Apihandler.baseUrl.resolve('$_usersEndpoint/delete/$userId'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'currentUserAffected': responseData['currentUserAffected'] ?? false,
          'message': responseData['message'] ?? 'Usuario eliminado exitosamente',
        };
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para eliminar usuarios');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar usuario');
      }
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // Get auth headers with token
  static Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthService.getAuthHeaders();
  }
}
