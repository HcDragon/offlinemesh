class AppConstants {
  static const int protocolVersion = 1;

  // TTL Settings
  static const int defaultTtl = 7;
  static const int maxTtl = 16;
  static const int sosTtl = 15;

  // Timeouts & Intervals (Seconds)
  static const int peerTimeoutSeconds = 60;
  static const int heartbeatIntervalSeconds = 15;
  static const int staleRouteThresholdSeconds = 45;
  static const int retryIntervalSeconds = 10;
  static const int maxRetryAttempts = 5;

  // Deduplication
  static const int deduplicationCacheCapacity = 2000;
  static const int deduplicationExpiryMinutes = 30;

  // Battery Thresholds
  static const int batterySaverThresholdPercent = 30;
  static const int criticalBatteryThresholdPercent = 15;

  // Routing Scoring Weights
  static const double connectivityWeight = 30.0;
  static const double destRelevanceWeight = 50.0;
  static const double hopPenaltyPerHop = 10.0;
  static const double stalePenaltyPerSecond = 0.5;
  static const double batteryPenaltyWeight = 20.0;

  // Storage
  static const String dbName = 'meshconnect.db';
  static const int dbVersion = 1;
}
