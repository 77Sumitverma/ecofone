import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/widgets/phone_3d_pop_showcase.dart';
import 'package:ecofone/core/widgets/smartphone_preview_widget.dart';
import 'package:ecofone/screens/phone_detail_screen.dart';
import 'package:ecofone/state/app_state.dart';

/// 3D Flip Phone Stock Card with Hardware-Accelerated Perspective
/// Allows customers to flip the card directly inside the grid to reveal
/// important bullet-point features on the back without opening any modals.
class FlipPhoneStockCard extends StatefulWidget {
  final PhoneStockItem item;
  final List<PhoneStockItem>? allPhones;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  const FlipPhoneStockCard({
    super.key,
    required this.item,
    required this.isWishlisted,
    required this.onWishlistToggle,
    this.allPhones,
  });

  @override
  State<FlipPhoneStockCard> createState() => _FlipPhoneStockCardState();
}

class _FlipPhoneStockCardState extends State<FlipPhoneStockCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  bool _isFlipped = false;

  static const Color _forestGreen = Color(0xFF13583C);
  static const Color _copper = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.mediumImpact();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
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

  List<_CardFeatureBullet> _getResolvedBullets(PhoneStockItem phone) {
    final brand = phone.brand.toLowerCase();
    final name = phone.name.toLowerCase();

    String cam = '48MP Pro Triple Camera';
    String chip = 'A16 Bionic 4nm SoC';
    String screen = '120Hz Super Retina OLED';

    if (brand.contains('samsung') || name.contains('galaxy')) {
      cam = '200MP Space Zoom Cam';
      chip = 'Snapdragon 8 Gen 2';
      screen = 'Dynamic AMOLED 2X';
    } else if (brand.contains('oneplus')) {
      cam = '50MP Sony IMX890';
      chip = 'Snapdragon Flagship';
      screen = '120Hz Fluid AMOLED';
    } else if (brand.contains('pixel') || brand.contains('google')) {
      cam = '50MP Computational AI';
      chip = 'Google Tensor SoC';
      screen = 'Actua OLED 120Hz';
    }

    if (phone.highlights.isNotEmpty) {
      cam = phone.highlights[0];
      if (phone.highlights.length > 1) chip = phone.highlights[1];
      if (phone.highlights.length > 2) screen = phone.highlights[2];
    }

    return [
      _CardFeatureBullet(Icons.camera_alt_rounded, cam, const Color(0xFF38BDF8)),
      _CardFeatureBullet(Icons.speed_rounded, chip, const Color(0xFFF59E0B)),
      _CardFeatureBullet(Icons.smartphone_rounded, screen, const Color(0xFFA855F7)),
      _CardFeatureBullet(Icons.battery_charging_full_rounded, '${phone.batteryHealth}% OEM Battery Health', const Color(0xFF10B981)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        final isUnder = angle > (math.pi / 2);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // 3D perspective depth
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isUnder
              ? Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildBackCard(context),
                )
              : _buildFrontCard(context),
        );
      },
    );
  }

  // --- Front Face of Card ---
  Widget _buildFrontCard(BuildContext context) {
    final item = widget.item;

    return BouncingWidget(
      scaleFactor: 0.96,
      onTap: () {
        PhoneDetailSheet.show(
          context,
          item,
          allPhones: widget.allPhones,
        );
      },
      onLongPress: () {
        Phone3DPopShowcase.show(
          context,
          item,
          allPhones: widget.allPhones,
          isWishlisted: widget.isWishlisted,
          onWishlistToggle: widget.onWishlistToggle,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Condition Tag + 3D Flip Quick Specs Icon + Wishlist Heart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: PulsingBadge(
                      maxScale: 1.05,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: EcoColors.mintLight,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: EcoColors.mintBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 10, color: EcoColors.mintGreen),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                item.conditionGrade.split(' ').first,
                                style: const TextStyle(
                                  color: EcoColors.mintGreen,
                                  fontSize: 9,
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
                  const SizedBox(width: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 3D Flip Quick Specs Toggle Button
                      GestureDetector(
                        onTap: _toggleFlip,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: EcoColors.forestGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: EcoColors.forestGreen.withOpacity(0.2), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flip_rounded, size: 10, color: EcoColors.forestGreen),
                              SizedBox(width: 2),
                              Text(
                                'Specs',
                                style: TextStyle(
                                  color: EcoColors.forestGreen,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Heart Wishlist
                      AnimatedHeartPop(
                        isLiked: widget.isWishlisted,
                        size: 17,
                        onToggle: widget.onWishlistToggle,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Phone Thumbnail Showcase
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _forestGreen.withOpacity(0.035),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: MiniPhoneThumbnail(
                      brand: item.brand,
                      colorName: item.color,
                      batteryHealth: item.batteryHealth,
                      realImageUrl: item.imageUrl,
                      width: 88,
                      height: 126,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Phone Name
              Text(
                item.name,
                style: const TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),

              // Specs Subtitle
              Text(
                '${item.storage} • ${item.color}',
                style: TextStyle(
                  color: _forestGreen.withOpacity(0.6),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Price & Discount Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatPrice(item.refurbishedPrice),
                    style: const TextStyle(
                      color: _copper,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _formatPrice(item.originalPrice),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: EcoColors.softOrange,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${item.savingsPercent}%',
                      style: const TextStyle(
                        color: EcoColors.vibrantOrange,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Live Store Tag
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 11, color: EcoColors.forestGreen),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${AppState.instance.selectedStore.city} Hub (${AppState.instance.getLiveDistanceFrom(AppState.instance.selectedStore)} km)',
                      style: TextStyle(
                        color: _forestGreen.withOpacity(0.75),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Buy Now CTA Button
              LuxuryShimmerSweep(
                interval: const Duration(seconds: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_forestGreen, Color(0xFF164730)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _forestGreen.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_rounded, size: 13, color: EcoColors.brightAmber),
                      SizedBox(width: 4),
                      Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Back Face of Card (Key Feature Points Revealed on 3D Flip) ---
  Widget _buildBackCard(BuildContext context) {
    final item = widget.item;
    final bullets = _getResolvedBullets(item);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF062E1E), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EcoColors.mintGreen.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: EcoColors.mintGreen.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Flip Back Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'KEY HIGHLIGHTS',
                      style: TextStyle(
                        color: EcoColors.mintGreen.withOpacity(0.9),
                        fontWeight: FontWeight.w900,
                        fontSize: 8.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Flip Back Button
              GestureDetector(
                onTap: _toggleFlip,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flip_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 0.8, color: Colors.white24),
          const SizedBox(height: 6),

          // 4 Important Feature Bullet Points
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bullets.map((bullet) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bullet.color.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(bullet.icon, size: 11, color: bullet.color),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        bullet.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Diagnostic Trust Tag
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 10, color: EcoColors.mintGreen),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '32-Pt Diagnostic OK • 6-Mo Warranty',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8.2,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Bottom Action: Buy Now
          BouncingWidget(
            scaleFactor: 0.95,
            onTap: () {
              PhoneDetailSheet.show(
                context,
                item,
                allPhones: widget.allPhones,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_forestGreen, Color(0xFF164730)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _forestGreen.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, size: 13, color: EcoColors.brightAmber),
                  const SizedBox(width: 3),
                  Text(
                    'Buy • ${_formatPrice(item.refurbishedPrice)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFeatureBullet {
  final IconData icon;
  final String text;
  final Color color;

  const _CardFeatureBullet(this.icon, this.text, this.color);
}
