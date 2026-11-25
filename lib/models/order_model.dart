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
  final String? suggestedStoreId;  // Auto-calculated nearest physical store
  final double? suggestedDistanceKm;
  final String? approvalNotes;
  final String? approvedBy;

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
    this.orderStatus = 'Order Requested • Awaiting Approval',
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
    this.suggestedStoreId,
    this.suggestedDistanceKm,
    this.approvalNotes,
    this.approvedBy,
  });

  // Backward-compatibility getters
  String get reservationId => orderId;
  String get status => orderStatus;
  String get grade => conditionGrade;
  String get date => '1-2 Business Days';
  String get timeSlot => deliveryOption;
  String get visitDate => date;

  String get effectiveImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    final nameLower = phoneName.toLowerCase();
    final combined = '${brand.toLowerCase()} $nameLower';
    if (combined.contains('adapter') || combined.contains('charger')) {
      return 'assets/phones/apple_20w_adapter.png';
    }
    if (combined.contains('pixel 7 pro')) return 'assets/phones/pixel_7_pro.png';
    if (combined.contains('pixel 6') || combined.contains('pixel')) {
      return 'assets/phones/pixel_6a.png';
    }
    if (combined.contains('s23 ultra') ||
        (combined.contains('galaxy') && combined.contains('s23'))) {
      return 'assets/phones/galaxy_s23_ultra.png';
    }
    if (combined.contains('flip')) return 'assets/phones/galaxy_z_flip_4.png';
    if (combined.contains('12r') || combined.contains('oneplus 12')) {
      return 'assets/phones/oneplus_12r.png';
    }
    if (combined.contains('nord')) return 'assets/phones/oneplus_nord_ce_2_lite.png';
    if (combined.contains('oneplus 11') || combined.contains('oneplus')) {
      return 'assets/phones/oneplus_11.png';
    }
    if (combined.contains('redmi') || combined.contains('note 12')) {
      return 'assets/phones/redmi_note_12_pro.png';
    }
    if (combined.contains('iphone 14 pro') ||
        (combined.contains('apple') && combined.contains('14 pro'))) {
      return 'assets/phones/iphone_14_pro.png';
    }
    if (combined.contains('iphone 14') ||
        (combined.contains('apple') && combined.contains('14'))) {
      return 'assets/phones/iphone_14.png';
    }
    if (combined.contains('iphone 13') ||
        (combined.contains('apple') && combined.contains('13'))) {
      return 'assets/phones/iphone_13.png';
    }
    if (combined.contains('iphone 12') ||
        (combined.contains('apple') && combined.contains('12'))) {
      return 'assets/phones/iphone_12.png';
    }
    if (combined.contains('iphone 11') ||
        (combined.contains('apple') && combined.contains('11'))) {
      return 'assets/phones/iphone_11.png';
    }
    return 'assets/phones/pixel_7_pro.png';
  }

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
    'suggestedStoreId': suggestedStoreId,
    'suggested_store_id': suggestedStoreId,
    'suggestedDistanceKm': suggestedDistanceKm,
    'suggested_distance_km': suggestedDistanceKm,
    'approvalNotes': approvalNotes,
    'approval_notes': approvalNotes,
    'approvedBy': approvedBy,
    'approved_by': approvedBy,
  };

  static IconData _resolveOrderIcon(dynamic codePoint, String? brand) {
    if (codePoint != null) {
      final cp = codePoint is int ? codePoint : int.tryParse(codePoint.toString());
      if (cp != null) {
        if (cp == Icons.phone_iphone_rounded.codePoint) return Icons.phone_iphone_rounded;
        if (cp == Icons.phone_android_rounded.codePoint) return Icons.phone_android_rounded;
        if (cp == Icons.tablet_mac_rounded.codePoint) return Icons.tablet_mac_rounded;
        if (cp == Icons.tablet_android_rounded.codePoint) return Icons.tablet_android_rounded;
        if (cp == Icons.smartphone_rounded.codePoint) return Icons.smartphone_rounded;
      }
    }
    return (brand?.toLowerCase().contains('apple') ?? false)
        ? Icons.phone_iphone_rounded
        : Icons.smartphone_rounded;
  }

  factory PhoneOrder.fromJson(Map<String, dynamic> json) => PhoneOrder(
    orderId: (json['orderId'] ?? json['order_id'] ?? json['reservationId'] ?? 'ECO-ORD-000') as String,
    phoneId: (json['phoneId'] ?? json['phone_id'] ?? json['sku'] ?? '') as String,
    phoneName: (json['phoneName'] ?? json['model'] ?? json['product_name'] ?? 'Smartphone') as String,
    brand: (json['brand'] ?? json['manufacturer'] ?? 'Premium') as String,
    storage: (json['storage'] ?? json['capacity'] ?? '128 GB') as String,
    color: (json['color'] ?? 'Default') as String,
    price: (json['price'] as num?)?.toInt() ?? 0,
    conditionGrade: (json['conditionGrade'] ?? json['condition_grade'] ?? json['grade'] ?? 'Superb (Pristine)') as String,
    imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
    icon: _resolveOrderIcon(json['iconCodePoint'], (json['brand'] ?? json['manufacturer']) as String?),
    deliveryOption: (json['deliveryOption'] ?? json['delivery_option'] ?? 'Express Doorstep Delivery (1-2 Days)') as String,
    deliveryAddress: (json['deliveryAddress'] ?? json['delivery_address'] ?? 'Doorstep Delivery') as String,
    paymentMethod: (json['paymentMethod'] ?? json['payment_method'] ?? 'Cash on Delivery (COD)') as String,
    paymentStatus: (json['paymentStatus'] ?? json['payment_status'] ?? 'Pay after Doorstep Inspection') as String,
    orderStatus: (json['orderStatus'] ?? json['order_status'] ?? json['status'] ?? 'Order Confirmed • Dispatching in 24h') as String,
    storeId: (json['storeId'] ?? json['store_id'] ?? 'EF-STORE-LKO-01') as String,
    storeName: (json['storeName'] ?? json['store_name'] ?? 'EcoFone Store') as String,
    storeAddress: (json['storeAddress'] ?? json['store_address'] ?? '') as String,
    storePhone: (json['storePhone'] ?? json['store_phone'] ?? '') as String,
    storeMapsUrl: (json['storeMapsUrl'] ?? json['store_maps_url'] ?? '') as String,
    customerName: (json['customerName'] ?? json['customer_name'] ?? 'Valued Customer') as String,
    customerPhone: (json['customerPhone'] ?? json['customer_phone'] ?? '') as String,
    customerEmail: (json['customerEmail'] ?? json['customer_email']) as String?,
    customerCity: (json['customerCity'] ?? json['customer_city']) as String?,
    customerState: (json['customerState'] ?? json['customer_state']) as String?,
    customerPincode: (json['customerPincode'] ?? json['customer_pincode']) as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : (json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now()),
    isSynced: json['isSynced'] as bool? ?? true,
    invoiceNumber: (json['invoiceNumber'] ?? json['invoice_number']) as String?,
    saleNumber: (json['saleNumber'] ?? json['sale_number']) as String?,
    saleId: ((json['saleId'] ?? json['sale_id']) as num?)?.toInt(),
    imei1: (json['imei1'] ?? json['imei']) as String?,
    invoiceUrl: (json['invoiceUrl'] ?? json['invoice_url']) as String?,
    razorpayPaymentId: (json['razorpayPaymentId'] ?? json['razorpay_payment_id']) as String?,
    razorpayOrderId: (json['razorpayOrderId'] ?? json['razorpay_order_id']) as String?,
    suggestedStoreId: (json['suggestedStoreId'] ?? json['suggested_store_id']) as String?,
    suggestedDistanceKm: ((json['suggestedDistanceKm'] ?? json['suggested_distance_km']) as num?)?.toDouble(),
    approvalNotes: (json['approvalNotes'] ?? json['approval_notes']) as String?,
    approvedBy: (json['approvedBy'] ?? json['approved_by']) as String?,
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
    String? suggestedStoreId,
    double? suggestedDistanceKm,
    String? approvalNotes,
    String? approvedBy,
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
    suggestedStoreId: suggestedStoreId ?? this.suggestedStoreId,
    suggestedDistanceKm: suggestedDistanceKm ?? this.suggestedDistanceKm,
    approvalNotes: approvalNotes ?? this.approvalNotes,
    approvedBy: approvedBy ?? this.approvedBy,
  );
}

/// Alias for backward compatibility
typedef PhoneReservation = PhoneOrder;
