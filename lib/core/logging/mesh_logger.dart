import 'dart:collection';
import 'package:flutter/foundation.dart';

enum MeshLogType {
  discovery,
  peerConnected,
  peerDisconnected,
  messageCreated,
  messageEncrypted,
  messageQueued,
  messageForwarded,
  messageDuplicate,
  messageDelivered,
  ackReceived,
  sosCreated,
  sosRelayed,
  routeUpdated,
  batteryModeChanged,
  error,
}

class LogEntry {
  final DateTime timestamp;
  final MeshLogType type;
  final String tag;
  final String message;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.type,
    required this.tag,
    required this.message,
    this.metadata,
  });

  @override
  String toString() {
    return '[${timestamp.toIso8601String()}] [${type.name.toUpperCase()}] $tag: $message';
  }
}

class MeshLogger {
  static final MeshLogger _instance = MeshLogger._internal();
  factory MeshLogger() => _instance;
  MeshLogger._internal();

  final ListQueue<LogEntry> _recentLogs = ListQueue<LogEntry>(500);
  final List<void Function(LogEntry)> _listeners = [];

  List<LogEntry> get logs => List.unmodifiable(_recentLogs.toList());

  void addListener(void Function(LogEntry) listener) => _listeners.add(listener);
  void removeListener(void Function(LogEntry) listener) => _listeners.remove(listener);

  void log(
    MeshLogType type,
    String tag,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    // Sanitize metadata to never include private keys or sensitive plaintext
    final sanitizedMetadata = _sanitize(metadata);

    final entry = LogEntry(
      timestamp: DateTime.now(),
      type: type,
      tag: tag,
      message: message,
      metadata: sanitizedMetadata,
    );

    if (_recentLogs.length >= 500) {
      _recentLogs.removeFirst();
    }
    _recentLogs.addLast(entry);

    if (kDebugMode) {
      debugPrint(entry.toString());
    }

    for (final listener in _listeners) {
      listener(entry);
    }
  }

  Map<String, dynamic>? _sanitize(Map<String, dynamic>? data) {
    if (data == null) return null;
    final clean = <String, dynamic>{};
    for (final entry in data.entries) {
      final keyLower = entry.key.toLowerCase();
      if (keyLower.contains('key') ||
          keyLower.contains('secret') ||
          keyLower.contains('password') ||
          keyLower.contains('plaintext')) {
        clean[entry.key] = '[REDACTED]';
      } else {
        clean[entry.key] = entry.value;
      }
    }
    return clean;
  }
}
