import 'dart:async';
import 'dart:collection';
import '/utils/performance_monitor.dart';

/// Performance monitoring service for real-time data synchronization
/// Implements requirement 5.6: Add performance monitoring for sync operations
class SyncPerformanceMonitor {
  static final SyncPerformanceMonitor _instance = SyncPerformanceMonitor._internal();
  factory SyncPerformanceMonitor() => _instance;
  SyncPerformanceMonitor._internal();

  static SyncPerformanceMonitor get instance => _instance;

  // Performance metrics storage
  final Map<String, List<SyncMetric>> _syncMetrics = {};
  final Map<String, DateTime> _lastSyncTimes = {};
  final Map<String, int> _syncFailureCounts = {};
  final Map<String, Duration> _averageSyncTimes = {};

  // Configuration
  static const int maxMetricsPerType = 100;
  static const Duration syncTimeoutThreshold = Duration(seconds: 10);
  static const Duration staleDataThreshold = Duration(minutes: 5);

  /// Record a sync operation start
  String startSyncOperation(String operationType, {Map<String, dynamic>? metadata}) {
    final operationId = '${operationType}_${DateTime.now().millisecondsSinceEpoch}';
    final metric = SyncMetric(
      operationId: operationId,
      operationType: operationType,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
    );

    _syncMetrics.putIfAbsent(operationType, () => <SyncMetric>[]);
    _syncMetrics[operationType]!.add(metric);

    // Keep only recent metrics to prevent memory leaks
    if (_syncMetrics[operationType]!.length > maxMetricsPerType) {
      _syncMetrics[operationType]!.removeAt(0);
    }

    return operationId;
  }

  /// Record a sync operation completion
  void completeSyncOperation(String operationId, {
    bool success = true,
    String? errorMessage,
    int? recordsProcessed,
    Map<String, dynamic>? additionalMetadata,
  }) {
    final operationType = operationId.split('_')[0];
    final metrics = _syncMetrics[operationType];
    
    if (metrics != null) {
      final metric = metrics.firstWhere(
        (m) => m.operationId == operationId,
        orElse: () => SyncMetric(
          operationId: operationId,
          operationType: operationType,
          startTime: DateTime.now(),
        ),
      );

      metric.endTime = DateTime.now();
      metric.success = success;
      metric.errorMessage = errorMessage;
      metric.recordsProcessed = recordsProcessed;
      
      if (additionalMetadata != null) {
        metric.metadata.addAll(additionalMetadata);
      }

      // Update last sync time on success
      if (success) {
        _lastSyncTimes[operationType] = DateTime.now();
        _syncFailureCounts[operationType] = 0;
      } else {
        _syncFailureCounts[operationType] = (_syncFailureCounts[operationType] ?? 0) + 1;
      }

      // Update average sync time
      _updateAverageSyncTime(operationType);
    }
  }

  /// Get sync performance metrics for a specific operation type
  SyncPerformanceStats getPerformanceStats(String operationType) {
    final metrics = _syncMetrics[operationType] ?? [];
    final recentMetrics = metrics.where((m) => 
      m.endTime != null && 
      DateTime.now().difference(m.endTime!) < Duration(hours: 1)
    ).toList();

    if (recentMetrics.isEmpty) {
      return SyncPerformanceStats(
        operationType: operationType,
        totalOperations: 0,
        successfulOperations: 0,
        failedOperations: 0,
        averageDuration: Duration.zero,
        lastSyncTime: _lastSyncTimes[operationType],
        isStale: isDataStale(operationType),
        consecutiveFailures: _syncFailureCounts[operationType] ?? 0,
      );
    }

    final successful = recentMetrics.where((m) => m.success).length;
    final failed = recentMetrics.length - successful;
    
    final durations = recentMetrics
        .where((m) => m.duration != null)
        .map((m) => m.duration!)
        .toList();
    
    final averageDuration = durations.isNotEmpty
        ? Duration(microseconds: (durations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / durations.length).round())
        : Duration.zero;

    return SyncPerformanceStats(
      operationType: operationType,
      totalOperations: recentMetrics.length,
      successfulOperations: successful,
      failedOperations: failed,
      averageDuration: averageDuration,
      lastSyncTime: _lastSyncTimes[operationType],
      isStale: isDataStale(operationType),
      consecutiveFailures: _syncFailureCounts[operationType] ?? 0,
      minDuration: durations.isNotEmpty ? durations.reduce((a, b) => a < b ? a : b) : Duration.zero,
      maxDuration: durations.isNotEmpty ? durations.reduce((a, b) => a > b ? a : b) : Duration.zero,
      recentErrors: recentMetrics
          .where((m) => !m.success && m.errorMessage != null)
          .map((m) => m.errorMessage!)
          .toList(),
    );
  }

  /// Check if data for a specific operation type is stale
  bool isDataStale(String operationType) {
    final lastSync = _lastSyncTimes[operationType];
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > staleDataThreshold;
  }

