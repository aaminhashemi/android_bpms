import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import './auth_service.dart';

class HomeService{
  final String baseUrl;
  HomeService(this.baseUrl);
  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  Future<Map<String, dynamic>> getStatistics() async {
    final token = await authService.getToken();

    final response = await http.get(Uri.parse('$baseUrl/get-statistics'), headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    });
    return json.decode(response.body);
  }
}