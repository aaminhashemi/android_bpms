import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  final String baseUrl;

  UpdateService(this.baseUrl);

  Future<Map<String, dynamic>> check() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final response = await http.post(
      Uri.parse(baseUrl),
      body: jsonEncode({'version': packageInfo.version}),
    );
    return json.decode(response.body);
  }
}
