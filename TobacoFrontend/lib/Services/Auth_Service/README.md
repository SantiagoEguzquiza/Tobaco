# Authentication System

This directory contains the authentication system for the Tobaco Flutter app.

## Files

- `auth_service.dart` - Service for handling authentication API calls
- `auth_provider.dart` - Provider for managing authentication state
- `README.md` - This documentation file

## Models

The authentication system uses these models (located in `lib/Models/`):
- `User.dart` - User data model
- `LoginRequest.dart` - Login request model
- `LoginResponse.dart` - Login response model

## Usage

### 1. Authentication Provider

The `AuthProvider` is already integrated into the main app. It provides:

- `isAuthenticated` - Boolean indicating if user is logged in
- `currentUser` - Current user data
- `isLoading` - Loading state
- `errorMessage` - Error messages

### 2. Login Screen

The login screen is automatically shown when the user is not authenticated.

### 3. Using Authentication in Services

To use authentication headers in your API services:

```dart
import 'Auth_Service/auth_service.dart';

// In your service method:
Future<void> someApiCall() async {
  final headers = await AuthService.getAuthHeaders();
  final response = await Apihandler.client.get(
    Uri.parse('$baseUrl/endpoint'),
    headers: headers,
  );
  // ... rest of your code
}
```

### 4. Logout

Users can logout by clicking the "Configuración" button in the menu, which shows a logout dialog.

## API Endpoints

The authentication system expects these endpoints in your backend:

- `POST /api/auth/login` - Login endpoint
  - Request: `{ "userName": "string", "password": "string" }`
  - Response: `{ "token": "string", "expiresAt": "datetime", "user": {...} }`

## Token Management

- Tokens are automatically stored in SharedPreferences
- Token expiration is checked automatically
- Tokens are included in all authenticated API calls
- Tokens are cleared on logout
