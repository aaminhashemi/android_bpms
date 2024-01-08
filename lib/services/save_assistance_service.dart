import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class SaveAssistanceService {
  final String assistanceUrl;
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  SaveAssistanceService(this.assistanceUrl);


  Future<Map<String, dynamic>> saveAssistance(String date, String value) async {
    final token = await authService.getToken();
    final response = await http.post(
      Uri.parse(assistanceUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      body: jsonEncode({'date': date, 'value': value}),
    );
    //print(response.statusCode);
    return json.decode(response.body);
  }
}
