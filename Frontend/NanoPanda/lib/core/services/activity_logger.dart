import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ActivityLogger {
  static final ActivityLogger _instance = ActivityLogger._internal();
  factory ActivityLogger() => _instance;
  ActivityLogger._internal();

  final List<Map<String, dynamic>> _logs = [];

  void log(String action, {Map<String, dynamic>? details}) {
    _logs.add({
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'details': details ?? {},
    });
    _saveLogs();
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('activity_logs', jsonEncode(_logs));
  }

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsString = prefs.getString('activity_logs');
    if (logsString != null) {
      final loaded = jsonDecode(logsString);
      if (loaded is List) {
        _logs.clear();
        _logs.addAll(List<Map<String, dynamic>>.from(loaded));
      }
    }
  }

  List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);

  Future<void> clearLogs() async {
    _logs.clear();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('activity_logs');
  }

  Future<bool> sendLogsToApi() async {
    final url = Uri.parse('http://172.18.118.215:5000/api/logs/activity');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'logs': _logs}),
      );
      if (response.statusCode == 200) {
        await clearLogs();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
