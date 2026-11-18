import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/api_config.dart';

class SettingsService {
  static Map<String, String> _cache = {};

  static Future<Map<String, String>> getSettings() async {
    if (_cache.isNotEmpty) return _cache;
    final url = Uri.parse('${ApiConfig.baseUrl}/items/app_settings');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['data'] ?? [];
        _cache = { for (var item in items) item['setting_key']: item['setting_value'] ?? '' };
        return _cache;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<String> getValue(String key, String defaultValue) async {
    final settings = await getSettings();
    return settings[key] ?? defaultValue;
  }

  static Color hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse('0x$hex'));
  }
}