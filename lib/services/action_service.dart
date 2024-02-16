import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ActionService {
  final String baseUrl;

  ActionService(this.baseUrl);

  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  Future<Map<String, dynamic>> save(
      String request_date, String type, String description) async {
    final token = await authService.getToken();
    final response = await http.post(Uri.parse('$baseUrl/save-action'),
        body: jsonEncode({
          'request_date': request_date,
          'type': type,
          'description': description
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    return json.decode(response.body);
  }

}
