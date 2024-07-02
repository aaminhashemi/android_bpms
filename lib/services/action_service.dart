import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ActionService {
  final String baseUrl;
  //static const String distanceKey = 'threshold_distance';
  static const String lastActionTypeKey = 'last_action_type';
  static const String lastActionTime = 'last_action_time';
  static const String lastActionDate = 'last_action_date';
  static const String lastActionDescriptionKey = 'last_action_description';
  static const String thresholdDistanceKey = 'threshold_distance';

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

  Future<Map<String, dynamic>> saveManual(
      String date, String time, String type, String description) async {
    final token = await authService.getToken();
    final response = await http.post(Uri.parse('$baseUrl/save-manual-action'),
        body: jsonEncode({
          'date': date,
          'time': time,
          'type': type,
          'description': description
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    print(response.body);
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getLastActionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {'distance': prefs.getString(thresholdDistanceKey) ??'50', 'type': prefs.getString(lastActionTypeKey), 'description': prefs.getString(lastActionDescriptionKey), 'date': prefs.getString(lastActionDate)??'', 'time': prefs.getString(lastActionTime)??''};
  }

  Future<Map<String, dynamic>> updateManual(String type , String status, String description) async {
    final token = await authService.getToken();
    final response = await http.post(Uri.parse('$baseUrl/update-manual-action'),
        body: jsonEncode({
          //'date': date,
          //'time': time,
          'type': type,
          'status': status,
          'description': description
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    print(response.body);
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateForgetManual(String date , String time,String type , String status, String? description) async {
    final token = await authService.getToken();
    final response = await http.post(Uri.parse('$baseUrl/update-forget-manual-action'),
        body: jsonEncode({
          'date': date,
          'time': time,
          'type': type,
          'status': status,
          'description': description
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        });
    return json.decode(response.body);
  }

  Future<String> getLastActionType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastActionTypeKey)??'';
  }

  Future<void> saveLastActionType(String lastActionType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastActionTypeKey, lastActionType);
  }

  Future<String> getLastActionDescription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastActionDescriptionKey)??'';
  }

  Future<void> saveLastActionDescription(String lastActionDescription) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastActionDescriptionKey, lastActionDescription);
  }

  Future<double> getThresholdDistance() async {
    final prefs = await SharedPreferences.getInstance();
    print('hig');
    final String? thresholdDistanceStr = prefs.getString(thresholdDistanceKey);
    print(thresholdDistanceStr);
    double defaultThresholdDistance = 50.0; // Default value

    if (thresholdDistanceStr != null) {
      try {
        return double.parse(thresholdDistanceStr);
      } catch (e) {
        return defaultThresholdDistance;
      }
    }
    return defaultThresholdDistance;
  }

  Future<void> saveThresholdDistance(String thresholdDistance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(thresholdDistanceKey, thresholdDistance);
  }

}
