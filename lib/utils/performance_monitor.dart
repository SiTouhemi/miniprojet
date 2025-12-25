import 'package:flutter/foundation.dart';
import '/config/app_config.dart';
import '/utils/app_logger.dart';

class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  
  static void startTrace(String traceName) {
    if (!AppConfig.enablePerformanceMonitoring) return;
    
    _startTimes[traceName] = DateTime.now();
    
    if (AppConfig.enableDebugLogging) {
      AppLogger.performance('Started trace $traceName');
    }
  }
  
  static void stopTrace(String traceName) {
    if (!AppConfig.enablePerformanceMonitoring) return;
    
    final startTime = _startTimes[traceName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _startTimes.remove(traceName);
      
      if (AppConfig.enableDebugLogging) {
        AppLogger.performance('$traceName completed', duration: duration);
      }
      
      // In production, send to Firebase Performance
      if (AppConfig.isProduction) {
        // TODO: Send to Firebase Performance Monitoring
        // FirebasePerformance.instance.newTrace(traceName)..stop();
      }
    }
  }
  
  static void recordMetric(String metricName, double value) {
    if (!AppConfig.enablePerformanceMonitoring) return;
    
    if (AppConfig.enableDebugLogging) {
      AppLogger.performance('$metricName = $value', value: value.toInt());
    }
    
    // In production, send to analytics
    if (AppConfig.isProduction && AppConfig.enableAnalytics) {
      // TODO: Send to Firebase Analytics
      // FirebaseAnalytics.instance.logEvent(name: metricName, parameters: {'value': value});
    }
  }
  
  static void recordUserAction(String action, {Map<String, dynamic>? parameters}) {
    if (!AppConfig.enableAnalytics) return;
    
    if (AppConfig.enableDebugLogging) {
      AppLogger.userAction(action, params: parameters);
    }
    
    // In production, send to analytics
    if (AppConfig.isProduction) {
      // TODO: Send to Firebase Analytics
      // FirebaseAnalytics.instance.logEvent(name: action, parameters: parameters);
    }
  }
}