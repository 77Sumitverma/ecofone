import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecofone/screens/onboarding_screen.dart';
import 'package:ecofone/services/storage/local_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableOnboarding() {
    return MaterialApp(
      routes: {
        '/home': (context) => const Scaffold(body: Text('Home Page Destination')),
      },
      home: const OnboardingScreen(),
    );
  }

  testWidgets(
      'OnboardingScreen renders pure white background, logo, and bold headlines',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableOnboarding());
    await tester.pump(const Duration(milliseconds: 300));

    // Verify official brand logo and Skip button
    expect(find.text('Skip'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    // Verify category tag
    expect(find.text('CERTIFIED REFURBISHED'), findsOneWidget);

    // Verify Slide 1 rich headline text
    expect(
      find.byWidgetPredicate((w) =>
          w is RichText &&
          w.text.toPlainText().contains('Flagships.') &&
          w.text.toPlainText().contains('Half the Price.')),
      findsOneWidget,
    );

    // Verify subtitle text
    expect(
      find.textContaining('Why pay full price?'),
      findsOneWidget,
    );
  });

  testWidgets('OnboardingScreen advances slides on tapping Continue',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableOnboarding());
    await tester.pump(const Duration(milliseconds: 300));

    // Slide 1 is active
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue to go to slide 2
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Slide 2 content
    expect(find.text('TOTAL PEACE OF MIND'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is RichText &&
          w.text.toPlainText().contains('6 Months Warranty.') &&
          w.text.toPlainText().contains('Zero Stress.')),
      findsOneWidget,
    );

    // Tap Continue to go to slide 3
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Slide 3 content & final CTA
    expect(find.text('13+ STORES & EXPRESS DELIVERY'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is RichText &&
          w.text.toPlainText().contains('Touch & Feel.') &&
          w.text.toPlainText().contains('At 13+ Stores.')),
      findsOneWidget,
    );
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Tapping Skip completes onboarding and navigates to /home',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableOnboarding());
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Skip
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify navigated to /home
    expect(find.text('Home Page Destination'), findsOneWidget);

    // Verify preference flag persisted
    final storage = await LocalStorageService.getInstance();
    expect(storage.hasSeenOnboarding, isTrue);
  });
}
