import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl;
  static const String tokenKey = 'access_token';

  AuthService(this.baseUrl);

  Future<Map<String, dynamic>> register(String mobile, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: {'mobile': mobile, 'password': password},
    );

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> login(String mobile, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/login'), body: {
      'mobile': mobile,
      'password': password
    }, headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
      // Add other headers if required
    });

    return json.decode(response.body);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<bool> isAccessTokenValid(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://afkhambpms.ir/api1/validate-token'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.headers['content-type'] == 'application/json') {
      print(response.statusCode == 200);
      return response.statusCode == 200;
    } else {
      print('false');
      return false;
    }
  }

  Future<void> logout() async {
    await removeToken();
  }
}
