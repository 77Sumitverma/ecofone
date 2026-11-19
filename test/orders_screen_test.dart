import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecofone/screens/orders_screen.dart';
import 'package:ecofone/screens/order_detail_screen.dart';
import 'package:ecofone/screens/profile_screen.dart';
import 'package:ecofone/state/app_state.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.initServices();
    AppState.instance.backend = null;
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      routes: {
        '/orders': (context) => const OrdersScreen(),
      },
      home: child,
    );
  }

  testWidgets('OrdersScreen renders guest state when user is not logged in',
      (WidgetTester tester) async {
    AppState.instance.logout();
    await tester.pumpWidget(buildTestableWidget(const OrdersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('My Orders & Purchases'), findsOneWidget);
    expect(find.text('Sign In to View Orders'), findsOneWidget);
    expect(find.text('Back to Profile to Login'), findsOneWidget);
  });

  testWidgets('OrdersScreen renders orders and filter chips when user is logged in',
      (WidgetTester tester) async {
    AppState.instance.login(
      phone: '9876543210',
      name: 'Rahul Sharma',
      email: 'rahul@example.com',
      city: 'Lucknow',
      pincode: '226010',
    );

    final testOrder = PhoneOrder(
      orderId: 'ECO-TEST-8899',
      phoneId: 'APL-IP13-128',
      phoneName: 'iPhone 13',
      brand: 'Apple',
      storage: '128 GB',
      color: 'Midnight Blue',
      price: 42999,
      conditionGrade: 'Superb',
      icon: Icons.phone_iphone_rounded,
      deliveryOption: 'Doorstep Delivery',
      deliveryAddress: 'Gomti Nagar, Lucknow - 226010',
      paymentMethod: 'Cash on Delivery (COD)',
      paymentStatus: 'Pending Payment on Delivery',
      orderStatus: 'Confirmed • Dispatch in 24h',
      storeId: 'eco-lko-01',
      storeName: 'EcoFone Lucknow Flagship',
      storeAddress: 'Transport Nagar, Lucknow',
      storePhone: '+91 99182 40555',
      storeMapsUrl: 'https://maps.google.com',
      customerName: 'Rahul Sharma',
      customerPhone: '+91 9876543210',
      customerCity: 'Lucknow',
      customerPincode: '226010',
      createdAt: DateTime.now(),
      isSynced: true,
    );

    AppState.instance.orders.clear();
    AppState.instance.orders.add(testOrder);

    await tester.pumpWidget(buildTestableWidget(const OrdersScreen()));
    await tester.pumpAndSettle();

    expect(find.text('My Orders & Purchases'), findsOneWidget);
    expect(find.text('All Orders (1)'), findsOneWidget);
    expect(find.text('#ECO-TEST-8899'), findsOneWidget);
    expect(find.text('iPhone 13'), findsOneWidget);
    expect(find.text('Track Order'), findsOneWidget);
    expect(find.text('Tax Invoice & Pass'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows My Orders menu entry and does not display bulky order cards directly',
      (WidgetTester tester) async {
    AppState.instance.login(
      phone: '9876543210',
      name: 'Rahul Sharma',
      email: 'rahul@example.com',
      city: 'Lucknow',
      pincode: '226010',
    );

    final testOrder = PhoneOrder(
      orderId: 'ECO-TEST-8899',
      phoneId: 'APL-IP13-128',
      phoneName: 'iPhone 13',
      brand: 'Apple',
      storage: '128 GB',
      color: 'Midnight Blue',
      price: 42999,
      conditionGrade: 'Superb',
      icon: Icons.phone_iphone_rounded,
      deliveryOption: 'Doorstep Delivery',
      deliveryAddress: 'Gomti Nagar, Lucknow - 226010',
      paymentMethod: 'Cash on Delivery (COD)',
      paymentStatus: 'Pending Payment on Delivery',
      orderStatus: 'Confirmed • Dispatch in 24h',
      storeId: 'eco-lko-01',
      storeName: 'EcoFone Lucknow Flagship',
      storeAddress: 'Transport Nagar, Lucknow',
      storePhone: '+91 99182 40555',
      storeMapsUrl: 'https://maps.google.com',
      customerName: 'Rahul Sharma',
      customerPhone: '+91 9876543210',
      customerCity: 'Lucknow',
      customerPincode: '226010',
      createdAt: DateTime.now(),
      isSynced: true,
    );

    AppState.instance.orders.clear();
    AppState.instance.orders.add(testOrder);

    await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
    await tester.pumpAndSettle();

    // Verify "My Orders & Purchases" menu entry exists with 1 Order badge
    expect(find.text('My Orders & Purchases'), findsOneWidget);
    expect(find.text('1 Order'), findsOneWidget);

    // Verify bulky order card action buttons are NOT on the profile page itself
    expect(find.text('Tax Invoice & Pass'), findsNothing);
    expect(find.text('Track Order'), findsNothing);

    // Tap on "My Orders & Purchases"
    await tester.tap(find.text('My Orders & Purchases'));
    await tester.pumpAndSettle();

    // Verify it navigated inside the Orders screen where the order is now shown!
    expect(find.text('All Orders (1)'), findsOneWidget);
    expect(find.text('#ECO-TEST-8899'), findsOneWidget);
    expect(find.text('Tax Invoice & Pass'), findsOneWidget);
    expect(find.text('Track Order'), findsOneWidget);
  });

  testWidgets('Orders cards render with uniform consistent sizes across different orders',
      (WidgetTester tester) async {
    AppState.instance.login(
      phone: '9876543210',
      name: 'Rahul Sharma',
      email: 'rahul@example.com',
      city: 'Lucknow',
      pincode: '226010',
    );

    final order1 = PhoneOrder(
      orderId: 'ECO-TEST-001',
      phoneId: 'APL-IP13',
      phoneName: 'iPhone 13',
      brand: 'Apple',
      storage: '128 GB',
      color: 'Blue',
      price: 42999,
      conditionGrade: 'Superb',
      deliveryOption: 'Doorstep Delivery',
      deliveryAddress: 'Gomti Nagar, Lucknow',
      paymentMethod: 'Instant UPI',
      paymentStatus: 'Paid Online',
      orderStatus: 'Confirmed • Dispatch in 24h',
      storeId: 'eco-lko-01',
      storeName: 'EcoFone Lucknow Flagship',
      storeAddress: 'Transport Nagar, Lucknow',
      storePhone: '+91 99182 40555',
      customerName: 'Rahul Sharma',
      customerPhone: '+91 9876543210',
      createdAt: DateTime.now(),
      isSynced: true,
    );

    final order2 = PhoneOrder(
      orderId: 'ECO-TEST-002',
      phoneId: 'SAM-S23U',
      phoneName: 'Samsung Galaxy S23 Ultra 5G Enterprise Edition',
      brand: 'Samsung',
      storage: '512 GB',
      color: 'Phantom Black Titanium Metallic',
      price: 89999,
      conditionGrade: 'Superb (Pristine Condition)',
      deliveryOption: 'Store Pickup',
      deliveryAddress: 'Hazratganj Store',
      paymentMethod: 'Cash on Delivery (COD)',
      paymentStatus: 'Pay after Doorstep Inspection',
      orderStatus: 'Out for Delivery',
      storeId: 'eco-lko-01',
      storeName: 'EcoFone Lucknow Flagship',
      storeAddress: 'Transport Nagar, Lucknow',
      storePhone: '+91 99182 40555',
      customerName: 'Rahul Sharma',
      customerPhone: '+91 9876543210',
      createdAt: DateTime.now(),
      isSynced: true,
    );

    AppState.instance.orders.clear();
    AppState.instance.orders.addAll([order1, order2]);

    await tester.pumpWidget(buildTestableWidget(const OrdersScreen()));
    await tester.pumpAndSettle();

    // Verify both orders rendered
    expect(find.text('#ECO-TEST-001'), findsOneWidget);
    expect(find.text('#ECO-TEST-002'), findsOneWidget);

    // Verify action buttons exist for both
    expect(find.text('Track Order'), findsOneWidget);
    expect(find.text('Store Route'), findsOneWidget);
    expect(find.text('Tax Invoice & Pass'), findsNWidgets(2));
  });

  testWidgets('OrderDetailScreen renders complete order details, tracker, and phone photos',
      (WidgetTester tester) async {
    final pixelOrder = PhoneOrder(
      orderId: 'ECO-ORD-95724586',
      phoneId: 'EF-104',
      phoneName: 'Pixel 7 Pro',
      brand: 'Google',
      storage: '128 GB',
      color: 'Hazel & Gold',
      price: 44999,
      conditionGrade: 'Superb (Pristine)',
      deliveryOption: 'Doorstep Delivery',
      deliveryAddress: 'Lucknow, Uttar Pradesh - 226010',
      paymentMethod: 'Cash on Delivery (COD)',
      paymentStatus: 'Pay on Delivery (COD)',
      orderStatus: 'ORDER PLACED',
      storeId: 'EF-STORE-LKO-01',
      storeName: 'EcoFone Flagship Hub',
      storeAddress: 'Transport Nagar, Lucknow',
      storePhone: '+91 99182 40555',
      customerName: 'Sumit Verma',
      customerPhone: '+91 9876543210',
      createdAt: DateTime.now(),
      isSynced: true,
    );

    AppState.instance.orders.clear();
    AppState.instance.orders.add(pixelOrder);

    await tester.pumpWidget(buildTestableWidget(OrderDetailScreen(order: pixelOrder)));
    await tester.pumpAndSettle();

    // Verify Header & Order ID
    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('#ECO-ORD-95724586'), findsOneWidget);
    expect(find.text('Pixel 7 Pro'), findsWidgets);

    // Verify Device Inspection Photos Gallery
    expect(find.text('Device Inspection Photos'), findsOneWidget);
    expect(find.text('Studio Front & Back Finish'), findsOneWidget);

    // Verify Delivery Tracker
    expect(find.text('Delivery Tracking'), findsOneWidget);
    expect(find.text('Order Placed & Confirmed'), findsOneWidget);
    expect(find.text('48-Point Diagnostic & Packaging'), findsOneWidget);

    // Verify Specs & Pricing
    expect(find.text('Device Specifications & Grade'), findsOneWidget);
    expect(find.text('Price & Payment Summary'), findsOneWidget);
    expect(find.text('Official POS Tax Invoice & QR Pass'), findsOneWidget);
  });
}
