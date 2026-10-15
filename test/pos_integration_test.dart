import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecofone/services/payment/razorpay_checkout_service.dart';
import 'package:ecofone/state/app_state.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('EcoFone App x POS Integration Tests', () {
    test('RazorpayCheckoutService builds exact notes payload for POS webhook fail-safe', () {
      final service = RazorpayCheckoutService();
      final order = PhoneOrder(
        orderId: 'APP-ORD-10829',
        phoneId: 'iphone_13_128',
        phoneName: 'iPhone 13',
        brand: 'Apple',
        storage: '128GB',
        color: 'Midnight Black',
        price: 38999,
        conditionGrade: 'Like New',
        customerName: 'Rahul Sharma',
        customerPhone: '+91 9876543210',
        customerEmail: 'rahul.sharma@gmail.com',
        customerCity: 'Indore',
        customerState: 'Madhya Pradesh',
        customerPincode: '452001',
        deliveryAddress: 'Flat 402, MG Road',
        createdAt: DateTime.now(),
      );

      final options = service.buildCheckoutOptions(
        order: order,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        customerEmail: order.customerEmail,
        address: order.deliveryAddress,
        city: order.customerCity ?? 'Indore',
        state: order.customerState ?? 'Madhya Pradesh',
        pincode: order.customerPincode ?? '452001',
      );

      expect(options['amount'], 38999 * 100);
      expect(options['currency'], 'INR');
      expect(options['name'], 'EcoFone');

      final notes = options['notes'] as Map<String, dynamic>;
      expect(notes['customer_name'], 'Rahul Sharma');
      expect(notes['customer_phone'], '9876543210');
      expect(notes['customer_email'], 'rahul.sharma@gmail.com');
      expect(notes['customer_address'], 'Flat 402, MG Road');
      expect(notes['customer_city'], 'Indore');
      expect(notes['customer_state'], 'Madhya Pradesh');
      expect(notes['customer_pincode'], '452001');
      expect(notes['brand'], 'Apple');
      expect(notes['model'], 'iPhone 13');
      expect(notes['storage'], '128GB');
      expect(notes['color'], 'Midnight Black');
      expect(notes['grade'], 'Like New');
    });

    test('BillingApiService.createOnlineOrder generates sequential invoice & allocates IMEI', () async {
      final billingApi = BillingApiService();
      final order = PhoneOrder(
        orderId: 'APP-ORD-10829',
        phoneId: 'iphone_13_128',
        phoneName: 'iPhone 13',
        brand: 'Apple',
        storage: '128GB',
        color: 'Midnight Black',
        price: 38999,
        conditionGrade: 'Like New',
        customerName: 'Rahul Sharma',
        customerPhone: '+91 9876543210',
        customerEmail: 'rahul.sharma@gmail.com',
        customerCity: 'Indore',
        customerState: 'Madhya Pradesh',
        customerPincode: '452001',
        deliveryAddress: 'Flat 402, MG Road',
        createdAt: DateTime.now(),
      );

      final result = await billingApi.createOnlineOrder(
        order: order,
        razorpayPaymentId: 'pay_O7xKwXv983LmQ1',
        razorpayOrderId: 'order_O7xK3Yy456AbCd',
      );

      expect(result.invoiceNumber, startsWith('ECO-2026-'));
      expect(result.saleNumber, startsWith('SL-2026-'));
      expect(result.imei1, isNotNull);
      expect(result.razorpayPaymentId, 'pay_O7xKwXv983LmQ1');
      expect(result.paymentStatus, contains('Paid Online'));
      expect(result.orderStatus, contains('INVOICED'));
    });

    test('BillingApiService.fetchOnlineInvoice returns margin-scheme GST Rule 32(5) and 6M Warranty', () async {
      final billingApi = BillingApiService();
      final invoice = await billingApi.fetchOnlineInvoice('ECO-2026-000452');

      expect(invoice, isNotNull);
      expect(invoice!['invoice_number'], 'ECO-2026-000452');

      final marginGst = invoice['margin_scheme_gst'] as Map<String, dynamic>;
      expect(marginGst['rule'], contains('Rule 32(5)'));
      expect(marginGst['total_gst'], 810);

      final warranty = invoice['warranty'] as Map<String, dynamic>;
      expect(warranty['duration_months'], 6);
      expect(warranty['status'], 'ACTIVE');
    });

    test('AppState.placeOnlineOrder records order with invoice & warranty in app state', () async {
      final appState = AppState.instance;
      final order = PhoneOrder(
        orderId: 'ECO-TEST-POS-001',
        phoneId: 's23_ultra',
        phoneName: 'Galaxy S23 Ultra',
        brand: 'Samsung',
        storage: '256GB',
        color: 'Phantom Black',
        price: 54999,
        conditionGrade: 'Pristine',
        customerName: 'Aman Singh',
        customerPhone: '+91 9123456789',
        createdAt: DateTime.now(),
      );

      final placedOrder = await appState.placeOnlineOrder(
        order: order,
        razorpayPaymentId: 'pay_TEST_999888',
        razorpayOrderId: 'order_TEST_111',
      );

      expect(placedOrder.invoiceNumber, isNotNull);
      expect(placedOrder.razorpayPaymentId, 'pay_TEST_999888');
      expect(appState.orders.any((o) => o.orderId == 'ECO-TEST-POS-001'), isTrue);
    });
  });
}
