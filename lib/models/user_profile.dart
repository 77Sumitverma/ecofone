class UserProfile {
  final String name;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? city;
  final String? area;
  final String? address;
  final String? pincode;
  final String? token;
  final DateTime? lastLoginAt;
  final bool isNewUser;

  const UserProfile({
    required this.name,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.city,
    this.area,
    this.address,
    this.pincode,
    this.token,
    this.lastLoginAt,
    this.isNewUser = false,
  });

  static bool isPlaceholderName(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'valued customer' ||
        normalized == 'ecocustomer' ||
        normalized == 'customer' ||
        normalized == 'ecofone member';
  }

  static bool isPlaceholderAddress(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return normalized.isEmpty || normalized == 'doorstep delivery';
  }

  bool get hasSavedName => !isPlaceholderName(name);

  String get effectiveSavedAddress {
    if (!isPlaceholderAddress(address)) return address!.trim();
    final trimmedArea = (area ?? '').trim();
    if (!isPlaceholderAddress(trimmedArea)) {
      final trimmedCity = (city ?? '').trim();
      return trimmedCity.isNotEmpty && !trimmedArea.toLowerCase().contains(trimmedCity.toLowerCase())
          ? '$trimmedArea, $trimmedCity'
          : trimmedArea;
    }
    return '';
  }

  bool get hasSavedDeliveryDetails => hasSavedName || effectiveSavedAddress.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'alternatePhone': alternatePhone,
    'alternate_phone': alternatePhone,
    'email': email,
    'city': city,
    'area': area,
    'address': address,
    'pincode': pincode,
    'token': token,
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'isNewUser': isNewUser,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: (json['name'] as String?)?.trim() ?? '',
    phone: json['phone'] as String? ?? '',
    alternatePhone: (json['alternatePhone'] ?? json['alternate_phone']) as String?,
    email: json['email'] as String?,
    city: json['city'] as String?,
    area: json['area'] as String?,
    address: json['address'] as String?,
    pincode: json['pincode'] as String?,
    token: json['token'] as String?,
    lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'] as String) : null,
    isNewUser: json['isNewUser'] == true || json['is_new_user'] == true,
  );

  UserProfile copyWith({
    String? name,
    String? phone,
    String? alternatePhone,
    String? email,
    String? city,
    String? area,
    String? address,
    String? pincode,
    String? token,
    DateTime? lastLoginAt,
    bool? isNewUser,
  }) => UserProfile(
    name: name ?? this.name,
    phone: phone ?? this.phone,
    alternatePhone: alternatePhone ?? this.alternatePhone,
    email: email ?? this.email,
    city: city ?? this.city,
    area: area ?? this.area,
    address: address ?? this.address,
    pincode: pincode ?? this.pincode,
    token: token ?? this.token,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    isNewUser: isNewUser ?? this.isNewUser,
  );
}

class SavedCheckoutDetails {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String pincode;

  const SavedCheckoutDetails({
    required this.name,
    required this.phone,
    required this.address,
    this.city = '',
    this.pincode = '',
  });
}
