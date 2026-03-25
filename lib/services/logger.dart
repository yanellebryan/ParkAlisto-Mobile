import 'package:flutter/foundation.dart';

/// Centralized logger for the Park Alisto app to keep the terminal cleaner.
class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('Detail: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      // Use a distinct prefix for easy filtering
      debugPrint('PA_DEBUG: $message');
    }
  }
}
