import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crashlytics setup: log all Flutter errors
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      runApp(const BonkGuardApp());
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class BonkGuardApp extends StatelessWidget {
  const BonkGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BonkGuard',
      home: Scaffold(
        appBar: AppBar(title: const Text('BonkGuard')),
        body: Center(
          child: Row(
            mainAxisSize:
                MainAxisSize.min, // keeps the row tight around the buttons
            children: [
              ElevatedButton(
                onPressed: () async {
                  await analytics.logEvent(
                    name: 'bonkguard_test_event',
                    parameters: {'source': 'dev_setup'},
                  );
                  debugPrint('Logged bonkguard_test_event');
                },
                child: const Text('Test Event'),
              ),
              const SizedBox(width: 16), // space between buttons
              ElevatedButton(
                onPressed: () => throw Exception(),
                child: const Text('Test CRASH!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
