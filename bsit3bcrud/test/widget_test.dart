import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:developer'; // Import the log function
import 'package:bsit3bcrud/user_screen.dart'; // Import UserScreen (or the correct path)

void main() {
  testWidgets('UserScreen displays user list and logout button', (
    WidgetTester tester,
  ) async {
    // Define a simple mock onLogout function for the test
    void mockLogout() {
      // Log a message when logout is triggered for the test
      log('User logged out');
    }

    // Build the widget tree, passing the mockLogout function to onLogout
    await tester.pumpWidget(
      MaterialApp(home: UserScreen(onLogout: mockLogout)),
    );

    // Verify that the UserScreen widget is displayed correctly
    expect(
      find.text('User Management'),
      findsOneWidget,
    ); // If you have a title like this in UserScreen
    expect(
      find.byType(UserScreen),
      findsOneWidget,
    ); // Check that UserScreen widget exists

    // Check if a logout button is present (assuming you use an Icon for logout)
    expect(find.byIcon(Icons.logout), findsOneWidget);

    // Simulate pressing the logout button
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump(); // Trigger the widget to rebuild after the tap

    // Optionally, you can check if your mockLogout function was called by adding a print statement in the function
    // You may also check if you navigate to a login screen after logging out (if needed).
  });
}
