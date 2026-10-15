class TradeInQuote {
  final String quoteId;
  final String brand;
  final String modelName;
  final String storage;
  final int estimatedPayout;
  final String screenCondition;
  final String bodyCondition;
  final bool turnsOn;
  final bool cameraWorking;
  final bool batteryHealthy;
  final bool biometricsWorking;
  final bool speakerWorking;
  final bool hasCharger;
  final bool hasBox;
  final bool hasBill;
  final String customerName;
  final String customerPhone;
  final String storeId;
  final String storeName;
  final String payoutMethod;
  final String status;
  final DateTime createdAt;

  const TradeInQuote({
    required this.quoteId,
    required this.brand,
    required this.modelName,
    required this.storage,
    required this.estimatedPayout,
    required this.screenCondition,
    required this.bodyCondition,
    this.turnsOn = true,
    this.cameraWorking = true,
    this.batteryHealthy = true,
    this.biometricsWorking = true,
    this.speakerWorking = true,
    this.hasCharger = true,
    this.hasBox = true,
    this.hasBill = true,
    required this.customerName,
    required this.customerPhone,
    required this.storeId,
    required this.storeName,
    this.payoutMethod = 'In-Store Walk-in (15-Min Instant Payout)',
    this.status = 'Pending In-Store Inspection',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'quoteId': quoteId,
    'brand': brand,
    'modelName': modelName,
    'storage': storage,
    'estimatedPayout': estimatedPayout,
    'screenCondition': screenCondition,
    'bodyCondition': bodyCondition,
    'turnsOn': turnsOn,
    'cameraWorking': cameraWorking,
    'batteryHealthy': batteryHealthy,
    'biometricsWorking': biometricsWorking,
    'speakerWorking': speakerWorking,
    'hasCharger': hasCharger,
    'hasBox': hasBox,
    'hasBill': hasBill,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'storeId': storeId,
    'storeName': storeName,
    'payoutMethod': payoutMethod,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TradeInQuote.fromJson(Map<String, dynamic> json) => TradeInQuote(
    quoteId: (json['quoteId'] ?? json['quote_id'] ?? 'ECO-TRD-000') as String,
    brand: (json['brand'] ?? 'Apple') as String,
    modelName: (json['modelName'] ?? json['model_name'] ?? json['model'] ?? 'Smartphone') as String,
    storage: (json['storage'] ?? '128 GB') as String,
    estimatedPayout: (json['estimatedPayout'] ?? json['estimated_payout'] ?? json['payout_amount'] ?? json['price'] as num?)?.toInt() ?? 0,
    screenCondition: (json['screenCondition'] ?? json['screen_condition'] ?? 'Flawless') as String,
    bodyCondition: (json['bodyCondition'] ?? json['body_condition'] ?? 'Flawless') as String,
    turnsOn: (json['turnsOn'] ?? json['turns_on'] ?? true) as bool,
    cameraWorking: (json['cameraWorking'] ?? json['camera_working'] ?? true) as bool,
    batteryHealthy: (json['batteryHealthy'] ?? json['battery_healthy'] ?? true) as bool,
    biometricsWorking: (json['biometricsWorking'] ?? json['biometrics_working'] ?? true) as bool,
    speakerWorking: (json['speakerWorking'] ?? json['speaker_working'] ?? true) as bool,
    hasCharger: (json['hasCharger'] ?? json['has_charger'] ?? true) as bool,
    hasBox: (json['hasBox'] ?? json['has_box'] ?? true) as bool,
    hasBill: (json['hasBill'] ?? json['has_bill'] ?? true) as bool,
    customerName: (json['customerName'] ?? json['customer_name'] ?? 'Customer') as String,
    customerPhone: (json['customerPhone'] ?? json['customer_phone'] ?? '') as String,
    storeId: (json['storeId'] ?? json['store_id'] ?? 'EF-STORE-LKO-01') as String,
    storeName: (json['storeName'] ?? json['store_name'] ?? 'EcoFone Store') as String,
    payoutMethod: (json['payoutMethod'] ?? json['payout_method'] ?? 'In-Store Walk-in (15-Min Instant Payout)') as String,
    status: (json['status'] ?? 'Pending In-Store Inspection') as String,
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
        : (json['created_at'] != null ? (DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()) : DateTime.now()),
  );

  TradeInQuote copyWith({
    String? quoteId,
    String? brand,
    String? modelName,
    String? storage,
    int? estimatedPayout,
    String? screenCondition,
    String? bodyCondition,
    bool? turnsOn,
    bool? cameraWorking,
    bool? batteryHealthy,
    bool? biometricsWorking,
    bool? speakerWorking,
    bool? hasCharger,
    bool? hasBox,
    bool? hasBill,
    String? customerName,
    String? customerPhone,
    String? storeId,
    String? storeName,
    String? payoutMethod,
    String? status,
    DateTime? createdAt,
  }) => TradeInQuote(
    quoteId: quoteId ?? this.quoteId,
    brand: brand ?? this.brand,
    modelName: modelName ?? this.modelName,
    storage: storage ?? this.storage,
    estimatedPayout: estimatedPayout ?? this.estimatedPayout,
    screenCondition: screenCondition ?? this.screenCondition,
    bodyCondition: bodyCondition ?? this.bodyCondition,
    turnsOn: turnsOn ?? this.turnsOn,
    cameraWorking: cameraWorking ?? this.cameraWorking,
    batteryHealthy: batteryHealthy ?? this.batteryHealthy,
    biometricsWorking: biometricsWorking ?? this.biometricsWorking,
    speakerWorking: speakerWorking ?? this.speakerWorking,
    hasCharger: hasCharger ?? this.hasCharger,
    hasBox: hasBox ?? this.hasBox,
    hasBill: hasBill ?? this.hasBill,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    storeId: storeId ?? this.storeId,
    storeName: storeName ?? this.storeName,
    payoutMethod: payoutMethod ?? this.payoutMethod,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
}
