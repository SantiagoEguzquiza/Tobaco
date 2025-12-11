import 'User.dart';

class LoginResponse {
  final String token;
  final String refreshToken;
  final DateTime expiresAt;
  final int expiresIn;
  final User user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      refreshToken: json['refreshToken'] ?? '',
      expiresAt: DateTime.parse(json['expiresAt']),
      expiresIn: json['expiresIn'] ?? 1800, // Default 30 minutos en segundos
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'expiresIn': expiresIn,
      'user': user.toJson(),
    };
  }
}
