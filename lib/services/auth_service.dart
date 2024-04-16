import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl;
  static const String tokenKey = 'access_token';
  static const String infoKey = 'user_info';
  static const String codeKey = 'user_national_code';
  static const String maxAssistanceValueKey = 'max_assistance_value';

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

  Future<Map<String, dynamic>> checkMobile(String mobile) async {
    final response =
        await http.post(Uri.parse('$baseUrl/change-pass/check-mobile'),
            body: jsonEncode({
              'mobile': mobile,
            }),
            headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> otpCheckMobile(String mobile) async {
    final response =
        await http.post(Uri.parse('$baseUrl/login/otp-check-mobile'),
            body: jsonEncode({
              'mobile': mobile,
            }),
            headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> checkCode(String mobile, String code) async {
    final response =
        await http.post(Uri.parse('$baseUrl/change-pass/check-code'),
            body: jsonEncode({
              'mobile': mobile,
              'code': code,
            }),
            headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> otpCheckCode(String mobile, String code) async {
    final response =
        await http.post(Uri.parse('$baseUrl/login/otp-check-code'),
            body: jsonEncode({
              'mobile': mobile,
              'code': code,
            }),
            headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    return json.decode(response.body);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<String> getMaxAssistanceValue() async {
    final prefs = await SharedPreferences.getInstance();
    final String? max= prefs.getString(maxAssistanceValueKey);

    String defaultAssistanceValue = '20000000'; // Default value

    if (max != null) {
      return max;
    }
    return defaultAssistanceValue;
  }

  Future<Map<String, dynamic>> getInfo() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> dataArray = ['item1', 'item2', 'item3'];
    Map<String, List<String>> dataMap = {'yourKey': dataArray};
    return {'name': prefs.getString(infoKey), 'code': prefs.getString(codeKey)};
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> saveMaxAssistanceValue(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(maxAssistanceValueKey, token);
  }

  Future<void> saveInfo(String userName, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(infoKey, userName);
    await prefs.setString(codeKey, code);
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

  Future<Map<String, dynamic>> changePassword(String password) async {
    final accessToken = await getToken();
    final response = await http.post(
      Uri.parse('https://afkhambpms.ir/api1/change-pass/change-password'),
      body: jsonEncode({
        'password': password,
      }),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    return json.decode(response.body);
  }

  Future<void> logout() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('${baseUrl}/logout'), headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    });
    if (response.statusCode == 200) {
      await removeToken();
      try {
        final prefs = await SharedPreferences.getInstance();
        final imagePath = prefs.getString('profile_picture_path');
        File file = File(imagePath!);
        if (await file.exists()) {
          await file.delete();
          print('File deleted successfully.');
        } else {
          print('File does not exist.');
        }
        prefs.remove('profile_picture_path');
      } catch (e) {
        print('Error deleting file: $e');
      }
    }
  }

  Future<String> loadImageFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_picture_path');
      if (imagePath != null) {
        return imagePath;
      } else {
        return 'assets/images/ic_launcher.png';
      }
    } catch (e) {
      return 'assets/images/ic_launcher.png';
    }
  }
}
