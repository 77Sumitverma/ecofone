import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/widgets/smartphone_preview_widget.dart';
import 'package:ecofone/screens/phone_detail_screen.dart';
import 'package:ecofone/state/app_state.dart';

/// Cinematic Hero Feature Reveal Modal
/// When a customer taps/long-presses a phone:
/// 1. The rest of the page blurs deeply.
/// 2. The phone visually zooms & grows into the center with physics bounce.
/// 3. Important feature callouts emerge from behind the phone in glowing points.
class PhoneHeroFeatureReveal extends StatefulWidget {
  final PhoneStockItem phone;
  final List<PhoneStockItem>? allPhones;

  const PhoneHeroFeatureReveal({
    super.key,
    required this.phone,
    this.allPhones,
  });

  /// Displays the cinematic hero zoom & feature reveal overlay
  static Future<void> show(
    BuildContext context,
    PhoneStockItem phone, {
    List<PhoneStockItem>? allPhones,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PhoneHeroReveal',
      barrierColor: Colors.black.withOpacity(0.78),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => PhoneHeroFeatureReveal(
        phone: phone,
        allPhones: allPhones,
      ),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: anim.value * 18.0,
            sigmaY: anim.value * 18.0,
          ),
          child: child,
        );
      },
    );
  }

  @override
  State<PhoneHeroFeatureReveal> createState() => _PhoneHeroFeatureRevealState();
}

