import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';

class UpdateService {
  final String baseUrl;

  UpdateService(this.baseUrl);

  Future<Map<String, dynamic>> check() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {'version': packageInfo.version},
    );
    return json.decode(response.body);
  }

  }