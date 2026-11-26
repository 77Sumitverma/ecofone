import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecofone/core/widgets/saved_checkout_suggestion_card.dart';
import 'package:ecofone/screens/phone_detail_screen.dart';
import 'package:ecofone/screens/profile_screen.dart';
import 'package:ecofone/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.initServices();
    AppState.instance.backend = null;
    AppState.instance.logout();
  });

  group('Phone-Only Signup & Order Checkout Suggestion Flow', () {
    test('New phone-only OTP login signs in without saved details', () async {
      final profile = await AppState.instance.verifyOtpAndLogin(
        phone: '9876500111',
        otp: '1234',
      );

      expect(profile, isNotNull);
      expect(profile?.isNewUser, isTrue);
      expect(AppState.instance.isLoggedIn, isTrue);
      expect(AppState.instance.userPhone, '+91 9876500111');
      expect(AppState.instance.userName, isNull);
      expect(AppState.instance.getSavedCheckoutDetails(), isNull);
    });

    test('Saving first-order details enables SavedCheckoutDetails for subsequent logins', () async {
      await AppState.instance.verifyOtpAndLogin(
        phone: '9876500222',
        otp: '1234',
      );
      expect(AppState.instance.getSavedCheckoutDetails(), isNull);

      await AppState.instance.saveCheckoutProfileDetails(
        name: 'Aarav Verma',
        phone: '9876500222',
        address: 'House 18, Nirala Nagar',
        city: 'Lucknow',
        pincode: '226020',
      );

      final saved = AppState.instance.getSavedCheckoutDetails();
      expect(saved, isNotNull);
      expect(saved?.name, 'Aarav Verma');
      expect(saved?.address, 'House 18, Nirala Nagar');
      expect(saved?.pincode, '226020');

      // Re-login with same number (returning user offline session check)
      final relogged = await AppState.instance.verifyOtpAndLogin(
        phone: '9876500222',
        otp: '1234',
      );
      expect(relogged?.isNewUser, isFalse);
      expect(relogged?.name, 'Aarav Verma');
      expect(relogged?.address, 'House 18, Nirala Nagar');
    });

    testWidgets('ProfileScreen login/signup asks ONLY mobile number and OTP (no Name or Address modal steps)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open Sign In / Sign Up modal
      await tester.tap(find.text('Login / Sign Up with Mobile'));
      await tester.pumpAndSettle();

      // Verify Phone-only field is present and Full Name is NOT requested on Login/Signup
      expect(find.text('10-digit Mobile Number *'), findsOneWidget);
      expect(find.text('Full Name *'), findsNothing);
      expect(find.text('Set Delivery Address'), findsNothing);

      // Enter mobile number and send OTP
      await tester.enterText(find.widgetWithText(TextField, '10-digit Mobile Number *'), '9876543219');
      await tester.tap(find.text('Send Verification OTP'));
      await tester.pumpAndSettle();

      // Verify OTP via 1234 fallback when backend is null
      await tester.enterText(find.widgetWithText(TextField, '6-digit SMS OTP'), '1234');
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      // New user completes signup immediately without Set Delivery Address step
      expect(find.text('Set Delivery Address'), findsNothing);
      expect(AppState.instance.isLoggedIn, isTrue);
      expect(AppState.instance.userPhone, '+91 9876543219');
      expect(AppState.instance.userName, isNull);
    });

    testWidgets('New user sees First Order Profile Setup and empty Name/Address at checkout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await AppState.instance.verifyOtpAndLogin(phone: '9876500333', otp: '1234');
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

      await tester.tap(find.textContaining('Buy Now').first);
      await tester.pumpAndSettle();

      expect(find.text('Order Checkout'), findsOneWidget);
      expect(find.text('First Order Profile Setup'), findsOneWidget);
      expect(find.text('Saved Details Suggestion'), findsNothing);

      final nameField = tester.widget<TextField>(find.widgetWithText(TextField, 'Your Full Name'));
      final addrField = tester.widget<TextField>(find.widgetWithText(TextField, 'Flat / House / Street Address'));
      expect(nameField.controller?.text, isEmpty);
      expect(addrField.controller?.text, isEmpty);
    });

    testWidgets('Old user sees Saved Details Suggestion and can apply in 1 tap or clear to enter new',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await AppState.instance.saveCheckoutProfileDetails(
        name: 'Meera Joshi',
        phone: '9876500444',
        address: 'Sector B, Aliganj',
        city: 'Lucknow',
        pincode: '226024',
      );

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

      await tester.tap(find.textContaining('Buy Now').first);
      await tester.pumpAndSettle();

      expect(find.text('Saved Details Suggestion'), findsOneWidget);
      expect(find.text('Meera Joshi'), findsOneWidget);
      expect(find.textContaining('Sector B, Aliganj'), findsOneWidget);

      // Fields start empty until the user taps the suggestion
      var nameField = tester.widget<TextField>(find.widgetWithText(TextField, 'Your Full Name'));
      var addrField = tester.widget<TextField>(find.widgetWithText(TextField, 'Flat / House / Street Address'));
      expect(nameField.controller?.text, isEmpty);
      expect(addrField.controller?.text, isEmpty);

      // Tap "Use Saved Details"
      await tester.tap(find.text('Use Saved Details'));
      await tester.pumpAndSettle();

      nameField = tester.widget<TextField>(find.widgetWithText(TextField, 'Your Full Name'));
      addrField = tester.widget<TextField>(find.widgetWithText(TextField, 'Flat / House / Street Address'));
      final pinField = tester.widget<TextField>(find.widgetWithText(TextField, 'Delivery Pincode'));
      expect(nameField.controller?.text, 'Meera Joshi');
      expect(addrField.controller?.text, 'Sector B, Aliganj');
      expect(pinField.controller?.text, '226024');
      expect(find.text('Using Saved Details'), findsOneWidget);
      expect(find.text('Enter New'), findsOneWidget);

      // Tap "Enter New" clears Name & Address so user can enter different details
      await tester.tap(find.text('Enter New'));
      await tester.pumpAndSettle();

      nameField = tester.widget<TextField>(find.widgetWithText(TextField, 'Your Full Name'));
      addrField = tester.widget<TextField>(find.widgetWithText(TextField, 'Flat / House / Street Address'));
      expect(nameField.controller?.text, isEmpty);
      expect(addrField.controller?.text, isEmpty);
    });

    test('SavedCheckoutDetails model preserves placeholder guards', () {
      expect(UserProfile.isPlaceholderName('Valued Customer'), isTrue);
      expect(UserProfile.isPlaceholderName('EcoCustomer'), isTrue);
      expect(UserProfile.isPlaceholderName('Rahul'), isFalse);
      expect(UserProfile.isPlaceholderAddress('Doorstep Delivery'), isTrue);
      expect(UserProfile.isPlaceholderAddress('Flat 12, Hazratganj'), isFalse);
      expect(SavedCheckoutSuggestionCard, isNotNull);
    });
  });
}
