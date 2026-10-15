class UserProfile {
  final String name;
  final String phone;
  final String? email;
  final String? city;
  final String? pincode;
  final String? token;
  final DateTime? lastLoginAt;

  const UserProfile({
    required this.name,
    required this.phone,
    this.email,
    this.city,
    this.pincode,
    this.token,
    this.lastLoginAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'city': city,
    'pincode': pincode,
    'token': token,
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String? ?? 'Valued Customer',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String?,
    city: json['city'] as String?,
    pincode: json['pincode'] as String?,
    token: json['token'] as String?,
    lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'] as String) : null,
  );

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? city,
    String? pincode,
    String? token,
    DateTime? lastLoginAt,
  }) => UserProfile(
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    city: city ?? this.city,
    pincode: pincode ?? this.pincode,
    token: token ?? this.token,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );
}
