class UserProfile {
  final String name;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? city;
  final String? area;
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
    this.pincode,
    this.token,
    this.lastLoginAt,
    this.isNewUser = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'alternatePhone': alternatePhone,
    'alternate_phone': alternatePhone,
    'email': email,
    'city': city,
    'area': area,
    'pincode': pincode,
    'token': token,
    'lastLoginAt': lastLoginAt?.toIso8601String(),
    'isNewUser': isNewUser,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'Valued Customer',
    phone: json['phone'] as String? ?? '',
    alternatePhone: (json['alternatePhone'] ?? json['alternate_phone']) as String?,
    email: json['email'] as String?,
    city: json['city'] as String?,
    area: json['area'] as String?,
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
    pincode: pincode ?? this.pincode,
    token: token ?? this.token,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    isNewUser: isNewUser ?? this.isNewUser,
  );
}
