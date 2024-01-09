import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class SaveMissionRequestService {
  final String missionUrl;

  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  SaveMissionRequestService(this.missionUrl);

  Future<Map<String, dynamic>> saveMissionRequest(
      String request_date,
      String start_date,
      String end_date,
      String start_time,
      String end_time,
      String reason,
      String leave_type) async {
    final token = await authService.getToken();
    final response = await http.post(
      Uri.parse(missionUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: jsonEncode({
        'request_date': request_date,
        'start_date': start_date,
        'end_date': end_date,
        'start_time': start_time,
        'end_time': end_time,
        'reason': reason,
        'type': leave_type,
      }),
    );
    return json.decode(response.body);
  }
}
