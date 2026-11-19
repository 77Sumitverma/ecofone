import 'package:flutter/material.dart';

/// AppBanner model represents promotional hero banners displayed dynamically
/// on the EcoFone mobile application home screen.
/// Managed centrally from the Super Admin Web Portal.
class AppBanner {
  final int id;
  final String badge;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String gradientStart;
  final String gradientEnd;
  final String actionType;
  final String actionValue;
  final String cta;
  final int displayOrder;
  final bool isActive;

  const AppBanner({
    required this.id,
    required this.badge,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.gradientStart = '#15803D',
    this.gradientEnd = '#0B4D3C',
    this.actionType = 'ROUTE',
    this.actionValue = '/stock',
    this.cta = 'VIEW OFFER',
    this.displayOrder = 1,
    this.isActive = true,
  });

  /// Safely parse Hex color string e.g. "#15803D" or "0xFF15803D"
  static Color _parseHexColor(String hexStr, Color fallback) {
    try {
      String clean = hexStr.replaceAll('#', '').trim();
      if (clean.length == 6) {
        clean = 'FF$clean';
      }
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  List<Color> get gradient {
    return [
      _parseHexColor(gradientStart, const Color(0xFF15803D)),
      _parseHexColor(gradientEnd, const Color(0xFF0B4D3C)),
    ];
  }

  Color get badgeBg {
    return gradient.first.withOpacity(0.85);
  }

  Color get badgeText => Colors.white;

  IconData get icon {
    final lower = '$badge $title'.toLowerCase();
    if (lower.contains('delivery') || lower.contains('pickup')) {
      return Icons.local_shipping_rounded;
    }
    if (lower.contains('bank') || lower.contains('cashback') || lower.contains('emi') || lower.contains('card')) {
      return Icons.credit_card_rounded;
    }
    if (lower.contains('warranty') || lower.contains('guarantee') || lower.contains('certified')) {
      return Icons.verified_user_rounded;
    }
    if (lower.contains('exchange') || lower.contains('bonus') || lower.contains('rupee') || lower.contains('sale')) {
      return Icons.currency_rupee_rounded;
    }
    return Icons.local_offer_rounded;
  }

  factory AppBanner.fromJson(Map<String, dynamic> json) {
    return AppBanner(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      badge: json['badge'] as String? ?? 'MEGA SALE',
      title: json['title'] as String? ?? 'EcoFone Special Offer',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      gradientStart: json['gradient_start'] as String? ?? '#15803D',
      gradientEnd: json['gradient_end'] as String? ?? '#0B4D3C',
      actionType: json['action_type'] as String? ?? 'ROUTE',
      actionValue: json['action_value'] as String? ?? '/stock',
      cta: json['cta'] as String? ?? 'VIEW OFFER',
      displayOrder: json['display_order'] is num ? (json['display_order'] as num).toInt() : 1,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'badge': badge,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'gradient_start': gradientStart,
      'gradient_end': gradientEnd,
      'action_type': actionType,
      'action_value': actionValue,
      'cta': cta,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  /// Default baseline banners if offline or before first network sync
  static const List<AppBanner> defaultBanners = [
    AppBanner(
      id: 1,
      badge: 'MEGA SALE',
      title: 'Upgrade to iPhone 14 Pro',
      subtitle: 'Flat ₹5,000 extra exchange bonus on your old smartphone',
      cta: 'CLAIM OFFER',
      gradientStart: '#0F5132',
      gradientEnd: '#0A3622',
      actionType: 'ROUTE',
      actionValue: '/trade_in',
      displayOrder: 1,
    ),
    AppBanner(
      id: 2,
      badge: 'EXPRESS DELIVERY',
      title: 'Free Doorstep Delivery & 2-Hr Pickup',
      subtitle: 'Fast dispatch, verified 32-point diagnostics & 7-day return guarantee!',
      cta: 'EXPLORE PHONES',
      gradientStart: '#B45309',
      gradientEnd: '#78350F',
      actionType: 'ROUTE',
      actionValue: '/stock',
      displayOrder: 2,
    ),
    AppBanner(
      id: 3,
      badge: 'BANK OFFER',
      title: 'Flat ₹2,500 Instant Cashback',
      subtitle: 'On orders above ₹30,000 via HDFC, ICICI, SBI & UPI',
      cta: 'VIEW DEALS',
      gradientStart: '#0369A1',
      gradientEnd: '#075985',
      actionType: 'ROUTE',
      actionValue: '/stock',
      displayOrder: 3,
    ),
    AppBanner(
      id: 4,
      badge: '6-MONTH WARRANTY',
      title: 'Pan-India Certified Guarantee',
      subtitle: '100% genuine components with free doorstep pickup & repair',
      cta: 'KNOW MORE',
      gradientStart: '#581C87',
      gradientEnd: '#3B0764',
      actionType: 'ROUTE',
      actionValue: '/stock',
      displayOrder: 4,
    ),
  ];
}
