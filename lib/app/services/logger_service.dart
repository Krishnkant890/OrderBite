import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class LoggerService extends GetxService {
  static LoggerService get to => Get.find();

  File? _logFile;
  bool _initialized = false;

  Future<LoggerService> init() async {
    if (_initialized) return this;
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app_logs.txt');
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
      _initialized = true;
      log('--- App Started: ${DateTime.now()} ---');
    } catch (e) {
      debugPrint('Error initializing LoggerService: $e');
    }
    return this;
  }

  Future<void> log(String message) async {
    if (!_initialized) await init();
    if (_logFile == null) return;

    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final logMessage = '[$timestamp] $message\n';

    // Print to console as well
    debugPrint(logMessage);

    try {
      await _logFile!.writeAsString(logMessage, mode: FileMode.append);
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    }
  }

  Future<void> shareLogs() async {
    if (!_initialized) await init();
    if (_logFile != null && await _logFile!.exists()) {
      final content = await _logFile!.readAsString();
      if (content.trim().isEmpty) {
        Get.snackbar('Logs', 'Log file is empty', 
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white);
        return;
      }
      await Share.shareXFiles([XFile(_logFile!.path)], text: 'App Logs');
    } else {
      Get.snackbar('Logs', 'No log file found', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white);
    }
  }

  Future<void> clearLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      await _logFile!.writeAsString('');
      log('--- Logs Cleared ---');
      Get.snackbar('Logs', 'Log file cleared', 
        snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class LogNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    LoggerService.to.log('Navigation Push: ${route.settings.name} (from: ${previousRoute?.settings.name})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    LoggerService.to.log('Navigation Pop: ${route.settings.name} (to: ${previousRoute?.settings.name})');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    LoggerService.to.log('Navigation Replace: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }
}
