import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/smartphone_preview_widget.dart';
import 'package:ecofone/screens/phone_detail_screen.dart';
import 'package:ecofone/screens/trade_in_screen.dart';
import 'package:ecofone/state/app_state.dart';

/// Instagram / iOS Style Haptic Long-Press Peek & Pop Menu with Full Screen Blur
class PhoneContextPeekPop extends StatefulWidget {
  final PhoneStockItem phone;
  final List<PhoneStockItem>? allPhones;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  const PhoneContextPeekPop({
    super.key,
    required this.phone,
    this.allPhones,
    this.isWishlisted = false,
    this.onWishlistToggle,
  });

  /// Static helper to trigger the long-press peek & pop dialog with tactile haptic
  static Future<void> show(
    BuildContext context,
    PhoneStockItem phone, {
    List<PhoneStockItem>? allPhones,
    bool isWishlisted = false,
    VoidCallback? onWishlistToggle,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PhonePeekBarrier',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return PhoneContextPeekPop(
          phone: phone,
          allPhones: allPhones,
          isWishlisted: isWishlisted,
          onWishlistToggle: onWishlistToggle,
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16 * anim.value,
            sigmaY: 16 * anim.value,
          ),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<PhoneContextPeekPop> createState() => _PhoneContextPeekPopState();
}

class _PhoneContextPeekPopState extends State<PhoneContextPeekPop>
    with SingleTickerProviderStateMixin {
  late bool _isWishlisted;

  static const Color _forestGreen = EcoColors.forestGreen;
  static const Color _copper = EcoColors.vibrantOrange;

  @override
  void initState() {
    super.initState();
    _isWishlisted = widget.isWishlisted;
  }

  String _formatPrice(int price) {
    final str = price.toString();
    if (str.length <= 3) return '₹$str';
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (match) => ',',
    );
    return '₹$formattedRest,$lastThree';
  }

  List<String> _resolveHighlights() {
    final p = widget.phone;
    if (p.highlights.isNotEmpty) return p.highlights;

    final name = p.name.toLowerCase();
    if (name.contains('iphone')) {
      return ['A16 Bionic 4nm', '48MP Pro Camera', '120Hz Super Retina', '${p.batteryHealth}% Battery Health'];
    } else if (name.contains('galaxy') || name.contains('samsung')) {
      return ['Snapdragon 8 Gen 2', '200MP Quad Zoom', 'Dynamic AMOLED 2X', 'S-Pen Included'];
    } else if (name.contains('pixel')) {
      return ['Google Tensor G2', '50MP AI Vision', '120Hz Smooth OLED', 'Clean Android 14'];
    }
    return ['Flagship Processor', 'Pro Camera System', 'High Refresh OLED', '${p.batteryHealth}% OEM Battery'];
  }

  void _handleBuyNow() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    PhoneDetailSheet.show(
      context,
      widget.phone,
      allPhones: widget.allPhones,
    );
  }

  void _handleViewDetails() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    PhoneDetailSheet.show(
      context,
      widget.phone,
      allPhones: widget.allPhones,
    );
  }

  void _handleWishlistToggle() {
    HapticFeedback.selectionClick();
    setState(() {
      _isWishlisted = !_isWishlisted;
    });
    if (widget.onWishlistToggle != null) {
      widget.onWishlistToggle!();
    } else {
      AppState.instance.toggleWishlist(widget.phone.id);
    }
  }

  void _handleTradeInExchange() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TradeInScreen()),
    );
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deal link for ${widget.phone.name} copied to clipboard!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.phone;
    final highlights = _resolveHighlights();
    final savings = phone.originalPrice > phone.refurbishedPrice
        ? phone.originalPrice - phone.refurbishedPrice
        : 0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. POPPED FLOATING PREVIEW CARD
                GestureDetector(
                  onTap: _handleViewDetails,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 28,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Top Header Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _forestGreen.withOpacity(0.04),
                            border: Border(
                              bottom: BorderSide(color: Colors.black.withOpacity(0.04)),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _forestGreen.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(phone.icon, size: 14, color: _forestGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            phone.name,
                                            style: const TextStyle(
                                              color: _forestGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.5,
                                              letterSpacing: -0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${phone.storage} • ${phone.color}',
                                            style: TextStyle(
                                              color: _forestGreen.withOpacity(0.6),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Grade Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: EcoColors.mintGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  phone.conditionGrade,
                                  style: const TextStyle(
                                    color: EcoColors.mintGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Phone Image & Visual Showcase
                        Container(
                          width: double.infinity,
                          height: 190,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: const Color(0xFFF8FAFC),
                          child: Center(
                            child: Hero(
                              tag: 'phone_peek_${phone.id}',
                              child: MiniPhoneThumbnail(
                                brand: phone.brand,
                                colorName: phone.color,
                                batteryHealth: phone.batteryHealth,
                                realImageUrl: phone.imageUrl,
                                width: 135,
                                height: 175,
                              ),
                            ),
                          ),
                        ),

                        // Pricing & Savings Row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _formatPrice(phone.refurbishedPrice),
                                    style: const TextStyle(
                                      color: _forestGreen,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (phone.originalPrice > phone.refurbishedPrice)
                                    Text(
                                      _formatPrice(phone.originalPrice),
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12.5,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                              if (savings > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _copper.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Save ${_formatPrice(savings)}',
                                    style: const TextStyle(
                                      color: _copper,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Key Hardware Specs Pills
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: highlights.take(4).map((h) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: _forestGreen.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 10, color: _forestGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      h,
                                      style: const TextStyle(
                                        color: _forestGreen,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 2. INSTAGRAM / IOS STYLE CONTEXT ACTION MENU
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 340),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Action 1: Buy Now
                      _buildMenuItem(
                        icon: Icons.flash_on_rounded,
                        title: 'Buy Now • Instant Checkout',
                        iconColor: const Color(0xFF10B981),
                        textColor: Colors.white,
                        onTap: _handleBuyNow,
                      ),
                      _buildMenuDivider(),

                      // Action 2: View Full Details & 360 Studio
                      _buildMenuItem(
                        icon: Icons.explore_rounded,
                        title: '360° Inspection & Full Specs',
                        iconColor: const Color(0xFF38BDF8),
                        textColor: Colors.white,
                        onTap: _handleViewDetails,
                      ),
                      _buildMenuDivider(),

                      // Action 3: Wishlist Toggle
                      _buildMenuItem(
                        icon: _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        title: _isWishlisted ? 'Remove from Saved Wishlist' : 'Add to Saved Wishlist',
                        iconColor: _isWishlisted ? const Color(0xFFEF4444) : Colors.white70,
                        textColor: Colors.white,
                        onTap: _handleWishlistToggle,
                      ),
                      _buildMenuDivider(),

                      // Action 4: Trade-in / Exchange Value
                      _buildMenuItem(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Exchange Old Phone with this',
                        iconColor: const Color(0xFFF59E0B),
                        textColor: Colors.white,
                        onTap: _handleTradeInExchange,
                      ),
                      _buildMenuDivider(),

                      // Action 5: Share Deal
                      _buildMenuItem(
                        icon: Icons.share_rounded,
                        title: 'Share Phone Deal',
                        iconColor: Colors.white70,
                        textColor: Colors.white70,
                        onTap: _handleShare,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white.withOpacity(0.08),
      highlightColor: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13.5),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.white.withOpacity(0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: Colors.white.withOpacity(0.09),
    );
  }
}
