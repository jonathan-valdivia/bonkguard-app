// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'firebase_options.dart';
import 'app_theme.dart';
import 'auth/auth_gate.dart';
import 'state/user_profile_notifier.dart';

// firebase analytics instance
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

// RevenueCat TEST STORE API Key
const String _rcTestApiKey = 'test_rUCSMpxkqldLXjtvRTOkPtnLzEi';
// Keep a single configuration instance
final PurchasesConfiguration _rcConfiguration = PurchasesConfiguration(
  _rcTestApiKey,
);

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
      await Purchases.configure(_rcConfiguration);

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
    return ChangeNotifierProvider<UserProfileNotifier>(
      create: (_) => UserProfileNotifier(),
      child: MaterialApp(
        title: 'BonkGuard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 16),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
