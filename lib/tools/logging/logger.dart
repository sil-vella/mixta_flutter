import 'dart:developer' as developer;

class Logger {
  // Private constructor
  Logger._();

  // The single instance of Logger
  static final Logger _instance = Logger._();

  // Factory constructor to return the same instance
  factory Logger() {
    return _instance;
  }

  /// General log method
  void log(String message, {String name = 'AppLogger', Object? error, StackTrace? stackTrace, int level = 0}) {
    developer.log(message, name: name, error: error, stackTrace: stackTrace, level: level);
  }

  /// Log an informational message
  void info(String message) => log(message, level: 800);

  /// Log a debug message
  void debug(String message) => log(message, level: 500);

  /// Log an error message
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(message, level: 1000, error: error, stackTrace: stackTrace);
}
