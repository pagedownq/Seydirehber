import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<AppLog> _logs = [];
  List<AppLog> get logs => List.unmodifiable(_logs.reversed);

  void log(String message, {LogType type = LogType.info, dynamic error, StackTrace? stackTrace}) {
    final timestamp = DateTime.now();
    final logEntry = AppLog(
      message: message,
      timestamp: timestamp,
      type: type,
      error: error?.toString(),
    );
    
    _logs.add(logEntry);
    if (_logs.length > 500) _logs.removeAt(0);
    
    if (kDebugMode) {
      final emoji = {
        LogType.info: 'ℹ️',
        LogType.warning: '⚠️',
        LogType.error: '❌',
        LogType.success: '✅',
        LogType.notification: '🔔',
      }[type];
      debugPrint('$emoji [${type.name.toUpperCase()}] $message');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null) debugPrint('   StackTrace: $stackTrace');
    }
  }

  void info(String message) => log(message, type: LogType.info);
  void warning(String message) => log(message, type: LogType.warning);
  void error(String message, {dynamic error, StackTrace? stackTrace}) => 
      log(message, type: LogType.error, error: error, stackTrace: stackTrace);
  void success(String message) => log(message, type: LogType.success);
  void notification(String message) => log(message, type: LogType.notification);

  void clear() => _logs.clear();
}

enum LogType { info, warning, error, success, notification }

class AppLog {
  final String message;
  final DateTime timestamp;
  final LogType type;
  final String? error;

  AppLog({
    required this.message,
    required this.timestamp,
    required this.type,
    this.error,
  });
}
