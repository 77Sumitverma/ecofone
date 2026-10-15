import 'package:flutter/material.dart';
import 'package:ecofone/state/app_state.dart';

/// E-Commerce Smartphone Order Placed by Customer
class PhoneOrder {
  final String orderId;
  final String phoneId;
  final String phoneName;
  final String brand;
  final String storage;
  final String color;
  final int price;
  final String conditionGrade;
  final String? imageUrl;
  final IconData icon;
  final String deliveryOption; // 'Express Doorstep Delivery' or 'Store Pickup'
  final String deliveryAddress;
  final String paymentMethod;  // 'Cash on Delivery (COD)', 'Instant UPI', 'Credit/Debit Card'
  final String paymentStatus;  // 'Pending Payment on Delivery' or 'Paid Online'
  final String orderStatus;    // 'Confirmed • Dispatch in 24h', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'
  final String storeId;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeMapsUrl;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? customerCity;
  final String? customerState;
  final String? customerPincode;
  final DateTime createdAt;
  final bool isSynced;

  // --- Official POS Integration Fields (per POS Guide) ---
  final String? invoiceNumber;     // e.g. "ECO-2026-000452"
  final String? saleNumber;        // e.g. "SL-2026-000452"
  final int? saleId;               // e.g. 412
  final String? imei1;             // Allocated Serialized Device IMEI
  final String? invoiceUrl;        // e.g. "/api/online/invoice/ECO-2026-000452"
  final String? razorpayPaymentId; // Idempotency key (e.g. "pay_O7xKwXv983LmQ1")
  final String? razorpayOrderId;   // e.g. "order_O7xK3Yy456AbCd"

  const PhoneOrder({
    required this.orderId,
    required this.phoneId,
    required this.phoneName,
    this.brand = 'Apple / Premium',
    required this.storage,
    required this.color,
    required this.price,
    required this.conditionGrade,
    this.imageUrl,
    this.icon = Icons.smartphone_rounded,
    this.deliveryOption = 'Express Doorstep Delivery (1-2 Days)',
    this.deliveryAddress = 'Home Delivery Address',
    this.paymentMethod = 'Cash on Delivery (COD)',
    this.paymentStatus = 'Pay after Doorstep Inspection',
    this.orderStatus = 'Order Confirmed • Dispatching in 24h',
    this.storeId = 'EF-STORE-LKO-01',
    this.storeName = 'EcoFone Flagship Hub',
    this.storeAddress = 'Transport Nagar, Lucknow',
    this.storePhone = '+91 99182 40555',
    this.storeMapsUrl = '',
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.customerCity,
    this.customerState,
    this.customerPincode,
    required this.createdAt,
    this.isSynced = true,
    this.invoiceNumber,
    this.saleNumber,
    this.saleId,
    this.imei1,
    this.invoiceUrl,
    this.razorpayPaymentId,
    this.razorpayOrderId,
  });

  // Backward-compatibility getters
  String get reservationId => orderId;
  String get status => orderStatus;
  String get grade => conditionGrade;
  String get date => '1-2 Business Days';
  String get timeSlot => deliveryOption;
  String get visitDate => date;

