import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SaveLeaveRequestService {
  final String leaveRequestUrl;

  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  SaveLeaveRequestService(this.leaveRequestUrl);

  Future<Map<String, dynamic>> saveLeaveRequest(
      String request_date,
      String start_date,
      String end_date,
      String start_time,
      String end_time,
      String reason,
      String leave_period,
      String leave_type) async {
    final token = await authService.getToken();
    final response = await http.post(
      Uri.parse(leaveRequestUrl),
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
        'period': leave_period,
        'type': leave_type,
      }),
    );
    print(response.body);
    return json.decode(response.body);
  }
}
