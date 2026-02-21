import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';

import '../../../../core/services/installed_apps_channel.dart';
import '../../../../core/models/app_info_model.dart';

class AppMonitorRepository {
  /// Get installed apps
  Future<List<AppInfoModel>> getInstalledApps() async {
    try {
      // Only Android
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final apps = await InstalledAppsChannel.getInstalledApps();

        debugPrint(
          'AppMonitorRepository: Received ${apps.length} apps from native channel',
        );

        return apps.map((app) {
          Uint8List? icon;

          if (app['icon'] != null && app['icon'].toString().isNotEmpty) {
            try {
              icon = base64Decode(app['icon']);
            } catch (e) {
              debugPrint('Icon decode error for ${app['name']}: $e');
            }
          }

          return AppInfoModel(
            name: app['name'] ?? '',
            packageName: app['packageName'] ?? '',
            icon: icon,
            isSystemApp: app['isSystemApp'] ?? false,
          );
        }).toList();
      }

      // Not Android
      debugPrint('Non-Android platform → returning mock apps');
      return MockApps.getMockApps();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching installed apps: $e');
      debugPrint('StackTrace: $stackTrace');
      return MockApps.getMockApps();
    }
  }

  /// Start monitoring
  Future<bool> startMonitoring(List<AppInfoModel> selectedApps) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('Monitoring started for ${selectedApps.length} apps');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting monitoring: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Stop monitoring (API Call)
  Future<bool> stopMonitoring() async {
    try {
      final dio = Dio();

      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      final response = await dio.get(
        'http://172.18.118.215:5000/api/logs/activity',
        // GET requests do not have a body
      );

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Data: ${response.data}');

      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ Dio error: ${e.message}');
      debugPrint('Response: ${e.response}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Unknown error stopping monitoring: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }

  /// Check foreground app (Mock)
  Future<bool> isAppInForeground(String packageName) async {
    try {
      debugPrint('Checking foreground for $packageName');
      return false;
    } catch (e) {
      debugPrint('Error checking foreground app: $e');
      return false;
    }
  }

  /// Post suspicious activity logs to backend (forced log)
  Future<bool> postSuspiciousActivity({
    required String userId,
    required String deviceId,
    required List<Map<String, dynamic>> actions,
    String? location,
    String? sessionName,
    DateTime? timestamp,
    bool forceLog = false, // new flag
  }) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      // Log payload regardless of validation
      final payload = {
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        'user_id': userId,
        'device_id': deviceId,
        if (location != null) 'location': location,
        if (sessionName != null) 'session_name': sessionName,
        'actions': actions,
      };
      debugPrint('POST Payload (forced): $payload');
      debugPrint('Calling API: http://172.18.118.215:5000/api/logs/activity');

      // Validate actions array unless forceLog is true
      if (!forceLog) {
        if (actions.isEmpty) {
          debugPrint('❌ Invalid actions payload: actions array is empty');
          return false;
        }
        for (int i = 0; i < actions.length; i++) {
          final a = actions[i];
          if (a['name'] == null || a['name'].toString().isEmpty) {
            debugPrint('❌ Action[$i] missing name: $a');
            return false;
          }
          if (a['resource'] == null || a['resource'].toString().isEmpty) {
            debugPrint('❌ Action[$i] missing resource: $a');
            return false;
          }
          if (a['duration_seconds'] == null) {
            debugPrint('❌ Action[$i] missing duration_seconds: $a');
            return false;
          }
          if (a['result'] == null || a['result'].toString().isEmpty) {
            debugPrint('❌ Action[$i] missing result: $a');
            return false;
          }
        }
      }

      // Always attempt POST
      final response = await dio.post(
        'http://172.18.118.215:5000/api/logs/activity',
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      debugPrint('POST API Response Status: ${response.statusCode}');
      debugPrint('POST API Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Log successfully sent to backend.');
        return true;
      } else {
        debugPrint(
          '❌ Backend responded with error status: ${response.statusCode}',
        );
        debugPrint('❌ Backend error response: ${response.data}');
        return false;
      }
    } on DioException catch (e) {
      debugPrint('❌ Dio POST error: ${e.message}');
      debugPrint('Response: ${e.response}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Unknown error posting activity: $e');
      debugPrint('StackTrace: $stackTrace');
      return false;
    }
  }
}
