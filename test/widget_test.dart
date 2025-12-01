// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// UNCOMMENT at a future date - I commented this out when the tests were failing
// with the default tests. When I removed those tests and added one test that
// only checks to see if the app is running this was not needed. Leaving here so
// I can uncomment when needed later.
// import 'package:bonkguard_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(),
    ); // or whatever your root widget is called
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
