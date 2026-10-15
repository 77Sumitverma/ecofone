import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/smartphone_preview_widget.dart';
import 'package:ecofone/models/inventory_model.dart';

/// Zero-Box 3D Floating Smartphone Pop-up with Side-by-Side Highlighted Specs
/// Completely removes all rectangular box/card containers.
/// When triggered via long-press:
/// 1. Entire background gets deeply blurred.
/// 2. Isolated transparent smartphone pops up in the center-left with smooth spring animation.
/// 3. Highlighted key specs float elegantly on the right side directly over the blur.
/// 4. Tapping anywhere on the screen immediately dismisses the pop.
class Phone3DPopShowcase extends StatefulWidget {
  final PhoneStockItem phone;
  final List<PhoneStockItem>? allPhones;
  final bool isWishlisted;
  final VoidCallback? onWishlistToggle;

  const Phone3DPopShowcase({
    super.key,
    required this.phone,
    this.allPhones,
    this.isWishlisted = false,
    this.onWishlistToggle,
  });

  /// Static trigger to display the pure floating pop overlay
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
      barrierLabel: 'PhoneFloatingPopBarrier',
      barrierColor: Colors.black.withOpacity(0.68),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return Phone3DPopShowcase(
          phone: phone,
          allPhones: allPhones,
          isWishlisted: isWishlisted,
          onWishlistToggle: onWishlistToggle,
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 18 * anim.value,
            sigmaY: 18 * anim.value,
          ),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<Phone3DPopShowcase> createState() => _Phone3DPopShowcaseState();
}

