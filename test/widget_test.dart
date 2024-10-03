import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator/main.dart'; // Replace with the actual path to your main.dart

void main() {
  testWidgets('LoginPage has a title and message', (WidgetTester tester) async {
    // Build the MyApp widget.
    await tester.pumpWidget(MyApp());

    // Verify that the title is displayed in the AppBar.
    expect(find.text('Calculator'), findsOneWidget);

    // Verify that the message is displayed on the LoginPage.
    expect(find.text('Please enter your username'), findsOneWidget); // Adjust based on actual text
    expect(find.text('Please enter your password'), findsOneWidget); // Adjust based on actual text
  });
}
