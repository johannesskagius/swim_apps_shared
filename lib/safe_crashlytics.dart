// safe_crashlytics.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class SafeCrashlytics {
  static bool _ready = false;

  static Future<void> markReady() async {
    try {
      // Called by main app AFTER Firebase.initializeApp()
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        _ready = true;
        debugPrint('✅ Crashlytics ready in shared lib');
      }
    } catch (e) {
      debugPrint('⚠️ Crashlytics markReady failed: $e');
    }
  }

  static void log(String msg) {
    if (!_ready) {
      debugPrint('[Crashlytics skipped] $msg');
      return;
    }
    try {
      FirebaseCrashlytics.instance.log(msg);
    } catch (_) {}
  }

  static void recordError(Object e, StackTrace st, {String? reason, bool fatal = false}) {
    if (!_ready) {
      debugPrint('[Crashlytics skipped error] $reason');
      return;
    }
    try {
      FirebaseCrashlytics.instance.recordError(e, st, reason: reason, fatal: fatal);
    } catch (_) {}
  }
}
