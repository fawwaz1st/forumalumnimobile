import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'core/constants/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appStart = DateTime.now();
  await Hive.initFlutter();
  // Ensure settings box opened before widgets build
  await Hive.openBox<String>('app_settings');
  // Ensure notifications box opened to avoid fallback Hive.box error
  await Hive.openBox<String>('notifications_v1');
  // Pre-open other boxes used across the app to avoid race conditions
  await Hive.openBox<String>('posts_cache');
  await Hive.openBox<String>('posts_queue');
  await Hive.openBox<String>('post_drafts');
  await Hive.openBox<String>('bookmarks_v1');
  await Hive.openBox('search_history_v1');
  await Hive.openBox('app_flags');

  // Global error widget to avoid red screen in release
  ErrorWidget.builder = (details) {
    // Hindari dependensi pada Material/Theme/Directionality dari tree utama,
    // karena error dapat terjadi sebelum MaterialApp tersedia.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Terjadi kesalahan tak terduga',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  // Debug performance logging: startup time + FPS
  if (kDebugMode) {
    WidgetsBinding.instance.addTimingsCallback((timings) {
      if (timings.isEmpty) return;
      final avgMs = timings
              .map((t) => t.totalSpan.inMilliseconds)
              .fold<int>(0, (a, b) => a + b) /
          timings.length;
      final fps = (avgMs > 0) ? (1000 / avgMs) : 0.0;
      dev.log('Frame timings: avg ${avgMs.toStringAsFixed(1)}ms -> ~${fps.toStringAsFixed(1)} fps', name: 'performance');
    });
  }

  void runRoot() {
    final startupMs = DateTime.now().difference(appStart).inMilliseconds;
    if (kDebugMode) {
      dev.log('Startup time: ${startupMs}ms', name: 'performance');
    }
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      Sentry.captureException(details.exception, stackTrace: details.stack);
    };
    runApp(const ProviderScope(child: App()));
  }

  // Initialize Sentry (no-op if DSN empty)
  if (AppConfig.sentryDsn.isEmpty) {
    runRoot();
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 0.2; // performance monitoring sample rate
        options.enableAutoPerformanceTracing = true;
      },
      appRunner: runRoot,
    );
  }
}
