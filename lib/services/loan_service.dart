import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LoanService {
  final String loanUrl;

  final AuthService authService = AuthService('https://afkhambpms.ir/api1');

  LoanService(this.loanUrl);

  Future<Map<String, dynamic>> save(
      String date, String value, String count, String description) async {
    final token = await authService.getToken();
    final response = await http.post(
      Uri.parse(loanUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: jsonEncode({
        'request_date': date,
        'requested_value': value,
        'requested_repayment_count': count,
        'description': description
      }),
    );
    return json.decode(response.body);
  }

  Future getPersonnelLoan() async {
    final token = await authService.getToken();
    final response = await http.get(Uri.parse(loanUrl), headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/x-www-form-urlencoded',
    });
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return [];
    }
  }
}