class _Phone3DPopShowcaseState extends State<Phone3DPopShowcase>
    with TickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _staggerSpecsAnimation;
  late final AnimationController _hoverLoopController;
  late final Animation<double> _hoverOffsetAnimation;

  // Subtle interactive 3D perspective tilt
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOutBack),
    );

    _staggerSpecsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _popController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _hoverLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _hoverOffsetAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _hoverLoopController, curve: Curves.easeInOutSine),
    );

    _popController.forward();
  }

  @override
  void dispose() {
    _popController.dispose();
    _hoverLoopController.dispose();
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

  Color _resolveAuraColor(String brand, String color) {
    final b = brand.toLowerCase();
    final c = color.toLowerCase();
    if (c.contains('purple')) return const Color(0xFFA855F7);
    if (c.contains('red')) return const Color(0xFFEF4444);
    if (c.contains('blue') || c.contains('tide')) return const Color(0xFF38BDF8);
    if (c.contains('gold') || c.contains('hazel')) return const Color(0xFFF59E0B);
    if (b.contains('samsung')) return const Color(0xFF6366F1);
    if (b.contains('oneplus')) return const Color(0xFF10B981);
    return const Color(0xFF10B981);
  }

  List<_FloatingSpecPoint> _getResolvedSpecPoints(PhoneStockItem phone) {
    final brand = phone.brand.toLowerCase();
    final name = phone.name.toLowerCase();

    String cam = '48MP Pro Triple Camera';
    String chip = 'A16 Bionic 4nm SoC';
    String screen = '120Hz Super Retina OLED';

    if (brand.contains('samsung') || name.contains('galaxy')) {
      cam = '200MP Space Zoom Cam';
      chip = 'Snapdragon 8 Gen 2';
      screen = 'Dynamic AMOLED 2X 120Hz';
    } else if (brand.contains('oneplus')) {
      cam = '50MP Sony IMX890 OIS';
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
      _FloatingSpecPoint(Icons.camera_alt_rounded, cam, const Color(0xFF38BDF8)),
      _FloatingSpecPoint(Icons.speed_rounded, chip, const Color(0xFFF59E0B)),
      _FloatingSpecPoint(Icons.smartphone_rounded, screen, const Color(0xFFA855F7)),
      _FloatingSpecPoint(Icons.battery_charging_full_rounded, '${phone.batteryHealth}% Battery Health', const Color(0xFF10B981)),
      _FloatingSpecPoint(Icons.verified_rounded, phone.conditionGrade, EcoColors.mintGreen),
      const _FloatingSpecPoint(Icons.shield_rounded, '12M Warranty Included', Color(0xFF38BDF8)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.phone;
    final auraColor = _resolveAuraColor(phone.brand, phone.color);
    final specPoints = _getResolvedSpecPoints(phone);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Full-Screen Tap-To-Dismiss Area
              Positioned.fill(
                child: Container(color: Colors.transparent),
              ),

              // 2. Pure Floating Pop Content (Zero Box Design)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    // Allow dragging phone for 3D tilt
                    onPanUpdate: (details) {
                      setState(() {
                        _tiltY = (_tiltY + details.delta.dx * 0.006).clamp(-0.25, 0.25);
                        _tiltX = (_tiltX - details.delta.dy * 0.006).clamp(-0.25, 0.25);
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _tiltX = 0.0;
                        _tiltY = 0.0;
                      });
                    },
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_popController, _hoverLoopController]),
                        builder: (context, child) {
                          return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // --- LEFT: POPPING SMARTPHONE (NO BOX, PURE FLOATING PHOTO) ---
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002) // 3D Perspective Depth
                                ..scale(_scaleAnimation.value)
                                ..translate(0.0, _hoverOffsetAnimation.value)
                                ..rotateX(_tiltX)
                                ..rotateY(_tiltY),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Ambient Colored Aura Glow behind phone
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          auraColor.withOpacity(0.55 * _scaleAnimation.value),
                                          auraColor.withOpacity(0.18 * _scaleAnimation.value),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Isolated Smartphone Cutout
                                  Hero(
                                    tag: 'phone_pop_preview_${phone.id}',
                                    child: MiniPhoneThumbnail(
                                      brand: phone.brand,
                                      colorName: phone.color,
                                      batteryHealth: phone.batteryHealth,
                                      realImageUrl: phone.imageUrl,
                                      width: 125,
                                      height: 200,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 18),

                            // --- RIGHT: FLOATING HIGHLIGHTED SPECS (NO BOX, PURE TEXT & ACCENTS) ---
                            Flexible(
                              child: Transform.translate(
                                offset: Offset((1 - _staggerSpecsAnimation.value) * 30, 0),
                                child: Opacity(
                                  opacity: _staggerSpecsAnimation.value.clamp(0.0, 1.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Phone Name
                                      Text(
                                        phone.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.3,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 10,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 2),

                                      // Storage & Color Variant
                                      Text(
                                        '${phone.storage} • ${phone.color}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black45,
                                              blurRadius: 8,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Price Row
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatPrice(phone.refurbishedPrice),
                                            style: const TextStyle(
                                              color: EcoColors.mintGreen,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.2,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 10,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (phone.originalPrice > phone.refurbishedPrice) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '${phone.savingsPercent}% OFF',
                                              style: const TextStyle(
                                                color: EcoColors.vibrantOrange,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      const SizedBox(height: 10),

                                      // Glowing Accent Divider
                                      Container(
                                        width: 140,
                                        height: 1.5,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              auraColor.withOpacity(0.8),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      // Highlighted Spec Points Floating in Space
                                      ...specPoints.map((spec) => Padding(
                                            padding: const EdgeInsets.only(bottom: 7),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Glowing Micro Dot / Icon
                                                Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    color: spec.color.withOpacity(0.18),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: spec.color.withOpacity(0.4),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    spec.icon,
                                                    size: 10,
                                                    color: spec.color,
                                                  ),
                                                ),
                                                const SizedBox(width: 7),
                                                Flexible(
                                                  child: Text(
                                                    spec.text,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black87,
                                                          blurRadius: 8,
                                                          offset: Offset(0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),

                                      const SizedBox(height: 8),

                                      // Tap anywhere hint
                                      Text(
                                        'Tap anywhere to close',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.45),
                                          fontSize: 9.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
}

class _FloatingSpecPoint {
  final IconData icon;
  final String text;
  final Color color;

  const _FloatingSpecPoint(this.icon, this.text, this.color);
}