  EcoStore get store {
    final matching = AppState.allStores.where((s) => s.id == storeId).toList();
    if (matching.isNotEmpty) return matching.first;

    final resolved = AppState.resolvePincodeOrCity(storeAddress.isNotEmpty ? storeAddress : storeName);
    return EcoStore(
      id: storeId,
      name: storeName,
      city: resolved.city,
      pincode: resolved.pincode,
      area: resolved.area,
      address: storeAddress.isNotEmpty ? storeAddress : storeName,
      phone: storePhone.isNotEmpty ? storePhone : '+91 99182 40555',
      timings: '10:00 AM - 9:00 PM (Open All 7 Days)',
      distanceKm: 1.0,
      rating: 4.9,
      reviewCount: 200,
      services: const ['32-Point Diagnostics', 'Instant Buy & Express Delivery'],
      landmark: 'EcoFone Hub',
      metroStation: 'Nearby Station',
      latitude: resolved.lat,
      longitude: resolved.lng,
      googleMapsUrl: storeMapsUrl.isNotEmpty ? storeMapsUrl : 'https://maps.google.com/?q=${resolved.lat},${resolved.lng}',
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'reservationId': orderId,
    'phoneId': phoneId,
    'phoneName': phoneName,
    'brand': brand,
    'storage': storage,
    'color': color,
    'price': price,
    'conditionGrade': conditionGrade,
    'imageUrl': imageUrl,
    'iconCodePoint': icon.codePoint,
    'deliveryOption': deliveryOption,
    'deliveryAddress': deliveryAddress,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'orderStatus': orderStatus,
    'status': orderStatus,
    'storeId': storeId,
    'storeName': storeName,
    'storeAddress': storeAddress,
    'storePhone': storePhone,
    'storeMapsUrl': storeMapsUrl,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'customerCity': customerCity,
    'customerState': customerState,
    'customerPincode': customerPincode,
    'createdAt': createdAt.toIso8601String(),
    'isSynced': isSynced,
    'invoiceNumber': invoiceNumber,
    'saleNumber': saleNumber,
    'saleId': saleId,
    'imei1': imei1,
    'invoiceUrl': invoiceUrl,
    'razorpayPaymentId': razorpayPaymentId,
    'razorpayOrderId': razorpayOrderId,
  };

  factory PhoneOrder.fromJson(Map<String, dynamic> json) => PhoneOrder(
    orderId: (json['orderId'] ?? json['reservationId'] ?? 'ECO-ORD-000') as String,
    phoneId: json['phoneId'] as String? ?? '',
    phoneName: (json['phoneName'] ?? json['product_name'] ?? 'Smartphone') as String,
    brand: json['brand'] as String? ?? 'Premium',
    storage: json['storage'] as String? ?? '128 GB',
    color: json['color'] as String? ?? 'Default',
    price: (json['price'] as num?)?.toInt() ?? 0,
    conditionGrade: json['conditionGrade'] as String? ?? 'Superb (Pristine)',
    imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
    icon: json['iconCodePoint'] != null
        ? IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons')
        : Icons.smartphone_rounded,
    deliveryOption: json['deliveryOption'] as String? ?? 'Express Doorstep Delivery (1-2 Days)',
    deliveryAddress: json['deliveryAddress'] as String? ?? 'Doorstep Delivery',
    paymentMethod: json['paymentMethod'] as String? ?? 'Cash on Delivery (COD)',
    paymentStatus: json['paymentStatus'] as String? ?? 'Pay after Doorstep Inspection',
    orderStatus: (json['orderStatus'] ?? json['status'] ?? 'Order Confirmed • Dispatching in 24h') as String,
    storeId: json['storeId'] as String? ?? 'EF-STORE-LKO-01',
    storeName: json['storeName'] as String? ?? 'EcoFone Store',
    storeAddress: json['storeAddress'] as String? ?? '',
    storePhone: json['storePhone'] as String? ?? '',
    storeMapsUrl: json['storeMapsUrl'] as String? ?? '',
    customerName: json['customerName'] as String? ?? 'Valued Customer',
    customerPhone: json['customerPhone'] as String? ?? '',
    customerEmail: json['customerEmail'] as String?,
    customerCity: json['customerCity'] as String?,
    customerState: json['customerState'] as String?,
    customerPincode: json['customerPincode'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    isSynced: json['isSynced'] as bool? ?? true,
    invoiceNumber: json['invoiceNumber'] as String?,
    saleNumber: json['saleNumber'] as String?,
    saleId: (json['saleId'] as num?)?.toInt(),
    imei1: json['imei1'] as String?,
    invoiceUrl: json['invoiceUrl'] as String?,
    razorpayPaymentId: json['razorpayPaymentId'] as String?,
    razorpayOrderId: json['razorpayOrderId'] as String?,
  );

  PhoneOrder copyWith({
    String? orderId,
    String? phoneId,
    String? phoneName,
    String? brand,
    String? storage,
    String? color,
    int? price,
    String? conditionGrade,
    IconData? icon,
    String? deliveryOption,
    String? deliveryAddress,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    String? storeId,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? storeMapsUrl,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerCity,
    String? customerState,
    String? customerPincode,
    DateTime? createdAt,
    bool? isSynced,
    String? invoiceNumber,
    String? saleNumber,
    int? saleId,
    String? imei1,
    String? invoiceUrl,
    String? razorpayPaymentId,
    String? razorpayOrderId,
  }) => PhoneOrder(
    orderId: orderId ?? this.orderId,
    phoneId: phoneId ?? this.phoneId,
    phoneName: phoneName ?? this.phoneName,
    brand: brand ?? this.brand,
    storage: storage ?? this.storage,
    color: color ?? this.color,
    price: price ?? this.price,
    conditionGrade: conditionGrade ?? this.conditionGrade,
    icon: icon ?? this.icon,
    deliveryOption: deliveryOption ?? this.deliveryOption,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    orderStatus: orderStatus ?? this.orderStatus,
    storeId: storeId ?? this.storeId,
    storeName: storeName ?? this.storeName,
    storeAddress: storeAddress ?? this.storeAddress,
    storePhone: storePhone ?? this.storePhone,
    storeMapsUrl: storeMapsUrl ?? this.storeMapsUrl,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    customerEmail: customerEmail ?? this.customerEmail,
    customerCity: customerCity ?? this.customerCity,
    customerState: customerState ?? this.customerState,
    customerPincode: customerPincode ?? this.customerPincode,
    createdAt: createdAt ?? this.createdAt,
    isSynced: isSynced ?? this.isSynced,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    saleNumber: saleNumber ?? this.saleNumber,
    saleId: saleId ?? this.saleId,
    imei1: imei1 ?? this.imei1,
    invoiceUrl: invoiceUrl ?? this.invoiceUrl,
    razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
    razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
  );
}

/// Alias for backward compatibility
typedef PhoneReservation = PhoneOrder;
