import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecofone/services/backend/realtime_backend_service.dart';
import 'package:ecofone/services/storage/local_storage_service.dart';
import 'package:ecofone/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Billing & POS API Integration Tests', () {
    test('PhoneStockItem JSON serialization includes POS/billing fields', () {
      const item = PhoneStockItem(
        id: 'EF-101',
        sku: 'SKU-IPH14P-128-BLK',
        imei: '358941098234567',
        storeId: 'EF-STORE-LKO-01',
        hsnCode: '85171200',
        taxPercent: 18.0,
        name: 'iPhone 14 Pro',
        brand: 'Apple',
        storage: '128 GB',
        color: 'Space Black',
        batteryHealth: 94,
        conditionGrade: 'Superb (Pristine)',
        gradeDescription: 'Pristine display & frame.',
        refurbishedPrice: 76999,
        originalPrice: 129900,
        stockQuantity: 2,
        icon: Icons.phone_iphone_rounded,
        highlights: ['Dynamic Island', 'A16 Bionic'],
      );

      final json = item.toJson();
      expect(json['sku'], 'SKU-IPH14P-128-BLK');
      expect(json['imei'], '358941098234567');
      expect(json['storeId'], 'EF-STORE-LKO-01');
      expect(json['hsnCode'], '85171200');
      expect(json['taxPercent'], 18.0);
      expect(json['refurbishedPrice'], 76999);
      expect(item.isAvailable, isTrue);

      // Verify deserialization from POS snake_case format
      final posJson = {
        'product_id': 'EF-201',
        'sku': 'SKU-S23U-256-BLK',
        'product_name': 'Galaxy S23 Ultra',
        'manufacturer': 'Samsung',
        'capacity': '256 GB',
        'color': 'Phantom Black',
        'battery_health': 98,
        'grade': 'Superb (Pristine)',
        'selling_price': 79999,
        'mrp': 124999,
        'quantity': 4,
        'hsn_code': '85171200',
        'tax_percent': 18.0,
      };

      final parsed = PhoneStockItem.fromJson(posJson);
      expect(parsed.id, 'EF-201');
      expect(parsed.sku, 'SKU-S23U-256-BLK');
      expect(parsed.name, 'Galaxy S23 Ultra');
      expect(parsed.brand, 'Samsung');
      expect(parsed.refurbishedPrice, 79999);
      expect(parsed.stockQuantity, 4);
      expect(parsed.isAvailable, isTrue);
    });

    test('TradeInQuote model serializes and deserializes properly', () {
      final quote = TradeInQuote(
        quoteId: 'ECO-TRD-998811',
        brand: 'Apple',
        modelName: 'iPhone 13',
        storage: '128 GB',
        estimatedPayout: 34500,
        screenCondition: 'Flawless',
        bodyCondition: 'Minor Scuffs',
        turnsOn: true,
        cameraWorking: true,
        batteryHealthy: true,
        biometricsWorking: true,
        speakerWorking: true,
        hasCharger: true,
        hasBox: true,
        hasBill: true,
        customerName: 'Aman Verma',
        customerPhone: '+91 98765 43210',
        storeId: 'EF-STORE-LKO-01',
        storeName: 'EcoFone Flagship Hub - Transport Nagar',
        createdAt: DateTime.parse('2026-10-07T10:00:00.000Z'),
      );

      final json = quote.toJson();
      final fromJson = TradeInQuote.fromJson(json);

      expect(fromJson.quoteId, 'ECO-TRD-998811');
      expect(fromJson.modelName, 'iPhone 13');
      expect(fromJson.estimatedPayout, 34500);
      expect(fromJson.customerName, 'Aman Verma');
      expect(fromJson.screenCondition, 'Flawless');
      expect(fromJson.bodyCondition, 'Minor Scuffs');
    });

    test('BillingApiService in Sandbox mode returns sample catalog & handles holds', () async {
      final service = BillingApiService(); // default sandbox mode
      expect(service.isSandboxMode, isTrue);

      final inventory = await service.fetchInventory();
      expect(inventory.isNotEmpty, isTrue);
      expect(inventory.length, PhoneStockItem.sampleInventory.length);

      final product = await service.fetchProductDetails('EF-101');
      expect(product?.name, 'iPhone 14 Pro');

      final order = PhoneOrder(
        orderId: 'ECO-ORD-TEST-1',
        phoneId: 'EF-101',
        phoneName: 'iPhone 14 Pro',
        storage: '128 GB',
        color: 'Space Black',
        price: 76999,
        conditionGrade: 'Superb',
        deliveryOption: 'Doorstep Delivery',
        deliveryAddress: 'Transport Nagar, Lucknow',
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'Pay on Delivery',
        orderStatus: 'CONFIRMED',
        storeId: 'EF-STORE-LKO-01',
        storeName: 'EcoFone Lucknow',
        storeAddress: 'Transport Nagar',
        storePhone: '+91 99182 40555',
        storeMapsUrl: '',
        customerName: 'Rohit Roy',
        customerPhone: '+91 9988776655',
        createdAt: DateTime.now(),
      );

      final orderCreated = await service.createOrder(order);
      expect(orderCreated, isTrue);

      final orderCancelled = await service.cancelOrder('ECO-ORD-TEST-1');
      expect(orderCancelled, isTrue);

      final isHealthy = await service.checkHealth();
      expect(isHealthy, isTrue);
    });

    test('BillingApiService communicates with live REST mock client', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/inventory') {
          return http.Response(
            jsonEncode([
              {
                'id': 'POS-LIVE-01',
                'sku': 'SKU-IPH15-128',
                'name': 'iPhone 15',
                'brand': 'Apple',
                'storage': '128 GB',
                'color': 'Blue',
                'batteryHealth': 99,
                'conditionGrade': 'Superb (Pristine)',
                'gradeDescription': 'Mint showroom unit',
                'refurbishedPrice': 59999,
                'originalPrice': 79900,
                'stockQuantity': 5,
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/api/v1/reservations' && request.method == 'POST') {
          return http.Response(jsonEncode({'status': 'HELD_ON_BENCH'}), 201);
        } else if (request.url.path == '/api/v1/trade-in/quote' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              ...body,
              'status': 'ENTERED_IN_PURCHASE_REGISTER',
            }),
            200,
          );
        } else if (request.url.path == '/api/v1/health') {
          return http.Response(jsonEncode({'status': 'OK', 'pos_version': '4.2.0'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final liveService = BillingApiService(
        baseUrl: 'https://api.billingcompany.com',
        apiKey: 'SECRET_API_KEY_123',
        client: mockClient,
      );

      expect(liveService.isSandboxMode, isFalse);

      final items = await liveService.fetchInventory();
      expect(items.length, 1);
      expect(items.first.id, 'POS-LIVE-01');
      expect(items.first.name, 'iPhone 15');
      expect(items.first.refurbishedPrice, 59999);

      final healthy = await liveService.checkHealth();
      expect(healthy, isTrue);

      final quote = TradeInQuote(
        quoteId: 'ECO-TRD-TEST',
        brand: 'Apple',
        modelName: 'iPhone 12',
        storage: '128 GB',
        estimatedPayout: 25000,
        screenCondition: 'Flawless',
        bodyCondition: 'Flawless',
        customerName: 'Amit',
        customerPhone: '+91 99999 88888',
        storeId: 'EF-STORE-LKO-01',
        storeName: 'EcoFone Lucknow',
        createdAt: DateTime.now(),
      );

      final syncedQuote = await liveService.submitTradeInQuote(quote);
      expect(syncedQuote.status, 'ENTERED_IN_PURCHASE_REGISTER');
      liveService.dispose();
    });

    test('AppState refreshInventory and submitTradeInQuote operate smoothly', () async {
      final storage = await LocalStorageService.getInstance();
      final backend = RealtimeBackendService(storage: storage);
      final appState = AppState.instance;

      appState.backend = backend;
      await appState.initServices();

      expect(appState.liveInventory.isNotEmpty, isTrue);
      await appState.refreshInventory();
      expect(appState.liveInventory.isNotEmpty, isTrue);

      final quote = TradeInQuote(
        quoteId: 'ECO-TRD-STATE-TEST',
        brand: 'Samsung',
        modelName: 'Galaxy S23 Ultra',
        storage: '256 GB',
        estimatedPayout: 58000,
        screenCondition: 'Flawless',
        bodyCondition: 'Flawless',
        customerName: 'Kunal Kapoor',
        customerPhone: '+91 98765 00112',
        storeId: 'EF-STORE-LKO-01',
        storeName: 'EcoFone Store - Transport Nagar',
        createdAt: DateTime.now(),
      );

      final result = await appState.submitTradeInQuote(quote);
      expect(result.quoteId, 'ECO-TRD-STATE-TEST');
      expect(appState.tradeInQuotes.any((q) => q.quoteId == 'ECO-TRD-STATE-TEST'), isTrue);

      backend.dispose();
    });
  });
}
