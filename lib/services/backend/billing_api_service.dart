import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ecofone/models/inventory_model.dart';
import 'package:ecofone/models/order_model.dart';
import 'package:ecofone/models/trade_in_model.dart';

/// BillingApiService coordinates REST API communication between the EcoFone
/// mobile app and the company's enterprise Billing / Point-of-Sale (POS) software backend.
///
/// Features:
/// - Real-time inventory synchronization with physical store registers
/// - Instant customer order dispatch into billing sales registers
/// - Instant trade-in valuation and quote submission into billing purchase registers
/// - Graceful offline & sandbox fallback with 0 crashing
class BillingApiService {
  final String? baseUrl;
  final String? apiKey;
  final http.Client _client;

  /// Whether the service is currently running in local sandbox/mock mode or live REST mode
  final bool isSandboxMode;

  BillingApiService({
    this.baseUrl,
    this.apiKey,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        isSandboxMode = (baseUrl == null || baseUrl.isEmpty || baseUrl == 'https://mock.billing.ecofone.internal');

  /// Standard HTTP headers for Billing API requests
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (apiKey != null && apiKey!.isNotEmpty) 'x-api-key': apiKey!,
        if (apiKey != null && apiKey!.isNotEmpty) 'Authorization': 'Bearer $apiKey',
      };

  /// Fetches real-time available inventory from the billing software
  Future<List<PhoneStockItem>> fetchInventory({String? storeId}) async {
    if (isSandboxMode) {
      debugPrint('[BillingAPI] Running in Sandbox mode. Serving cached catalog (${PhoneStockItem.sampleInventory.length} items).');
      return PhoneStockItem.sampleInventory;
    }

    try {
      final queryParams = storeId != null && storeId.isNotEmpty ? '?storeId=$storeId' : '';
      final uri = Uri.parse('$baseUrl/api/v1/inventory$queryParams');

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
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

        final items = itemsJson
            .map((item) => PhoneStockItem.fromJson(item as Map<String, dynamic>))
            .toList();

        debugPrint('[BillingAPI] ✅ Successfully fetched ${items.length} inventory items from billing software.');
        return items.isNotEmpty ? items : PhoneStockItem.sampleInventory;
      } else {
        debugPrint('[BillingAPI] ⚠️ Billing API returned status ${response.statusCode}. Falling back to default inventory.');
        return PhoneStockItem.sampleInventory;
      }
    } catch (e) {
      debugPrint('[BillingAPI] ❌ Billing API inventory fetch error: $e. Using offline fallback.');
      return PhoneStockItem.sampleInventory;
    }
  }

  /// Fetches specific device stock details by SKU or ID
  Future<PhoneStockItem?> fetchProductDetails(String skuOrId) async {
    if (isSandboxMode) {
      final matches = PhoneStockItem.sampleInventory.where((i) => i.id == skuOrId || i.effectiveSku == skuOrId);
      return matches.isNotEmpty ? matches.first : null;
    }

    try {
      final uri = Uri.parse('$baseUrl/api/v1/inventory/$skuOrId');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        return PhoneStockItem.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[BillingAPI] Error fetching product $skuOrId: $e');
    }
    return null;
  }