  /// Get overall sync health status
  SyncHealthStatus getOverallHealth() {
    final allOperationTypes = _syncMetrics.keys.toList();
    if (allOperationTypes.isEmpty) {
      return SyncHealthStatus(
        isHealthy: false,
        issues: ['No sync operations recorded'],
        recommendations: ['Initialize data synchronization'],
      );
    }

    final issues = <String>[];
    final recommendations = <String>[];
    int healthyOperations = 0;

    for (final operationType in allOperationTypes) {
      final stats = getPerformanceStats(operationType);
      
      // Check for stale data
      if (stats.isStale) {
        issues.add('$operationType data is stale (last sync: ${stats.lastSyncTime})');
        recommendations.add('Refresh $operationType data');
      }

      // Check for high failure rate
      if (stats.totalOperations > 0 && stats.failedOperations / stats.totalOperations > 0.2) {
        issues.add('$operationType has high failure rate (${(stats.failedOperations / stats.totalOperations * 100).toStringAsFixed(1)}%)');
        recommendations.add('Check network connectivity and Firestore permissions for $operationType');
      }

      // Check for consecutive failures
      if (stats.consecutiveFailures > 3) {
        issues.add('$operationType has ${stats.consecutiveFailures} consecutive failures');
        recommendations.add('Investigate $operationType sync issues');
      }

      // Check for slow sync times
      if (stats.averageDuration > syncTimeoutThreshold) {
        issues.add('$operationType sync is slow (avg: ${stats.averageDuration.inSeconds}s)');
        recommendations.add('Optimize $operationType queries or check network performance');
      }

      if (issues.isEmpty) {
        healthyOperations++;
      }
    }

    return SyncHealthStatus(
      isHealthy: issues.isEmpty,
      issues: issues,
      recommendations: recommendations,
      healthyOperations: healthyOperations,
      totalOperations: allOperationTypes.length,
    );
  }

  /// Get detailed metrics for debugging
  Map<String, dynamic> getDetailedMetrics() {
    final result = <String, dynamic>{};
    
    for (final operationType in _syncMetrics.keys) {
      final stats = getPerformanceStats(operationType);
      result[operationType] = {
        'stats': stats.toMap(),
        'recentMetrics': _syncMetrics[operationType]!
            .where((m) => m.endTime != null && DateTime.now().difference(m.endTime!) < Duration(minutes: 30))
            .map((m) => m.toMap())
            .toList(),
      };
    }

    return result;
  }

  /// Clear old metrics to prevent memory leaks
  void cleanupOldMetrics() {
    final cutoffTime = DateTime.now().subtract(Duration(hours: 24));
    
    for (final operationType in _syncMetrics.keys.toList()) {
      _syncMetrics[operationType]!.removeWhere((metric) => 
        metric.startTime.isBefore(cutoffTime)
      );
      
      if (_syncMetrics[operationType]!.isEmpty) {
        _syncMetrics.remove(operationType);
        _lastSyncTimes.remove(operationType);
        _syncFailureCounts.remove(operationType);
        _averageSyncTimes.remove(operationType);
      }
    }
  }

  /// Update average sync time for an operation type
  void _updateAverageSyncTime(String operationType) {
    final metrics = _syncMetrics[operationType] ?? [];
    final recentSuccessfulMetrics = metrics
        .where((m) => m.success && m.duration != null && DateTime.now().difference(m.startTime) < Duration(hours: 1))
        .toList();

    if (recentSuccessfulMetrics.isNotEmpty) {
      final totalMicroseconds = recentSuccessfulMetrics
          .map((m) => m.duration!.inMicroseconds)
          .reduce((a, b) => a + b);
      
      _averageSyncTimes[operationType] = Duration(
        microseconds: (totalMicroseconds / recentSuccessfulMetrics.length).round()
      );
    }
  }

  /// Start periodic cleanup of old metrics
  Timer startPeriodicCleanup() {
    return Timer.periodic(Duration(hours: 1), (_) => cleanupOldMetrics());
  }
}

/// Individual sync operation metric
class SyncMetric {
  final String operationId;
  final String operationType;
  final DateTime startTime;
  DateTime? endTime;
  bool success = false;
  String? errorMessage;
  int? recordsProcessed;
  final Map<String, dynamic> metadata;

  SyncMetric({
    required this.operationId,
    required this.operationType,
    required this.startTime,
    this.endTime,
    this.success = false,
    this.errorMessage,
    this.recordsProcessed,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'operationType': operationType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'success': success,
      'errorMessage': errorMessage,
      'recordsProcessed': recordsProcessed,
      'metadata': metadata,
    };
  }
}

/// Performance statistics for a sync operation type
class SyncPerformanceStats {
  final String operationType;
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final Duration averageDuration;
  final DateTime? lastSyncTime;
  final bool isStale;
  final int consecutiveFailures;
  final Duration? minDuration;
  final Duration? maxDuration;
  final List<String> recentErrors;

  SyncPerformanceStats({
    required this.operationType,
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.averageDuration,
    required this.lastSyncTime,
    required this.isStale,
    required this.consecutiveFailures,
    this.minDuration,
    this.maxDuration,
    this.recentErrors = const [],
  });

  double get successRate {
    if (totalOperations == 0) return 0.0;
    return successfulOperations / totalOperations;
  }

  Map<String, dynamic> toMap() {
    return {
      'operationType': operationType,
      'totalOperations': totalOperations,
      'successfulOperations': successfulOperations,
      'failedOperations': failedOperations,
      'successRate': successRate,
      'averageDuration': averageDuration.inMilliseconds,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'isStale': isStale,
      'consecutiveFailures': consecutiveFailures,
      'minDuration': minDuration?.inMilliseconds,
      'maxDuration': maxDuration?.inMilliseconds,
      'recentErrors': recentErrors,
    };
  }
}

/// Overall sync health status
class SyncHealthStatus {
  final bool isHealthy;
  final List<String> issues;
  final List<String> recommendations;
  final int? healthyOperations;
  final int? totalOperations;

  SyncHealthStatus({
    required this.isHealthy,
    required this.issues,
    required this.recommendations,
    this.healthyOperations,
    this.totalOperations,
  });

  Map<String, dynamic> toMap() {
    return {
      'isHealthy': isHealthy,
      'issues': issues,
      'recommendations': recommendations,
      'healthyOperations': healthyOperations,
      'totalOperations': totalOperations,
    };
  }
}