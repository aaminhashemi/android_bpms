import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl;
  static const String tokenKey = 'access_token';
  static const String infoKey = 'user_info';

  AuthService(this.baseUrl);

  Future<Map<String, dynamic>> login(String mobile, String password) async {
    final response = await http.post(Uri.parse('$baseUrl/login'), body: {
      'mobile': mobile,
      'password': password
    }, headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    });
    return json.decode(response.body);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<String?> getInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(infoKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> saveInfo(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(infoKey, userName);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<Uint8List?> fetchImageFromServer() async {
    final token = await this.getToken();
    try {
      final response =
          await http.get(Uri.parse('${baseUrl}/get-profile'), headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      });
      print(response);

      if (response.statusCode == 200) {
        print(response);
        return response.bodyBytes;
      } else {
        print(
            'Failed to fetch image from server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching image from server: $e');
    }
    return null;
  }

  Future<bool> isAccessTokenValid(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://afkhambpms.ir/api1/validate-token'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.headers['content-type'] == 'application/json') {
      return response.statusCode == 200;
    } else {
      return false;
    }
  }

  Future<void> logout() async {
    await removeToken();
  }

  Future<String> loadImageFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_picture_path');
      print('object');
      print(imagePath);
      print('object');
      if (imagePath != null) {
        return imagePath;
      } else {
        return 'assets/images/logo.png';
      }
    } catch (e) {
      return 'assets/images/logo.png';
    }
  }
}
