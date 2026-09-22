import '../core/constants/app_constants.dart';

class MeshRoute {
  final String sourceId;
  final String destinationId;
  final String nextHopId;
  final int hopCount;
  final double score;
  final DateTime lastUpdated;
  final double linkQuality; // 0.0 to 1.0 (based on RSSI/packet delivery)

  const MeshRoute({
    required this.sourceId,
    required this.destinationId,
    required this.nextHopId,
    required this.hopCount,
    required this.score,
    required this.lastUpdated,
    this.linkQuality = 1.0,
  });

  bool get isDirect => hopCount == 1;

  bool get isStale {
    final ageSeconds = DateTime.now().difference(lastUpdated).inSeconds;
    return ageSeconds > AppConstants.staleRouteThresholdSeconds;
  }

  static double calculateScore({
    required double linkQuality,
    required int hopCount,
    required int ageSeconds,
    required int batteryLevel,
    bool isDirect = false,
  }) {
    // connectivity score (0 to 30)
    final connectivity = linkQuality * AppConstants.connectivityWeight;

    // destination relevance (50 if direct or small hop, scales down)
    final destinationRelevance = isDirect ? AppConstants.destRelevanceWeight : (AppConstants.destRelevanceWeight / (hopCount > 0 ? hopCount : 1));

    // hop penalty
    final hopPenalty = (hopCount - 1).clamp(0, 16) * AppConstants.hopPenaltyPerHop;

    // stale penalty
    final stalePenalty = ageSeconds * AppConstants.stalePenaltyPerSecond;

    // battery penalty: if local or relay node has low battery, penalty increases
    final batteryDeficit = (100 - batteryLevel).clamp(0, 100);
    final batteryPenalty = (batteryDeficit / 100.0) * AppConstants.batteryPenaltyWeight;

    final totalScore = connectivity + destinationRelevance - hopPenalty - stalePenalty - batteryPenalty;
    return totalScore > 0.0 ? totalScore : 0.0;
  }

  MeshRoute copyWithScore({required int localBatteryLevel}) {
    final ageSeconds = DateTime.now().difference(lastUpdated).inSeconds;
    final newScore = calculateScore(
      linkQuality: linkQuality,
      hopCount: hopCount,
      ageSeconds: ageSeconds,
      batteryLevel: localBatteryLevel,
      isDirect: isDirect,
    );
    return MeshRoute(
      sourceId: sourceId,
      destinationId: destinationId,
      nextHopId: nextHopId,
      hopCount: hopCount,
      score: newScore,
      lastUpdated: lastUpdated,
      linkQuality: linkQuality,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'sourceId': sourceId,
      'destinationId': destinationId,
      'nextHopId': nextHopId,
      'hopCount': hopCount,
      'score': score,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'linkQuality': linkQuality,
    };
  }

  factory MeshRoute.fromDbMap(Map<String, dynamic> map) {
    return MeshRoute(
      sourceId: map['sourceId'] as String,
      destinationId: map['destinationId'] as String,
      nextHopId: map['nextHopId'] as String,
      hopCount: map['hopCount'] as int? ?? 1,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] as int),
      linkQuality: (map['linkQuality'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
