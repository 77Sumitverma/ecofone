import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecofone/core/utils/phone_media_resolver.dart';
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

    test('Media URL normalization preserves .jpg network uploads & resolves PhoneOrder fallback assets', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host != 'api.ecofone.in') {
          return http.Response('Unreachable', 503);
        }
        if (request.url.path == '/api/v1/inventory') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': [
                {
                  'id': 'SKU-JPG-01',
                  'sku': 'SKU-JPG-01',
                  'name': 'iPhone 15',
                  'brand': 'Apple',
                  'storage': '128 GB',
                  'color': 'Blue',
                  'batteryHealth': 98,
                  'conditionGrade': 'Superb (Pristine)',
                  'refurbishedPrice': 62999,
                  'originalPrice': 79900,
                  'stockQuantity': 2,
                  'imageUrl': 'http://127.0.0.1:8000/uploads/catalog/iphone_15_photo.jpg',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/api/v1/inventory/SKU-JPG-01') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 'SKU-JPG-01',
                'sku': 'SKU-JPG-01',
                'name': 'iPhone 15',
                'brand': 'Apple',
                'storage': '128 GB',
                'color': 'Blue',
                'batteryHealth': 98,
                'conditionGrade': 'Superb (Pristine)',
                'refurbishedPrice': 62999,
                'originalPrice': 79900,
                'stockQuantity': 2,
                'imageUrl': '/uploads/catalog/iphone_15_photo.jpg',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = BillingApiService(
        baseUrl: 'https://api.ecofone.in',
        apiKey: 'eco_test_key_99182',
        client: mockClient,
      );

      final list = await service.fetchInventory();
      expect(list.first.imageUrl, 'https://api.ecofone.in/uploads/catalog/iphone_15_photo.jpg');

      final single = await service.fetchProductDetails('SKU-JPG-01');
      expect(single?.imageUrl, 'https://api.ecofone.in/uploads/catalog/iphone_15_photo.jpg');

      final ip14Order = PhoneOrder(
        orderId: 'ORD-14',
        phoneId: 'SKU-14',
        phoneName: 'iPhone 14',
        brand: 'Apple',
        storage: '128 GB',
        color: 'Midnight',
        price: 54999,
        conditionGrade: 'Superb',
        customerName: 'Test',
        customerPhone: '+91 9999999999',
        createdAt: DateTime.now(),
      );
      expect(ip14Order.effectiveImageUrl, 'assets/phones/iphone_14.png');

      final op12rOrder = ip14Order.copyWith(phoneName: 'OnePlus 12R 5G', brand: 'OnePlus');
      expect(op12rOrder.effectiveImageUrl, 'assets/phones/oneplus_12r.png');

      service.dispose();
    });

    test('PhoneMediaResolver resolves exact authentic photos for every brand, model & color', () {
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 14 Pro', 'Space Black'), 'assets/phones/iphone_14_pro.png');
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 14 Pro', 'Deep Purple'), 'assets/phones/iphone_14_pro_deep_purple.png');
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 14 Pro', 'Silver'), 'assets/phones/iphone_14_pro_silver.png');
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 14 Pro', 'Gold'), 'assets/phones/iphone_14_pro_gold.png');
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 14', 'Blue'), 'assets/phones/iphone_14_blue.png');
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 13', 'Starlight White'), 'assets/phones/iphone_13_starlight.png');
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 13', 'Midnight Blue'), 'assets/phones/iphone_13.png');
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 12', 'Product Red'), 'assets/phones/iphone_12_red.png');
      expect(PhoneMediaResolver.resolveColorAsset('Apple', 'iPhone 11', 'White'), 'assets/phones/iphone_11_white.png');
      expect(PhoneMediaResolver.resolveColorAsset('Samsung', 'Galaxy S23 Ultra 5G', 'Phantom Black'), 'assets/phones/galaxy_s23_ultra.png');
      expect(PhoneMediaResolver.resolveColorAsset('Samsung', 'Galaxy S23 Ultra 5G', 'Lavender'), 'assets/phones/galaxy_s23_ultra_lavender.png');
      expect(PhoneMediaResolver.resolveColorAsset('Samsung', 'Galaxy Z Flip 4 5G', 'Graphite'), 'assets/phones/galaxy_z_flip_4_graphite.png');
      expect(PhoneMediaResolver.resolveColorAsset('OnePlus', 'OnePlus 11 5G', 'Titan Black'), 'assets/phones/oneplus_11_titan_black.png');
      expect(PhoneMediaResolver.resolveColorAsset('OnePlus', 'OnePlus 12R 5G', 'Iron Gray'), 'assets/phones/oneplus_12r_iron_gray.png');
      expect(PhoneMediaResolver.resolveColorAsset('OnePlus', 'OnePlus Nord CE 2 Lite', 'Black Dusk'), 'assets/phones/oneplus_nord_ce_2_lite_black_dusk.png');
      expect(PhoneMediaResolver.resolveColorAsset('Google', 'Pixel 7 Pro', 'Obsidian'), 'assets/phones/pixel_7_pro_obsidian.png');
      expect(PhoneMediaResolver.resolveColorAsset('Google', 'Pixel 6a', 'Chalk White'), 'assets/phones/pixel_6a_chalk.png');
      expect(PhoneMediaResolver.resolveColorAsset('Google', 'Pixel 6a', 'Charcoal Black'), 'assets/phones/pixel_6a.png');
      expect(PhoneMediaResolver.resolveColorAsset('Xiaomi', 'Redmi Note 12 Pro 5G', 'Glacier Blue'), 'assets/phones/redmi_note_12_pro_blue.png');

      // Preserves custom URL for initialColor and dynamically swaps on color selection change
      expect(
        PhoneMediaResolver.resolveEffectiveImageUrl(
          brand: 'Apple',
          modelName: 'iPhone 14 Pro',
          selectedColor: 'Space Black',
          initialColor: 'Space Black',
          rawImageUrl: 'https://api.ecofone.in/uploads/custom.jpg',
        ),
        'https://api.ecofone.in/uploads/custom.jpg',
      );
      expect(
        PhoneMediaResolver.resolveEffectiveImageUrl(
          brand: 'Apple',
          modelName: 'iPhone 14 Pro',
          selectedColor: 'Deep Purple',
          initialColor: 'Space Black',
          rawImageUrl: 'https://api.ecofone.in/uploads/custom.jpg',
        ),
        'assets/phones/iphone_14_pro_deep_purple.png',
      );
    });
  });
}
