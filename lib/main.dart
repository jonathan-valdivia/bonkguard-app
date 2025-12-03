import 'dart:async';
import 'app_theme.dart';
import 'auth/auth_gate.dart';
import 'package:flutter/material.dart';

// firebase imports
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// revenueCat imports
import 'package:purchases_flutter/purchases_flutter.dart';

// imports for PDF printing:
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// ^^ IMPORTS ^^

// firebase analytics instance
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
      //home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BonkGuardLogo()),
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
                  await FirebaseFirestore.instance.collection('devTests').add({
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await generateTestPdf();
              },
              child: const Text('Generate Test PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

// Generate PDF method
Future<void> generateTestPdf() async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BonkGuard Fuel Plan **TEST**',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('This is a test PDF from the BonkGuard app.'),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: ['Time', 'Fuel'],
              data: const [
                ['00:15', 'Gel'],
                ['00:30', 'Drink Mix'],
                ['00:45', 'Chews'],
                ['01:00', 'Bar'],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 24,
            ),
          ],
        );
      },
    ),
  );

  // This opens the system preview / print dialog
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
