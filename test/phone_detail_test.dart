import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecofone/core/widgets/flip_phone_stock_card.dart';
import 'package:ecofone/core/widgets/phone_3d_pop_showcase.dart';
import 'package:ecofone/core/widgets/phone_context_peek_pop.dart';
import 'package:ecofone/core/widgets/phone_hero_feature_reveal.dart';
import 'package:ecofone/core/widgets/phone_quick_peek_dialog.dart';
import 'package:ecofone/core/widgets/smartphone_preview_widget.dart';
import 'package:ecofone/screens/phone_detail_screen.dart';
import 'package:ecofone/state/app_state.dart';

void main() {
  testWidgets('PhoneDetailScreen renders phone specs, price, and similar phones', (WidgetTester tester) async {
    final sampleItem = PhoneStockItem.sampleInventory.first;

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneDetailScreen(
          phone: sampleItem,
          allPhones: PhoneStockItem.sampleInventory,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Phone Name and Brand
    expect(find.text(sampleItem.name), findsWidgets);

    // Verify 32-Point Diagnostics and Warranty Guarantee
    expect(find.text('32-Point Hardware & Software Diagnostics Passed'), findsOneWidget);
    expect(find.text('6-Month Comprehensive Warranty'), findsOneWidget);

    // Verify Sticky Action Bar CTA
    expect(find.textContaining('Buy Now'), findsOneWidget);
    expect(find.text('Inquire'), findsOneWidget);

    // Verify Similar Phones Section
    expect(find.text('Similar Refurbished Phones'), findsOneWidget);
  });

  testWidgets('PhoneDetailSheet.show opens draggable modal popup', (WidgetTester tester) async {
    final sampleItem = PhoneStockItem.sampleInventory.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => PhoneDetailSheet.show(
                  context,
                  sampleItem,
                  allPhones: PhoneStockItem.sampleInventory,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify modal sheet is open and phone specs are rendered
    expect(find.text(sampleItem.name), findsWidgets);
    expect(find.textContaining('Buy Now'), findsOneWidget);
    expect(find.text('Inquire'), findsOneWidget);
  });

  testWidgets('PhoneQuickPeekDialog.show renders photo thumbnail, highlights and quick actions', (WidgetTester tester) async {
    final sampleItem = PhoneStockItem.sampleInventory.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => PhoneQuickPeekDialog.show(
                  context,
                  sampleItem,
                  allPhones: PhoneStockItem.sampleInventory,
                ),
                child: const Text('Long Press Trigger'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Long Press Trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify Quick Peek Header & Condition
    expect(find.text('QUICK PEEK'), findsOneWidget);
    expect(find.text(sampleItem.conditionGrade), findsOneWidget);

    // Verify Phone details & Highlights
    expect(find.text(sampleItem.name), findsOneWidget);
    expect(find.text('${sampleItem.batteryHealth}% Battery Health'), findsOneWidget);
    expect(find.text('Key Highlighted Features'), findsOneWidget);

    // Verify Quick Action Buttons
    expect(find.textContaining('Buy Now'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('360° Studio'), findsOneWidget);
  });

  testWidgets('PhoneHeroFeatureReveal.show renders enlarged phone and emerging feature points', (WidgetTester tester) async {
    final sampleItem = PhoneStockItem.sampleInventory.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => PhoneHeroFeatureReveal.show(
                  context,
                  sampleItem,
                  allPhones: PhoneStockItem.sampleInventory,
                ),
                child: const Text('Hero Reveal Trigger'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Hero Reveal Trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Verify Key Highlights Header
    expect(find.text('KEY HIGHLIGHTS'), findsOneWidget);

    // Verify Phone name and price in bottom dock
    expect(find.text(sampleItem.name), findsOneWidget);
    expect(find.textContaining('${sampleItem.batteryHealth}% Battery Health'), findsOneWidget);

    // Verify Buy Now Action & 360 Studio in dock
    expect(find.text('Buy Now'), findsOneWidget);
    expect(find.text('360° Studio'), findsOneWidget);
  });

  testWidgets('FlipPhoneStockCard flips in 3D to reveal key feature points', (WidgetTester tester) async {
    final sampleItem = PhoneStockItem.sampleInventory.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 290,
              child: FlipPhoneStockCard(
                item: sampleItem,
                isWishlisted: false,
                onWishlistToggle: () {},
                allPhones: PhoneStockItem.sampleInventory,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Front Card contents
    expect(find.text(sampleItem.name), findsOneWidget);
    expect(find.text('Specs'), findsOneWidget);
    expect(find.text('Buy Now'), findsOneWidget);

    // Tap "Specs" button to trigger 3D Flip
    await tester.tap(find.text('Specs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Back Card is revealed with bullet points
    expect(find.text('KEY HIGHLIGHTS'), findsOneWidget);
    expect(find.textContaining('32-Pt Diagnostic OK'), findsOneWidget);
  });

  testWidgets('PhoneContextPeekPop renders Instagram/iOS style floating card and action menu', (WidgetTester tester) async {
    final sampleItem = PhoneStockItem.sampleInventory.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => PhoneContextPeekPop.show(
                  context,
                  sampleItem,
                  allPhones: PhoneStockItem.sampleInventory,
                  isWishlisted: false,
                ),
                child: const Text('Long Press Peek Trigger'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Long Press Peek Trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify phone details in popped card
    expect(find.text(sampleItem.name), findsOneWidget);
    expect(find.text(sampleItem.conditionGrade), findsOneWidget);

    // Verify iOS/Instagram context action menu items
    expect(find.text('Buy Now • Instant Checkout'), findsOneWidget);
    expect(find.text('360° Inspection & Full Specs'), findsOneWidget);
    expect(find.text('Add to Saved Wishlist'), findsOneWidget);
    expect(find.text('Exchange Old Phone with this'), findsOneWidget);
    expect(find.text('Share Phone Deal'), findsOneWidget);
  });

  testWidgets('Phone3DPopShowcase renders 3D floating phone, ambient aura and feature capsules', (WidgetTester tester) async {
    final sampleItem = PhoneStockItem.sampleInventory.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Phone3DPopShowcase.show(
                  context,
                  sampleItem,
                  allPhones: PhoneStockItem.sampleInventory,
                  isWishlisted: false,
                ),
                child: const Text('Tap 3D Pop Trigger'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap 3D Pop Trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // Verify Floating Phone and Spec Points
    expect(find.text(sampleItem.name), findsOneWidget);
    expect(find.text(sampleItem.conditionGrade), findsOneWidget);
    expect(find.text('${sampleItem.batteryHealth}% Battery Health'), findsOneWidget);
    expect(find.text('12M Warranty Included'), findsOneWidget);
    expect(find.text('Tap anywhere to close'), findsOneWidget);
  });

  testWidgets('Buy Now flow: guest user sees Quick Mobile Login, verifies OTP, then proceeds to Address & Order', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    AppState.instance.logout();
    final sampleItem = PhoneStockItem.sampleInventory.first;

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneDetailScreen(
          phone: sampleItem,
          allPhones: PhoneStockItem.sampleInventory,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Buy Now" button
    await tester.tap(find.textContaining('Buy Now').first);
    await tester.pumpAndSettle();

    // Verify Step 1: Quick Mobile Login is displayed
    expect(find.text('Quick Mobile Login'), findsOneWidget);
    expect(find.text('10-Digit Mobile Number *'), findsOneWidget);
    expect(find.text('Send Verification OTP'), findsOneWidget);

    // Enter phone number
    await tester.enterText(find.widgetWithText(TextField, '10-Digit Mobile Number *'), '9876543210');
    await tester.pumpAndSettle();

    // Tap Send Verification OTP
    await tester.tap(find.text('Send Verification OTP'));
    await tester.pumpAndSettle();

    // Verify Dynamic OTP Banner and Auto-fill button appear
    expect(find.text('Dynamic In-App OTP'), findsOneWidget);
    expect(find.text('Auto-fill'), findsOneWidget);

    // Tap Auto-fill
    await tester.tap(find.text('Auto-fill'));
    await tester.pumpAndSettle();

    // Tap "Verify & Proceed to Address"
    await tester.tap(find.text('Verify & Proceed to Address'));
    await tester.pumpAndSettle();

    // Verify Step 2: Order Checkout is displayed
    expect(find.text('Order Checkout'), findsOneWidget);
    expect(find.text('Fulfillment Method'), findsOneWidget);
    expect(find.text('Delivery Address & Pincode'), findsOneWidget);
    expect(find.text('Contact Information'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.textContaining('Place Order'), findsOneWidget);

    // Enter Address and Name
    await tester.enterText(find.widgetWithText(TextField, 'Flat / House / Street Address'), 'Flat 402, Green Park');
    await tester.enterText(find.widgetWithText(TextField, 'Your Full Name'), 'Rahul Sharma');
    await tester.pumpAndSettle();

    // Tap Place Order
    await tester.tap(find.textContaining('Place Order'));
    await tester.pumpAndSettle();

    // Verify order placed / Tax invoice dialog
    expect(find.textContaining('Order Placed Successfully'), findsOneWidget);
  });

  testWidgets('Selecting a different color chip dynamically updates hero MiniPhoneThumbnail photo', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final sampleItem = PhoneStockItem.sampleInventory.first; // iPhone 14 Pro Space Black

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneDetailScreen(
          phone: sampleItem,
          allPhones: PhoneStockItem.sampleInventory,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial Space Black photo
    var heroThumb = tester.widget<MiniPhoneThumbnail>(find.byType(MiniPhoneThumbnail).first);
    expect(heroThumb.realImageUrl, 'assets/phones/iphone_14_pro.png');

    // Scroll to Deep Purple color chip and tap it
    await tester.ensureVisible(find.text('Deep Purple'));
    await tester.tap(find.text('Deep Purple'));
    await tester.pumpAndSettle();

    heroThumb = tester.widget<MiniPhoneThumbnail>(find.byType(MiniPhoneThumbnail).first);
    expect(heroThumb.colorName, 'Deep Purple');
    expect(heroThumb.realImageUrl, 'assets/phones/iphone_14_pro_deep_purple.png');
  });
}



