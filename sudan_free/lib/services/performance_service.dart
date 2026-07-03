import 'package:flutter/foundation.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Performance monitoring service for tracking custom traces and network metrics.
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  /// Start a custom performance trace
  AppTrace startTrace(String name) {
    final trace = AppTrace._(name);
    trace._start();
    return trace;
  }

  /// Measure and log the duration of an async operation
  Future<T> measureAsync<T>(String name, Future<T> Function() operation) async {
    final trace = startTrace(name);
    try {
      final result = await operation();
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      trace.putAttribute('status', 'error');
      trace.putAttribute('error',
          e.toString().substring(0, 100.clamp(0, e.toString().length)));
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}

/// A lightweight performance trace that logs timing data and sends it to Firebase.
class AppTrace {
  final String name;
  Trace? _firebaseTrace;
  final Stopwatch _stopwatch = Stopwatch();
  final Map<String, String> _attributes = {};
  final Map<String, int> _metrics = {};

  AppTrace._(this.name);

  Future<void> _start() async {
    _stopwatch.start();
    debugPrint('⏱️ [Perf] Trace "$name" started');
    try {
      _firebaseTrace = FirebasePerformance.instance.newTrace(name);
      await _firebaseTrace?.start();
    } catch (e) {
      debugPrint('Perf Init Error: $e');
    }
  }

  /// Add a string attribute to this trace
  void putAttribute(String key, String value) {
    _attributes[key] = value;
    _firebaseTrace?.putAttribute(key, value);
  }

  /// Add a numeric metric to this trace
  void incrementMetric(String name, int value) {
    _metrics[name] = (_metrics[name] ?? 0) + value;
    _firebaseTrace?.incrementMetric(name, value);
  }

  /// Stop the trace and log the results
  Future<void> stop() async {
    _stopwatch.stop();
    final durationMs = _stopwatch.elapsedMilliseconds;

    try {
      await _firebaseTrace?.stop();
    } catch (e) {
      debugPrint('Perf Stop Error: $e');
    }

    // Log performance data locally
    final buffer =
        StringBuffer('⏱️ [Perf] "$name" completed in ${durationMs}ms');
    if (_attributes.isNotEmpty) {
      buffer.write(' | attrs: $_attributes');
    }
    if (_metrics.isNotEmpty) {
      buffer.write(' | metrics: $_metrics');
    }

    if (durationMs > 3000) {
      debugPrint('⚠️ [Perf] SLOW: $buffer');
    } else {
      debugPrint(buffer.toString());
    }
  }
}
