import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class UserService {
  final String baseUrl;

  UserService(this.baseUrl);

  Future<int> getUserId() async {
    final authService = AuthService(baseUrl);
    final token = await authService.getToken();

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/get-user'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> userData = json.decode(response.body);
          return userData['id'];
        } else {
          return 0;
        }
      } catch (error) {
        return 0;
      }
    } else {
      return 0;
    }
  }
}
