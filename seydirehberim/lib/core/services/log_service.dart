import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<AppLog> _logs = [];
  List<AppLog> get logs => List.unmodifiable(_logs.reversed);

  void log(String message, {LogType type = LogType.info, dynamic error}) {
    final timestamp = DateTime.now();
    final logEntry = AppLog(
      message: message,
      timestamp: timestamp,
      type: type,
      error: error?.toString(),
    );
    
    _logs.add(logEntry);
    if (_logs.length > 500) _logs.removeAt(0); // Hafızayı korumak için son 500 log
    
    debugPrint('[${type.name.toUpperCase()}] $message');
  }

  void clear() => _logs.clear();
}

enum LogType { info, warning, error, success }

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
