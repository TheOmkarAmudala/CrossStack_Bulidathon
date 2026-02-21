import 'dart:async';
import 'package:flutter/services.dart';

class InstalledAppsChannel {
  static const MethodChannel _channel = MethodChannel('installed_apps_channel');

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    final List<dynamic> apps = await _channel.invokeMethod('getInstalledApps');
    return apps.cast<Map<String, dynamic>>();
  }
}
