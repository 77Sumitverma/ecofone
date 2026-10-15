import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/widgets/smartphone_preview_widget.dart';
import 'package:ecofone/screens/phone_detail_screen.dart';
import 'package:ecofone/state/app_state.dart';

/// Quick Peek / Preview Modal Dialog that pops up on Long-Press
/// Allows customers to view device photo, highlights, warranty, specs,
/// and take quick buy/wishlist actions without navigating to a new screen.
class PhoneQuickPeekDialog extends StatefulWidget {
  final PhoneStockItem phone;
  final List<PhoneStockItem>? allPhones;

  const PhoneQuickPeekDialog({
    super.key,
    required this.phone,
    this.allPhones,
  });

  /// Displays the Quick Peek modal dialog with spring pop-in physics & haptics
  static Future<void> show(
    BuildContext context,
    PhoneStockItem phone, {
    List<PhoneStockItem>? allPhones,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PhoneQuickPeek',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) => PhoneQuickPeekDialog(
        phone: phone,
        allPhones: allPhones,
      ),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curvedVal = Curves.easeOutBack.transform(anim.value);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: anim.value * 8.0,
            sigmaY: anim.value * 8.0,
          ),
          child: Transform.scale(
            scale: 0.8 + (0.2 * curvedVal),
            child: Opacity(
              opacity: anim.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<PhoneQuickPeekDialog> createState() => _PhoneQuickPeekDialogState();
}

class _PhoneQuickPeekDialogState extends State<PhoneQuickPeekDialog> {
  static const Color _forestGreen = Color(0xFF13583C);
  static const Color _copper = Color(0xFFEA580C);

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

  List<String> _getResolvedHighlights(PhoneStockItem phone) {
    if (phone.highlights.isNotEmpty) {
      return phone.highlights;
    }
    // Dynamic default highlights by brand if not explicitly provided
    final brand = phone.brand.toLowerCase();
    if (brand.contains('apple')) {
      return [
        'Super Retina XDR OLED Display',
        'Bionic High-Performance Chip',
        'Advanced Dual/Pro Camera System',
        'Ceramic Shield Front Glass',
        'All-Day Battery & MagSafe Fast Charging',
      ];
    } else if (brand.contains('samsung')) {
      return [
        'Dynamic AMOLED 2X 120Hz Display',
        'Snapdragon Flagship Multi-Core SoC',
        'Pro-Grade High-Resolution Nightography',
        'Armor Aluminum Chassis & Gorilla Glass',
        'Super Fast 45W Charging & Wireless PowerShare',
      ];
    } else if (brand.contains('oneplus')) {
      return [
        '120Hz Fluid AMOLED Display',
        'SuperVOOC Ultra Fast Charging',
        'Hasselblad Color Calibration Optics',
        'OxygenOS Clean & Smooth UI',
      ];
    }
    return [
      'High-Refresh Rate HDR Display',
      'High-Capacity All-Day Battery',
      'Multi-Lens AI Camera Setup',
      'Fast Charging & Turbo Power Support',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.phone;
    final highlights = _getResolvedHighlights(phone);
    final isWishlisted = AppState.instance.wishlistedIds.contains(phone.id);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.90,
          constraints: const BoxConstraints(maxWidth: 390, maxHeight: 680),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: EcoColors.mintGreen.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: _forestGreen.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header Bar: Quick Peek Tag + Close Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _forestGreen.withOpacity(0.08),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: _forestGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 12, color: EcoColors.brightAmber),
                            SizedBox(width: 3),
                            Text(
                              'QUICK PEEK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: EcoColors.mintLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: EcoColors.mintBorder),
                          ),
                          child: Text(
                            phone.conditionGrade,
                            style: const TextStyle(
                              color: EcoColors.mintGreen,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Close button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Scrollable Body: Phone visual, pricing & highlighted features
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phone Image & Main Info Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Device Showcase Thumbnail
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.06),
                                ),
                              ),
                              child: MiniPhoneThumbnail(
                                brand: phone.brand,
                                colorName: phone.color,
                                batteryHealth: phone.batteryHealth,
                                realImageUrl: phone.imageUrl,
                                width: 76,
                                height: 124,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Phone Title, Variants & Price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    phone.name,
                                    style: const TextStyle(
                                      color: _forestGreen,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${phone.storage} • ${phone.color}',
                                    style: TextStyle(
                                      color: _forestGreen.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Battery Health Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: EcoColors.mintGreen.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.battery_charging_full_rounded, size: 13, color: EcoColors.mintGreen),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${phone.batteryHealth}% Battery Health',
                                          style: const TextStyle(
                                            color: EcoColors.mintGreen,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Price Breakdown
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        _formatPrice(phone.refurbishedPrice),
                                        style: const TextStyle(
                                          color: _copper,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (phone.originalPrice > phone.refurbishedPrice)
                                        Text(
                                          _formatPrice(phone.originalPrice),
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (phone.savingsPercent > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Save ${_formatPrice(phone.savingsAmount)} (${phone.savingsPercent}% OFF)',
                                      style: const TextStyle(
                                        color: EcoColors.mintGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 12),

                        // 3. Highlighted Features Section (Customer Requirement)
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 15, color: _copper),
                            SizedBox(width: 6),
                            Text(
                              'Key Highlighted Features',
                              style: TextStyle(
                                color: _forestGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Highlight points list
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: highlights.map((highlight) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 3.5, right: 8),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: EcoColors.mintGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      highlight,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 11.5,
                                        height: 1.3,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),

                        // Diagnostic Trust Strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 16, color: EcoColors.mintGreen),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '32-Point Quality Passed • 6-Month Warranty • 7-Day Replacement',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),

                // 4. Bottom Action Dock: Buy Now + Wishlist + 360 Studio
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Buy Now Primary CTA
                      LuxuryShimmerSweep(
                        interval: const Duration(seconds: 3),
                        child: BouncingWidget(
                          scaleFactor: 0.96,
                          onTap: () {
                            Navigator.pop(context);
                            PhoneDetailSheet.show(
                              context,
                              phone,
                              allPhones: widget.allPhones,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_forestGreen, Color(0xFF0F442F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _forestGreen.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bolt_rounded, size: 18, color: EcoColors.brightAmber),
                                const SizedBox(width: 6),
                                Text(
                                  'Buy Now • ${_formatPrice(phone.refurbishedPrice)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Secondary Action Buttons (Wishlist + 360 Showroom)
                      Row(
                        children: [
                          // Wishlist Button
                          Expanded(
                            child: BouncingWidget(
                              scaleFactor: 0.95,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                AppState.instance.toggleWishlist(phone.id);
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isWishlisted
                                      ? const Color(0xFFFEE2E2)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isWishlisted
                                        ? const Color(0xFFFCA5A5)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 14,
                                      color: isWishlisted ? Colors.red : _forestGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        isWishlisted ? 'Wishlisted' : 'Save',
                                        style: TextStyle(
                                          color: isWishlisted ? Colors.red : _forestGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Full 360° Studio Button
                          Expanded(
                            child: BouncingWidget(
                              scaleFactor: 0.95,
                              onTap: () {
                                Navigator.pop(context);
                                PhoneDetailSheet.show(
                                  context,
                                  phone,
                                  allPhones: widget.allPhones,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: _copper.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _copper.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.threed_rotation_rounded, size: 14, color: _copper),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '360° Studio',
                                        style: TextStyle(
                                          color: _copper,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
}
