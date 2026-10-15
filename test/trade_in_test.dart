import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecofone/screens/trade_in_screen.dart';

void main() {
  testWidgets('TradeInScreen renders live valuation, selectors, and booking sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: TradeInScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Hero Live Valuation Header
    expect(find.text('Live Benchmark Valuation'), findsOneWidget);
    expect(find.text('7-Day Price Lock'), findsOneWidget);
    expect(find.text('Instant Cash Payout'), findsOneWidget);

    // 2. Verify Selectors & Guarantees
    expect(find.text('Select Your Old Phone'), findsOneWidget);
    expect(find.text('Physical & Functional Health'), findsOneWidget);
    expect(find.text('Your Positive Green Footprint'), findsOneWidget);
    expect(find.text('Book 15-Min Payout'), findsOneWidget);

    // 3. Test changing brand
    final samsungChip = find.text('Samsung');
    expect(samsungChip, findsOneWidget);
    await tester.tap(samsungChip);
    await tester.pumpAndSettle();

    // 4. Test tapping Dead/Broken phone option
    final deadPhoneOption = find.text('No, dead/broken');
    expect(deadPhoneOption, findsOneWidget);
    await tester.tap(deadPhoneOption);
    await tester.pumpAndSettle();

    expect(find.text('Guaranteed E-Waste Salvage Value'), findsOneWidget);

    // 5. Switch back to working phone
    final workingPhoneOption = find.text('Yes, works');
    await tester.tap(workingPhoneOption);
    await tester.pumpAndSettle();

    // 6. Test opening booking modal sheet
    final bookButton = find.text('Book 15-Min Payout');
    await tester.tap(bookButton);
    await tester.pumpAndSettle();

    expect(find.text('Instant Phone Payout Pass'), findsOneWidget);
    expect(find.text('Select Payout Mode'), findsOneWidget);
    expect(find.text('Confirm Trade-in Pass'), findsOneWidget);
  });
}