class _PhoneHeroFeatureRevealState extends State<PhoneHeroFeatureReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _phoneScale;
  late final Animation<double> _phoneOpacity;
  late final Animation<double> _point1Anim;
  late final Animation<double> _point2Anim;
  late final Animation<double> _point3Anim;
  late final Animation<double> _point4Anim;
  late final Animation<double> _dockAnim;

  static const Color _forestGreen = Color(0xFF13583C);
  static const Color _copper = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 1. Phone scales up from small to big hero size
    _phoneScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutBack),
      ),
    );

    _phoneOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // 2. Staggered feature callouts emerge from behind the phone
    _point1Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _point2Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _point3Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _point4Anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.00, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Bottom dock slides up
    _dockAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.00, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  List<_FeaturePoint> _resolveKeyFeatures(PhoneStockItem phone) {
    final brand = phone.brand.toLowerCase();
    final name = phone.name.toLowerCase();

    String cameraText = '48MP Pro Triple Camera';
    String cameraSub = '4K HDR & Night Mode';
    String chipText = 'A16 Bionic 4nm Chip';
    String chipSub = 'Flagship Performance';
    String displayText = '120Hz ProMotion OLED';
    String displaySub = 'Super Retina XDR';

    if (brand.contains('samsung') || name.contains('galaxy') || name.contains('s23')) {
      cameraText = '200MP Space Zoom Cam';
      cameraSub = 'Nightography & 8K Video';
      chipText = 'Snapdragon 8 Gen 2';
      chipSub = 'Ray-Tracing Graphics';
      displayText = 'Dynamic AMOLED 2X';
      displaySub = '120Hz Adaptive 1750 nits';
    } else if (brand.contains('oneplus')) {
      cameraText = '50MP Sony IMX890';
      cameraSub = 'Hasselblad Color Calibration';
      chipText = 'Snapdragon Flagship SoC';
      chipSub = 'OxygenOS Fast & Smooth';
      displayText = '120Hz Fluid AMOLED';
      displaySub = 'HDR10+ 10-Bit Color';
    } else if (brand.contains('google') || name.contains('pixel')) {
      cameraText = '50MP Computational AI';
      cameraSub = 'Real Tone & Magic Eraser';
      chipText = 'Google Tensor G2/G3';
      chipSub = 'Titan M2 Security';
      displayText = 'Smooth Actua OLED';
      displaySub = '120Hz Ultra Bright';
    }

    // If custom highlights are present, map them to callout points
    if (phone.highlights.isNotEmpty) {
      cameraText = phone.highlights[0];
      if (phone.highlights.length > 1) chipText = phone.highlights[1];
      if (phone.highlights.length > 2) displayText = phone.highlights[2];
    }

    return [
      _FeaturePoint(
        icon: Icons.camera_alt_rounded,
        title: cameraText,
        subtitle: cameraSub,
        color: const Color(0xFF38BDF8), // Cyan blue
      ),
      _FeaturePoint(
        icon: Icons.speed_rounded,
        title: chipText,
        subtitle: chipSub,
        color: const Color(0xFFF59E0B), // Amber gold
      ),
      _FeaturePoint(
        icon: Icons.smartphone_rounded,
        title: displayText,
        subtitle: displaySub,
        color: const Color(0xFFA855F7), // Purple
      ),
      _FeaturePoint(
        icon: Icons.battery_charging_full_rounded,
        title: '${phone.batteryHealth}% Battery Health',
        subtitle: '${phone.conditionGrade.split(' ').first} Certified Grade',
        color: const Color(0xFF10B981), // Mint green
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.phone;
    final features = _resolveKeyFeatures(phone);
    final size = MediaQuery.of(context).size;
    final isWishlisted = AppState.instance.wishlistedIds.contains(phone.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Top Close & Title Bar
              Positioned(
                top: 14,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: EcoColors.brightAmber),
                          SizedBox(width: 6),
                          Text(
                            'KEY HIGHLIGHTS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Central Hero Feature Stage (Phone + Radiating Points)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120, top: 40),
                  child: Center(
                    child: SizedBox(
                      width: size.width * 0.92,
                      height: (size.height * 0.58).clamp(380.0, 520.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ambient Glow Aura
                          AnimatedBuilder(
                            animation: _phoneScale,
                            builder: (context, child) {
                              return Container(
                                width: 220 * _phoneScale.value,
                                height: 320 * _phoneScale.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: EcoColors.mintGreen.withOpacity(0.25 * _phoneScale.value),
                                      blurRadius: 70,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // --- Staggered Feature Callouts emerging from behind ---
                          // Point 1: Top Left
                          _buildEmergedFeaturePill(
                            animation: _point1Anim,
                            feature: features[0],
                            alignment: const Alignment(-0.95, -0.75),
                            slideDirection: const Offset(-0.8, -0.4),
                          ),

                          // Point 2: Top Right
                          _buildEmergedFeaturePill(
                            animation: _point2Anim,
                            feature: features[1],
                            alignment: const Alignment(0.95, -0.35),
                            slideDirection: const Offset(0.8, -0.3),
                          ),

                          // Point 3: Bottom Left
                          _buildEmergedFeaturePill(
                            animation: _point3Anim,
                            feature: features[2],
                            alignment: const Alignment(-0.95, 0.35),
                            slideDirection: const Offset(-0.8, 0.3),
                          ),

                          // Point 4: Bottom Right
                          _buildEmergedFeaturePill(
                            animation: _point4Anim,
                            feature: features[3],
                            alignment: const Alignment(0.95, 0.75),
                            slideDirection: const Offset(0.8, 0.4),
                          ),

                          // --- Central Enlarged Hero Phone ---
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _phoneScale.value,
                                child: Opacity(
                                  opacity: _phoneOpacity.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.55),
                                          blurRadius: 32,
                                          offset: const Offset(0, 16),
                                        ),
                                        BoxShadow(
                                          color: EcoColors.mintGreen.withOpacity(0.18),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: MiniPhoneThumbnail(
                                      brand: phone.brand,
                                      colorName: phone.color,
                                      batteryHealth: phone.batteryHealth,
                                      realImageUrl: phone.imageUrl,
                                      width: 128,
                                      height: 218,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Bottom Compact Control & Direct Purchase Dock
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _dockAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 40 * (1.0 - _dockAnim.value)),
                      child: Opacity(
                        opacity: _dockAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Device Title & Pricing Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    phone.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${phone.storage} • ${phone.color} • 32-Pt Quality Passed',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatPrice(phone.refurbishedPrice),
                                  style: const TextStyle(
                                    color: EcoColors.brightAmber,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                if (phone.savingsPercent > 0)
                                  Text(
                                    '${phone.savingsPercent}% OFF',
                                    style: const TextStyle(
                                      color: EcoColors.mintGreen,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons: Buy Now + 360 Showroom + Wishlist
                        Row(
                          children: [
                            // Buy Now Primary Button
                            Expanded(
                              flex: 3,
                              child: LuxuryShimmerSweep(
                                interval: const Duration(seconds: 3),
                                child: BouncingWidget(
                                  scaleFactor: 0.96,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    PhoneDetailSheet.show(
                                      context,
                                      phone,
                                      allPhones: widget.allPhones,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [_forestGreen, Color(0xFF0F442F)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _forestGreen.withOpacity(0.45),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bolt_rounded, size: 17, color: EcoColors.brightAmber),
                                        SizedBox(width: 5),
                                        Text(
                                          'Buy Now',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Wishlist Toggle
                            BouncingWidget(
                              scaleFactor: 0.95,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                AppState.instance.toggleWishlist(phone.id);
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isWishlisted
                                      ? const Color(0xFFEF4444).withOpacity(0.2)
                                      : Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isWishlisted
                                        ? const Color(0xFFEF4444).withOpacity(0.6)
                                        : Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(
                                  isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 19,
                                  color: isWishlisted ? const Color(0xFFEF4444) : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 360° Showroom Button
                            Expanded(
                              flex: 2,
                              child: BouncingWidget(
                                scaleFactor: 0.95,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  PhoneDetailSheet.show(
                                    context,
                                    phone,
                                    allPhones: widget.allPhones,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.threed_rotation_rounded, size: 15, color: _copper),
                                      SizedBox(width: 4),
                                      Text(
                                        '360° Studio',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single animated feature point emerging from behind the center phone
  Widget _buildEmergedFeaturePill({
    required Animation<double> animation,
    required _FeaturePoint feature,
    required Alignment alignment,
    required Offset slideDirection,
  }) {
    return Align(
      alignment: alignment,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final val = animation.value;
          // Slides outward from center (0,0) to target offset
          final translateX = slideDirection.dx * 35.0 * (1.0 - val);
          final translateY = slideDirection.dy * 35.0 * (1.0 - val);

          return Transform.translate(
            offset: Offset(translateX, translateY),
            child: Transform.scale(
              scale: 0.5 + (0.5 * val),
              child: Opacity(
                opacity: val.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 155),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.88),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: feature.color.withOpacity(0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: feature.color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feature.icon,
                  size: 13,
                  color: feature.color,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      feature.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 8.5,
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
      ),
    );
  }
}

class _FeaturePoint {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeaturePoint({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
