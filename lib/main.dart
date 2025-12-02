import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

// RevenueCat TEST STORE API Key
const String _rcTestApiKey = 'test_rUCSMpxkqldLXjtvRTOkPtnLzEi';
final configuration = PurchasesConfiguration(_rcTestApiKey);

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

      // RevenueCat: configured with Test store
      final configuration = PurchasesConfiguration(_rcTestApiKey);
      await Purchases.configure(configuration);

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
      title: 'BonkGuard',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('BonkGuard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 16), // space between buttons
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('devTests')
                        .add({
                          'createdAt': DateTime.now(),
                          'note': 'Hello from BonkGuard Firestore test',
                        });
                    debugPrint('Firestore write succeeded');
                  } catch (e, st) {
                    debugPrint('Firestore write FAILED: $e');
                    // Crashlytics will also pick this up
                    FirebaseCrashlytics.instance.recordError(e, st);
                  }
                },
                child: const Text('Test Firestore Write'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final offerings = await Purchases.getOfferings();
                    if (offerings.current != null) {
                      debugPrint(
                        'RevenueCat offerings loaded: ${offerings.current!.identifier}',
                      );
                    } else {
                      debugPrint(
                        'RevenueCat connected, but no current offering is configured yet.',
                      );
                    }
                  } catch (e, st) {
                    debugPrint('Error fetching offerings: $e');
                    FirebaseCrashlytics.instance.recordError(e, st);
                  }
                },
                child: const Text('Test RevenueCat Offerings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
