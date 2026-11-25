import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ecofone/models/inventory_model.dart';
import 'package:ecofone/models/order_model.dart';
import 'package:ecofone/models/trade_in_model.dart';
import 'package:ecofone/models/banner_model.dart';
import 'package:ecofone/models/user_profile.dart';

/// BillingApiService coordinates REST API communication between the EcoFone
/// mobile app and the company's enterprise Billing / Point-of-Sale (POS) software backend.
///
/// Features:
/// - Real-time inventory synchronization with physical store registers
/// - Instant customer order dispatch into billing sales registers
/// - Instant trade-in valuation and quote submission into billing purchase registers
/// - Seamless multi-host fallback (Wi-Fi IP + USB ADB Reverse) with 0 crashing
class BillingApiService {
  final String? baseUrl;
  final String? apiKey;
  final http.Client _client;

  /// Cached active base URL that has proven responsive
  String? _workingBaseUrl;

  /// Whether the service is currently running in local sandbox/mock mode or live REST mode
  final bool isSandboxMode;

  BillingApiService({
    this.baseUrl,
    this.apiKey,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        isSandboxMode = (baseUrl == null || baseUrl.isEmpty || baseUrl == 'https://mock.billing.ecofone.internal');

  /// Dynamic list of candidate base URLs to try in order (ensures Wi-Fi and USB both work seamlessly)
  List<String> get candidateBaseUrls {
    final list = <String>[];
    if (_workingBaseUrl != null && _workingBaseUrl!.isNotEmpty) {
      list.add(_workingBaseUrl!);
    }
    // Prioritize active PC Wi-Fi host for seamless direct physical phone connection on local Wi-Fi
    const activeWifiHost = 'http://192.168.1.17:8000';
    if (!list.contains(activeWifiHost)) {
      list.add(activeWifiHost);
    }
    if (baseUrl != null && baseUrl!.isNotEmpty && baseUrl != 'https://mock.billing.ecofone.internal') {
      if (!list.contains(baseUrl)) list.add(baseUrl!);
    }
    const defaults = [
      'http://192.168.1.17:8000',
      'http://127.0.0.1:8000',
      'http://192.168.1.16:8000',
      'http://192.168.1.18:8000',
      'http://192.168.1.15:8000',
      'http://192.168.1.19:8000',
      'http://192.168.1.20:8000',
      'http://10.0.2.2:8000',
      'http://127.0.0.1:5000',
      'http://10.0.2.2:5000',
    ];
    for (final d in defaults) {
      if (!list.contains(d)) list.add(d);
    }
    return list;
  }

  /// Standard HTTP headers for Billing API requests
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (apiKey != null && apiKey!.isNotEmpty) 'x-api-key': apiKey!,
        if (apiKey != null && apiKey!.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

  /// Rewrites localhost / emulator / relative paths returned by backend APIs to match the active host.
  String _normalizeMediaUrl(String rawUrl, String activeHost) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    final cleanHost = activeHost.endsWith('/')
        ? activeHost.substring(0, activeHost.length - 1)
        : activeHost;
    if (trimmed.startsWith('/')) {
      return '$cleanHost$trimmed';
    }
    if (trimmed.startsWith('assets/') || trimmed.startsWith('uploads/')) {
      return '$cleanHost/$trimmed';
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null) {
      const localDevHosts = {
        '127.0.0.1',
        'localhost',
        '10.0.2.2',
        '192.168.1.16',
        '192.168.1.17',
      };
      if (localDevHosts.contains(parsed.host)) {
        final query = parsed.hasQuery ? '?${parsed.query}' : '';
        final fragment = parsed.hasFragment ? '#${parsed.fragment}' : '';
        return '$cleanHost${parsed.path}$query$fragment';
      }
    }
    return trimmed;
  }

  /// Fetches real-time available inventory from the billing software
  Future<List<PhoneStockItem>> fetchInventory({String? storeId}) async {
    if (isSandboxMode) {
      debugPrint('[BillingAPI] Running in Sandbox mode. Serving cached catalog (${PhoneStockItem.sampleInventory.length} items).');
      return PhoneStockItem.sampleInventory;
    }

    final queryParams = storeId != null && storeId.isNotEmpty ? '?storeId=$storeId' : '';

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/inventory$queryParams');
        final response = await _client
            .get(uri, headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (apiKey != null && apiKey!.isNotEmpty) 'x-api-key': apiKey!,
            })
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          _workingBaseUrl = host;
          final decoded = jsonDecode(response.body);
          final List<dynamic> itemsJson;

          if (decoded is List) {
            itemsJson = decoded;
          } else if (decoded is Map && decoded['data'] is List) {
            itemsJson = decoded['data'] as List;
          } else if (decoded is Map && decoded['items'] is List) {
            itemsJson = decoded['items'] as List;
          } else {
            itemsJson = [];
          }

          final items = itemsJson.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final rawImg = (map['imageUrl'] ?? map['image_url'] ?? map['image']) as String?;
            if (rawImg != null && rawImg.isNotEmpty) {
              final normalized = _normalizeMediaUrl(rawImg, host);
              map['imageUrl'] = normalized;
              map['image_url'] = normalized;
            }
            return PhoneStockItem.fromJson(map);
          }).toList();

