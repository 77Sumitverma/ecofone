import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:ecofone/models/order_model.dart';

/// Service coordinating Razorpay payment checkout with the EcoFone POS integration.
/// Implements the exact specs from the EcoFone App x POS Integration Guide.
class RazorpayCheckoutService {
  static const String defaultKeyId = 'rzp_test_ecofone_official';

  final String keyId;

  RazorpayCheckoutService({String? keyId}) : keyId = keyId ?? defaultKeyId;

  /// Builds the exact Razorpay options payload with crucial backup `notes`.
  /// The POS webhook reads these notes if the user's network or app terminates after paying.
  Map<String, dynamic> buildCheckoutOptions({
    required PhoneOrder order,
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String address,
    required String city,
    required String state,
    required String pincode,
  }) {
    final cleanPhone = customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigitPhone = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
    final amountPaise = order.price * 100;

    return {
      'key': keyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'EcoFone',
      'description': '${order.brand} ${order.phoneName} ${order.storage}',
      'prefill': {
        'name': customerName,
        'contact': tenDigitPhone,
        'email': customerEmail ?? 'customer@ecofone.in',
      },
      'notes': {
        'order_id': order.orderId,
        'customer_name': customerName,
        'customer_phone': tenDigitPhone,
        'customer_email': customerEmail ?? 'customer@ecofone.in',
        'customer_address': address,
        'customer_city': city,
        'customer_state': state,
        'customer_pincode': pincode,
        'brand': order.brand,
        'model': order.phoneName,
        'storage': order.storage,
        'color': order.color,
        'grade': order.conditionGrade,
      },
      'theme': {
        'color': '#0B4D3C', // EcoColors.forestGreen
      },
    };
  }

  /// Generates a mock or sandbox payment response for development & testing
  Map<String, String> generateMockPaymentSuccess() {
    final randomPart = Random().nextInt(899999) + 100000;
    final paymentId = 'pay_O7x${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}$randomPart';
    final orderId = 'order_O7xK3Yy${Random().nextInt(89999) + 10000}';
    debugPrint('[RazorpayCheckout] 💳 Mock Payment Success generated: $paymentId');
    return {
      'razorpay_payment_id': paymentId,
      'razorpay_order_id': orderId,
    };
  }
}
