import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class CustomPrinter extends LogPrinter {

  String loggingClass;
  CustomPrinter(this.loggingClass);

  @override
  List<String> log(LogEvent event,) {
    final color = _getColorForLevel(event.level);
    final logMessage =
        "[${event.level.name.toUpperCase()}] [$loggingClass] ${event.message}";

    return [
      color(logMessage),
    ];
  }

  String Function(String) _getColorForLevel(Level level) {
    switch (level) {
      case Level.debug:
        return (message) => '\x1B[34m$message\x1B[0m'; // Blue
      case Level.info:
        return (message) => '\x1B[36m$message\x1B[0m'; // Cyan
      case Level.warning:
        return (message) => '\x1B[33m$message\x1B[0m'; // Yellow
      case Level.error:
        return (message) => '\x1B[31m$message\x1B[0m'; // Red
      default:
        return (message) => message;
    }
  }
}