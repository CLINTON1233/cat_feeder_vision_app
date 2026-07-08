import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/status_model.dart';

class ApiService {
  Future<StatusModel> getStatus() async {
    final response = await http
        .get(Uri.parse(AppConfig.statusUrl))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return StatusModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Gagal ambil status (${response.statusCode})");
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.healthUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> triggerManualFeed() async {
    final response = await http
        .post(Uri.parse(AppConfig.feedManualUrl))
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 200;
  }
}