          if (items.isNotEmpty) {
            debugPrint('[BillingAPI] ✅ Connected to $host! Fetched ${items.length} live smartphone items.');
            return items;
          }
        }
      } catch (e) {
        debugPrint('[BillingAPI] Attempt on $host failed: $e, trying next candidate...');
      }
    }

    debugPrint('[BillingAPI] ⚠️ All endpoints unreachable. Using cached catalog fallback.');
    return PhoneStockItem.sampleInventory;
  }

  /// Fetches specific device stock details by SKU or ID
  Future<PhoneStockItem?> fetchProductDetails(String skuOrId) async {
    if (isSandboxMode) {
      final matches = PhoneStockItem.sampleInventory.where((i) => i.id == skuOrId || i.effectiveSku == skuOrId);
      return matches.isNotEmpty ? matches.first : null;
    }

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/inventory/${Uri.encodeComponent(skuOrId)}');
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          _workingBaseUrl = host;
          final decoded = jsonDecode(response.body);
          final rawData = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
          if (rawData is Map) {
            final map = Map<String, dynamic>.from(rawData);
            final rawImg = (map['imageUrl'] ?? map['image_url'] ?? map['image']) as String?;
            if (rawImg != null && rawImg.isNotEmpty) {
              final normalized = _normalizeMediaUrl(rawImg, host);
              map['imageUrl'] = normalized;
              map['image_url'] = normalized;
            }
            return PhoneStockItem.fromJson(map);
          }
        }
      } catch (e) {
        // Continue to next candidate
      }
    }
    return null;
  }

  /// Creates a customer purchase order in the billing software POS sales register (Backward compatible)
  Future<bool> createOrder(PhoneOrder order) async {
    if (isSandboxMode) {
      debugPrint('[BillingAPI] Sandbox order created for #${order.orderId}');
      return true;
    }

    final payload = jsonEncode({
      ...order.toJson(),
      'sku': order.phoneId,
      'clientTimestamp': DateTime.now().toIso8601String(),
    });

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/orders');
        final response = await _client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (apiKey != null && apiKey!.isNotEmpty) 'x-api-key': apiKey!,
              },
              body: payload,
            )
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200 || response.statusCode == 201) {
          _workingBaseUrl = host;
          debugPrint('[BillingAPI] ✅ Order synced to $host successfully (#${order.orderId})');
          return true;
        }
      } catch (e) {
        // Try next
      }
    }
    return false;
  }

  /// Official EcoFone POS Integration API (per Integration Guide):
  /// Calls `POST /api/online/order` with `x-api-key`.
  /// Automatically allocates IMEI from ECO-ONLINE store, calculates margin-scheme GST,
  /// activates 6-Month Warranty, and generates sequential invoice (ECO-2026-XXXXXX).
  Future<PhoneOrder> createOnlineOrder({
    required PhoneOrder order,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    double? amount,
  }) async {
    if (isSandboxMode) {
      return order.copyWith(
        invoiceNumber: 'ECO-2026-000452',
        saleNumber: 'SL-2026-000452',
        saleId: 452,
        imei1: '356789104529811',
        invoiceUrl: 'https://billing.ecofone.internal/invoices/ECO-2026-000452.pdf',
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        paymentStatus: 'Paid Online • Verified',
        orderStatus: 'INVOICED • Allocated (ECO-2026-000452)',
      );
    }

    final effectiveAmount = amount ?? order.price.toDouble();
    final cleanPhone = order.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigitPhone = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    final payload = {
      "order_id": order.orderId,
      "channel": "APP",
      "customer": {
        "full_name": order.customerName,
        "phone": tenDigitPhone,
        "email": order.customerEmail ?? 'customer@ecofone.in',
        "address": order.deliveryAddress,
        "city": order.customerCity ?? 'Lucknow',
        "state": order.customerState ?? 'Uttar Pradesh',
        "pincode": order.customerPincode ?? '226010',
      },
      "item": {
        "brand": order.brand,
        "model": order.phoneName,
        "storage": order.storage,
        "color": order.color,
        "grade": order.conditionGrade,
      },
      "payment": {
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_order_id": razorpayOrderId ?? '',
        "amount": effectiveAmount,
      },
      "payment_method": order.paymentMethod,
      "payment_status": order.paymentStatus,
      // Flat fields for dual compatibility
      "customerName": order.customerName,
      "customerPhone": tenDigitPhone,
      "phoneName": order.phoneName,
      "price": effectiveAmount.toInt(),
    };

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/online/order');
        final response = await _client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'x-api-key': apiKey ?? 'eco_test_key_99182',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200 || response.statusCode == 201) {
          _workingBaseUrl = host;
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final data = decoded['data'] as Map<String, dynamic>? ?? {};

          final invoiceNo = data['invoice_number'] as String? ?? 'ECO-2026-000001';
          final saleNo = data['sale_number'] as String?;
          final saleId = (data['sale_id'] as num?)?.toInt();
          final phoneData = data['phone'] as Map<String, dynamic>?;
          final imei = phoneData?['imei1'] as String?;
          final invoiceUrl = data['invoice_url'] as String?;
          final assignedStoreId = data['store_id'] as String?;
          final assignedStoreName = data['store_name'] as String?;
          final suggestedStoreId = data['suggested_store_id'] as String?;
          final suggestedDist = (data['suggested_distance_km'] as num?)?.toDouble();

          debugPrint('[BillingAPI] ✅ Connected to $host! Order Created: Invoice $invoiceNo, Sale: $saleNo, IMEI: $imei, Store: $assignedStoreId ($assignedStoreName)');

          return order.copyWith(
            invoiceNumber: invoiceNo,
            saleNumber: saleNo,
            saleId: saleId,
            imei1: imei,
            invoiceUrl: invoiceUrl,
            storeId: assignedStoreId ?? order.storeId,
            storeName: assignedStoreName ?? order.storeName,
            suggestedStoreId: suggestedStoreId ?? order.suggestedStoreId,
            suggestedDistanceKm: suggestedDist ?? order.suggestedDistanceKm,
            razorpayPaymentId: razorpayPaymentId,
            razorpayOrderId: razorpayOrderId,
            paymentStatus: order.paymentStatus.contains('Delivery') ? 'Pay after Doorstep Inspection' : 'Paid Online • Verified',
            orderStatus: 'CONFIRMED • Allocated ($invoiceNo)',
          );
        } else {
          debugPrint('[BillingAPI] Endpoint $host returned status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('[BillingAPI] Order dispatch to $host failed: $e, trying next candidate...');
      }
    }

    debugPrint('[BillingAPI] ⚠️ All endpoints unreachable. Using offline order record.');
    final fallbackInvoiceNo = 'ECO-2026-000${(DateTime.now().millisecondsSinceEpoch % 899).toString().padLeft(3, '0')}';
    return order.copyWith(
      invoiceNumber: fallbackInvoiceNo,
      razorpayPaymentId: razorpayPaymentId,
      razorpayOrderId: razorpayOrderId,
      paymentStatus: order.paymentStatus.contains('Delivery') ? 'Pay after Doorstep Inspection' : 'Paid Online (Pending Sync)',
      orderStatus: 'CONFIRMED • In Queue',
    );
  }

  /// Official In-App Invoice Viewer:
  /// Calls `GET /api/online/invoice/:invoiceNumber` (No auth required)
  /// Returns items, price, warranty duration & expiry, GST breakup, store GSTIN, customer details.
  Future<Map<String, dynamic>?> fetchOnlineInvoice(String invoiceNumber) async {
    if (isSandboxMode) {
      return {
        "invoice_number": invoiceNumber,
        "sale_number": "SL-2026-000452",
        "order_id": "APP-ORD-10829",
        "customer": {
          "name": "Rahul Sharma",
          "phone": "9876543210",
          "address": "Flat 402, MG Road, Indore, MP - 452001",
        },
        "item": {
          "brand": "Apple",
          "model": "iPhone 13",
          "storage": "128GB",
          "color": "Midnight Black",
          "condition_grade": "Like New",
          "imei": "356789104529811",
          "hsn_code": "85171200",
        },
        "pricing": {
          "selling_price": 38999,
          "purchase_cost": 34500,
          "margin": 4499,
        },
        "margin_scheme_gst": {
          "rule": "Rule 32(5) CGST / SGST Rules",
          "description": "GST charged only on profit margin of pre-owned goods",
          "taxable_value": 4499,
          "cgst_rate": "9%",
          "cgst_amount": 405.00,
          "sgst_rate": "9%",
          "sgst_amount": 405.00,
          "total_gst": 810,
        },
        "warranty": {
          "duration_months": 6,
          "type": "EcoFone Certified Comprehensive Warranty",
          "valid_until": "2027-04-28",
          "status": "ACTIVE",
        },
      };
    }

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/online/invoice/$invoiceNumber');
        final response = await _client
            .get(uri)
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          _workingBaseUrl = host;
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        // Try next candidate
      }
    }
    return null;
  }

  /// Fetches real-time customer orders from backend database (with live dispatch/delivery status)
  Future<List<PhoneOrder>> fetchUserOrders(String userPhone) async {
    if (isSandboxMode) return [];

    final cleanPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigit = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/orders?phone=$tenDigit');
        final response = await _client
            .get(uri, headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (apiKey != null && apiKey!.isNotEmpty) 'x-api-key': apiKey!,
            })
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          _workingBaseUrl = host;
          final decoded = jsonDecode(response.body);
          final List<dynamic> itemsJson = decoded is Map && decoded['data'] is List
              ? decoded['data'] as List
              : (decoded is List ? decoded : []);

          final orders = itemsJson
              .map((item) => PhoneOrder.fromJson(item as Map<String, dynamic>))
              .toList();

          debugPrint('[BillingAPI] ✅ Fetched ${orders.length} real-time user orders from $host');
          return orders;
        }
      } catch (e) {
        // Try next candidate
      }
    }
    return [];
  }

  /// Cancels an order in the billing software
  Future<bool> cancelOrder(String orderId) async {
    if (isSandboxMode) {
      debugPrint('[BillingAPI] Sandbox order cancelled for #$orderId');
      return true;
    }

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/orders/$orderId');
        final response = await _client
            .delete(uri, headers: _headers)
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200 || response.statusCode == 204) {
          _workingBaseUrl = host;
          return true;
        }
      } catch (e) {
        // Try next
      }
    }
    return false;
  }

  // Backward-compatible aliases
  Future<bool> createHoldReservation(PhoneOrder reservation) => createOrder(reservation);
  Future<bool> releaseHoldReservation(String reservationId) => cancelOrder(reservationId);

  /// Submits a customer Trade-in / Buyback quote into the billing software's purchase register
  Future<TradeInQuote> submitTradeInQuote(TradeInQuote quote) async {
    if (isSandboxMode) {
      debugPrint('[BillingAPI] Sandbox Trade-In quote logged: ${quote.modelName} (₹${quote.estimatedPayout})');
      return quote;
    }

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/trade-in/quote');
        final response = await _client
            .post(
              uri,
              headers: _headers,
              body: jsonEncode(quote.toJson()),
            )
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200 || response.statusCode == 201) {
          _workingBaseUrl = host;
          final decoded = jsonDecode(response.body);
          final data = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
          return TradeInQuote.fromJson(data as Map<String, dynamic>);
        }
      } catch (e) {
        // Try next
      }
    }
    return quote;
  }

  /// Fetches dynamic app promotional hero banners from the Super Admin backend
  Future<List<AppBanner>> fetchBanners() async {
    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/banners');
        final response = await _client
            .get(uri, headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (apiKey != null && apiKey!.isNotEmpty) 'x-api-key': apiKey!,
            })
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          _workingBaseUrl = host;
          final decoded = jsonDecode(response.body);
          final List<dynamic> itemsJson = decoded is Map && decoded['data'] is List
              ? decoded['data'] as List
              : (decoded is List ? decoded : []);

          final banners = itemsJson
              .map((b) {
                final map = Map<String, dynamic>.from(b as Map);
                if (map['image_url'] != null && map['image_url'] is String) {
                  map['image_url'] = _normalizeMediaUrl(map['image_url'] as String, host);
                }
                return AppBanner.fromJson(map);
              })
              .where((b) => b.isActive)
              .toList();

          if (banners.isNotEmpty) {
            debugPrint('[BillingAPI] ✅ Connected to $host! Loaded ${banners.length} live app hero banners.');
            return banners;
          }
        }
      } catch (e) {
        // Continue to next candidate
      }
    }
    return AppBanner.defaultBanners;
  }

  /// Submits an In-Store VIP visit or test bench appointment to the central backend
  Future<bool> bookAppointment(Map<String, dynamic> appointmentData) async {
    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/appointments');
        final response = await _client
            .post(
              uri,
              headers: _headers,
              body: jsonEncode(appointmentData),
            )
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200 || response.statusCode == 201) {
          _workingBaseUrl = host;
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Lookup user by phone from central backend database.
  /// Returns UserProfile with isNewUser=false if registered, or isNewUser=true if not found.
  Future<UserProfile?> lookupUser(String phone) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigit = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;
    if (tenDigit.isEmpty) return null;

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/user/sync?phone=$tenDigit');
        final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          _workingBaseUrl = host;
          final isNew = data['is_new_user'] == true;
          if (!isNew && data['user'] != null) {
            final userMap = data['user'] as Map<String, dynamic>;
            return UserProfile.fromJson({
              ...userMap,
              'isNewUser': false,
            });
          } else {
            return UserProfile(
              name: '',
              phone: '+91 $tenDigit',
              isNewUser: true,
            );
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Syncs or registers a user profile to the central backend database
  Future<UserProfile?> syncUser({required UserProfile profile}) async {
    final cleanDigits = profile.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigit = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : cleanDigits;

    final payload = {
      'phone': tenDigit,
      'name': profile.name,
      'alternate_phone': profile.alternatePhone ?? '',
      'email': profile.email ?? '',
      'city': profile.city ?? '',
      'area': profile.area ?? '',
      'pincode': profile.pincode ?? '',
    };

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/user/sync');
        final response = await _client
            .post(
              uri,
              headers: _headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          _workingBaseUrl = host;
          if (data['user'] != null) {
            final userMap = data['user'] as Map<String, dynamic>;
            return UserProfile.fromJson({
              ...userMap,
              'isNewUser': false,
            });
          }
          return profile.copyWith(isNewUser: false);
        }
      } catch (_) {}
    }
    return null;
  }

  /// Verifies connectivity to the company's billing software server
  Future<bool> checkHealth() async {
    if (isSandboxMode) return true;

    for (final host in candidateBaseUrls) {
      try {
        final uri = Uri.parse('$host/api/v1/health');
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          _workingBaseUrl = host;
          return true;
        }
      } catch (e) {
        try {
          final uri = Uri.parse('$host/api/online/inventory');
          final response = await _client
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) {
            _workingBaseUrl = host;
            return true;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  /// Closes active HTTP connections
  void dispose() {
    _client.close();
  }
}
