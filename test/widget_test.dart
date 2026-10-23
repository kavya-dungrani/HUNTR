import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hunter/screens/hunter_auth_screen.dart';
import 'package:hunter/providers/hunter_provider.dart';

void main() {
  testWidgets('HunterAuthScreen renders login and toggles to sign up at bottom', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HunterProvider()),
        ],
        child: const MaterialApp(
          home: HunterAuthScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Login elements are present
    expect(find.text('HUNTER ASSOCIATION'), findsOneWidget);
    expect(find.text('ACCESS HUNTER SYSTEM'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign Up'), findsWidgets);

    // Scroll to the bottom if needed and tap "Sign Up"
    final signUpFinder = find.text('Sign Up').last;
    await tester.ensureVisible(signUpFinder);
    await tester.tap(signUpFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify switched to Sign Up
    expect(find.text('HUNTER REGISTRATION'), findsOneWidget);
    expect(find.text('AWAKEN & REGISTER'), findsOneWidget);
    expect(find.text('Log In'), findsWidgets);

    // Tap "Log In" at bottom of Sign Up to switch back
    final logInFinder = find.text('Log In').last;
    await tester.ensureVisible(logInFinder);
    await tester.tap(logInFinder);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify back on Login
    expect(find.text('HUNTER ASSOCIATION'), findsOneWidget);
    expect(find.text('ACCESS HUNTER SYSTEM'), findsOneWidget);
  });
}
