import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecofone/services/storage/local_storage_service.dart';
import 'package:ecofone/services/backend/realtime_backend_service.dart';
import 'package:ecofone/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Real-Time Backend & Persistence Layer Tests', () {
    test('UserProfile JSON serialization & deserialization with city & pincode', () {
      final profile = UserProfile(
        name: 'Rahul Sharma',
        phone: '+91 98765 43210',
        email: 'rahul@ecofone.in',
        city: 'Lucknow',
        pincode: '226012',
        token: 'ECO-JWT-TEST-123',
        lastLoginAt: DateTime.parse('2026-09-07T12:00:00.000Z'),
      );

      final json = profile.toJson();
      final fromJson = UserProfile.fromJson(json);

      expect(fromJson.name, 'Rahul Sharma');
      expect(fromJson.phone, '+91 98765 43210');
      expect(fromJson.email, 'rahul@ecofone.in');
      expect(fromJson.city, 'Lucknow');
      expect(fromJson.pincode, '226012');
      expect(fromJson.token, 'ECO-JWT-TEST-123');
      expect(fromJson.lastLoginAt?.toIso8601String(), '2026-09-07T12:00:00.000Z');
    });

    test('PhoneOrder JSON serialization & deserialization', () {
      final order = PhoneOrder(
        orderId: 'ECO-ORD-99881',
        phoneId: 'EF-103',
        phoneName: 'iPhone 13',
        brand: 'Apple',
        storage: '128 GB',
        color: 'Midnight Blue',
        price: 42999,
        conditionGrade: 'Very Good',
        deliveryOption: 'Doorstep Delivery',
        deliveryAddress: 'Transport Nagar Metro, Lucknow',
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'Pay on Delivery',
        orderStatus: 'CONFIRMED',
        storeId: 'EF-STORE-LKO-01',
        storeName: 'EcoFone Store - Transport Nagar, Lucknow',
        storeAddress: 'Transport Nagar Metro, Lucknow',
        storePhone: '+91 99182 40555',
        storeMapsUrl: 'https://maps.app.goo.gl/test',
        customerName: 'Aman Verma',
        customerPhone: '+91 91234 56789',
        createdAt: DateTime.parse('2026-09-07T10:30:00.000Z'),
      );

      final json = order.toJson();
      final fromJson = PhoneOrder.fromJson(json);

      expect(fromJson.orderId, 'ECO-ORD-99881');
      expect(fromJson.phoneName, 'iPhone 13');
      expect(fromJson.price, 42999);
      expect(fromJson.customerName, 'Aman Verma');
      expect(fromJson.storeName, contains('Transport Nagar'));
      expect(fromJson.deliveryOption, 'Doorstep Delivery');
      expect(fromJson.grade, 'Very Good');
    });

    test('LocalStorageService saves and loads user session and reservations', () async {
      final storage = await LocalStorageService.getInstance();
      
      const profile = UserProfile(
        name: 'Vikas Gupta',
        phone: '+91 99887 76655',
        email: 'vikas@ecofone.in',
        city: 'Lucknow',
        pincode: '226010',
      );

      await storage.saveUserProfile(profile);
      expect(storage.isLoggedIn, isTrue);

      final loaded = storage.getUserProfile();
      expect(loaded?.name, 'Vikas Gupta');
      expect(loaded?.phone, '+91 99887 76655');
      expect(loaded?.city, 'Lucknow');
      expect(loaded?.pincode, '226010');

      await storage.clearAuthSession();
      expect(storage.isLoggedIn, isFalse);
      expect(storage.getUserProfile(), isNull);
    });

    test('RealtimeBackendService generates dynamic OTP and verifies', () async {
      final storage = await LocalStorageService.getInstance();
      final backend = RealtimeBackendService(storage: storage);

      await backend.sendOtp('9876543210');
      final dynamicOtp = backend.getActiveOtp('9876543210');
      expect(dynamicOtp, isNotNull);
      expect(dynamicOtp!.length, 6);

      final profile = await backend.verifyOtpAndLogin(
        phoneNumber: '+91 98765 43210',
        otp: dynamicOtp,
        name: 'Ananya Roy',
      );
      expect(profile, isNotNull);
      expect(profile?.name, 'Ananya Roy');
      expect(profile?.phone, '+91 9876543210');
      backend.dispose();
    });

    test('RealtimeBackendService streams reservation updates', () async {
      final storage = await LocalStorageService.getInstance();
      final backend = RealtimeBackendService(storage: storage);

      final testRes = PhoneOrder(
        orderId: 'ECO-ORD-TEST-001',
        phoneId: 'EF-101',
        phoneName: 'iPhone 14 Pro',
        storage: '128 GB',
        color: 'Deep Purple',
        price: 79999,
        conditionGrade: 'Superb (Pristine)',
        deliveryOption: 'Doorstep Delivery',
        deliveryAddress: 'Viram Khand, Gomti Nagar, Lucknow',
        paymentMethod: 'Instant UPI',
        paymentStatus: 'Paid Online',
        orderStatus: 'CONFIRMED',
        storeId: 'EF-STORE-LKO-02',
        storeName: 'EcoFone Store - Gomti Nagar',
        storeAddress: 'Viram Khand, Gomti Nagar, Lucknow',
        storePhone: '+91 99182 40555',
        storeMapsUrl: 'https://maps.app.goo.gl/test',
        customerName: 'Pooja Singh',
        customerPhone: '+91 98765 11223',
        createdAt: DateTime.now(),
      );

      final streamFuture = backend.streamUserOrders('+91 98765 11223').first;
      await backend.createOrder(testRes);

      final streamedList = await streamFuture;
      expect(streamedList.length, 1);
      expect(streamedList.first.orderId, 'ECO-ORD-TEST-001');
      expect(streamedList.first.customerName, 'Pooja Singh');

      backend.dispose();
    });

    test('AppState initServices loads persistent data and updates profile details', () async {
      final appState = AppState.instance;
      await appState.initServices();

      expect(appState.isServicesInitialized, isTrue);
      expect(appState.storage, isNotNull);
      expect(appState.backend, isNotNull);

      // Verify OTP login
      final profile = await appState.verifyOtpAndLogin(
        phone: '9876500000',
        otp: '1234',
        name: 'Harshita Sharma',
      );

      expect(appState.isLoggedIn, isTrue);
      expect(appState.userName, 'Harshita Sharma');
      expect(appState.userPhone, '+91 9876500000');
      expect(profile?.name, 'Harshita Sharma');

      // Update profile details
      await appState.updateProfileDetails(
        name: 'Harshita Verma',
        email: 'harshita.verma@ecofone.in',
        city: 'Gorakhpur',
        pincode: '273001',
      );

      expect(appState.userName, 'Harshita Verma');
      expect(appState.userEmail, 'harshita.verma@ecofone.in');
      expect(appState.userLocation.city, 'Gorakhpur');

      appState.logout();
      expect(appState.isLoggedIn, isFalse);
      expect(appState.userName, isNull);
    });

    test('RealtimeBackendService and AppState reject invalid OTP', () async {
      final storage = await LocalStorageService.getInstance();
      final backend = RealtimeBackendService(storage: storage);

      await backend.sendOtp('9998887770');
      // Attempt login with wrong OTP
      final badProfile = await backend.verifyOtpAndLogin(
        phoneNumber: '+91 99988 87770',
        otp: '000000',
        name: 'Hacker',
      );
      expect(badProfile, isNull);

      final appState = AppState.instance;
      await appState.initServices();
      appState.logout();

      final stateBadProfile = await appState.verifyOtpAndLogin(
        phone: '9998887770',
        otp: '000000',
        name: 'Hacker',
      );
      expect(stateBadProfile, isNull);
      expect(appState.isLoggedIn, isFalse);

      backend.dispose();
    });
  });
}