  /// Creates a customer purchase order in the billing software POS sales register (Backward compatible)
  Future<bool> createOrder(PhoneOrder order) async {
    if (isSandboxMode) {
      debugPrint('[BillingAPI] Sandbox order created for ${order.phoneName} (#${order.orderId})');
      return true;
    }

    try {
      final uri = Uri.parse('$baseUrl/api/v1/orders');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode({
              ...order.toJson(),
              'sku': order.phoneId,
              'clientTimestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[BillingAPI] Failed to push order to billing software: $e');
      return false;
    }
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
    final effectiveAmount = amount ?? order.price.toDouble();
    final cleanPhone = order.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');

    if (isSandboxMode) {
      final seed = (100 + DateTime.now().millisecond % 899).toString().padLeft(3, '0');
      final mockInvoiceNo = 'ECO-2026-000$seed';
      final mockSaleNo = 'SL-2026-000$seed';
      final mockImei = '35678910${(DateTime.now().millisecondsSinceEpoch % 10000000).toString().padLeft(7, '0')}';

      debugPrint('[BillingAPI] 🧾 Sandbox POS Invoice Generated: $mockInvoiceNo (Sale #$mockSaleNo, IMEI: $mockImei)');

      return order.copyWith(
        invoiceNumber: mockInvoiceNo,
        saleNumber: mockSaleNo,
        saleId: 412,
        imei1: mockImei,
        invoiceUrl: '/api/online/invoice/$mockInvoiceNo',
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        paymentStatus: 'Paid Online • Verified',
        orderStatus: 'INVOICED • Allocated ($mockInvoiceNo)',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/api/online/order');
      final payload = {
        "order_id": order.orderId,
        "channel": "APP",
        "customer": {
          "full_name": order.customerName,
          "phone": cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone,
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
      };

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (apiKey != null && apiKey!.isNotEmpty) 'x-api-key': apiKey!,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>? ?? {};

        final invoiceNo = data['invoice_number'] as String? ?? 'ECO-2026-000001';
        final saleNo = data['sale_number'] as String?;
        final saleId = (data['sale_id'] as num?)?.toInt();
        final phoneData = data['phone'] as Map<String, dynamic>?;
        final imei = phoneData?['imei1'] as String?;
        final invoiceUrl = data['invoice_url'] as String?;

        debugPrint('[BillingAPI] ✅ POS Order Created! Invoice: $invoiceNo, Sale: $saleNo, IMEI: $imei');

        return order.copyWith(
          invoiceNumber: invoiceNo,
          saleNumber: saleNo,
          saleId: saleId,
          imei1: imei,
          invoiceUrl: invoiceUrl,
          razorpayPaymentId: razorpayPaymentId,
          razorpayOrderId: razorpayOrderId,
          paymentStatus: 'Paid Online • Verified',
          orderStatus: 'INVOICED • Allocated ($invoiceNo)',
        );
      } else {
        debugPrint('[BillingAPI] ⚠️ POS returned error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[BillingAPI] ❌ Failed to call POS /api/online/order: $e');
    }

    // Graceful fallback with payment details attached
    return order.copyWith(
      razorpayPaymentId: razorpayPaymentId,
      razorpayOrderId: razorpayOrderId,
      paymentStatus: 'Paid Online (Pending POS Invoicing)',
    );
  }

  /// Official In-App Invoice Viewer:
  /// Calls `GET /api/online/invoice/:invoiceNumber` (No auth required)
  /// Returns items, price, warranty duration & expiry, GST breakup, store GSTIN, customer details.
  Future<Map<String, dynamic>?> fetchOnlineInvoice(String invoiceNumber) async {
    if (isSandboxMode) {
      debugPrint('[BillingAPI] Serving sandbox invoice data for $invoiceNumber');
      return {
        "invoice_number": invoiceNumber,
        "sale_number": "SL-2026-000452",
        "date": DateTime.now().toIso8601String(),
        "store": {
          "name": "EcoFone Flagship Hub",
          "gstin": "09AAACE1234F1Z5",
          "address": "Transport Nagar, Lucknow, UP 226012",
          "phone": "+91 99182 40555",
        },
        "customer": {
          "full_name": "Valued Customer",
          "phone": "+91 98765 43210",
          "address": "Lucknow, Uttar Pradesh",
          "pincode": "226010",
        },
        "item": {
          "brand": "Apple",
          "model": "iPhone 13",
          "storage": "128GB",
          "color": "Midnight Black",
          "grade": "Like New (Superb)",
          "imei1": "356789101234567",
          "price": 38999,
        },
        "margin_scheme_gst": {
          "rule": "Rule 32(5), Central Goods and Services Tax Rules (Refurbished Goods)",
          "selling_price": 38999,
          "taxable_margin": 4500,
          "cgst_percent": 9.0,
          "cgst_amount": 405,
          "sgst_percent": 9.0,
          "sgst_amount": 405,
          "total_gst": 810,
        },
        "warranty": {
          "duration_months": 6,
          "expiry_date": DateTime.now().add(const Duration(days: 180)).toIso8601String(),
          "type": "EcoFone 6-Month Comprehensive Protection",
          "status": "ACTIVE",
        },
      };
    }

    try {
      final uri = Uri.parse('$baseUrl/api/online/invoice/$invoiceNumber');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('[BillingAPI] Invoice fetch returned status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BillingAPI] Invoice fetch error for $invoiceNumber: $e');
    }
    return null;
  }

  /// Cancels an order in the billing software
  Future<bool> cancelOrder(String orderId) async {
    if (isSandboxMode) {
      debugPrint('[BillingAPI] Sandbox order cancelled for #$orderId');
      return true;
    }

    try {
      final uri = Uri.parse('$baseUrl/api/v1/orders/$orderId');
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 6));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[BillingAPI] Failed to cancel order #$orderId: $e');
      return false;
    }
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

    try {
      final uri = Uri.parse('$baseUrl/api/v1/trade-in/quote');
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(quote.toJson()),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map && decoded['data'] != null ? decoded['data'] : decoded;
        return TradeInQuote.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[BillingAPI] Trade-in quote submission error: $e');
    }
    return quote;
  }

  /// Verifies connectivity to the company's billing software server
  Future<bool> checkHealth() async {
    if (isSandboxMode) return true;

    try {
      final uri = Uri.parse('$baseUrl/api/v1/health');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Closes active HTTP connections
  void dispose() {
    _client.close();
  }
}
