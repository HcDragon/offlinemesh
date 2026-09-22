import 'dart:collection';
import '../core/constants/app_constants.dart';
import '../core/logging/mesh_logger.dart';

class DeduplicationManager {
  final int capacity;
  final LinkedHashSet<String> _seenMessageIds = LinkedHashSet<String>();

  DeduplicationManager({this.capacity = AppConstants.deduplicationCacheCapacity});

  /// Returns true if message is a duplicate and should be dropped.
  /// If new, records it and returns false.
  bool isDuplicate(String messageId) {
    if (_seenMessageIds.contains(messageId)) {
      MeshLogger().log(
        MeshLogType.messageDuplicate,
        'DeduplicationManager',
        'Duplicate packet suppressed: $messageId',
      );
      return true;
    }

    if (_seenMessageIds.length >= capacity) {
      _seenMessageIds.remove(_seenMessageIds.first);
    }
    _seenMessageIds.add(messageId);
    return false;
  }

  void markSeen(String messageId) {
    if (_seenMessageIds.length >= capacity) {
      _seenMessageIds.remove(_seenMessageIds.first);
    }
    _seenMessageIds.add(messageId);
  }

  int get size => _seenMessageIds.length;

  void clear() => _seenMessageIds.clear();
}
