import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
export 'package:ecofone/core/widgets/skeleton_loader.dart';

/// Staggered Fade & Slide Entry Animation for smooth reveals on scroll/load
class FadeSlideEntry extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;
  final Offset slideOffset;
  final Curve curve;

  const FadeSlideEntry({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 450,
    this.slideOffset = const Offset(0, 0.08),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideEntry> createState() => _FadeSlideEntryState();
}

class _FadeSlideEntryState extends State<FadeSlideEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delayMs > 0) {
      _delayTimer = Timer(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Tactile Spring Bouncing Button / Card Wrapper with Haptic Feedback
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration duration;

  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 130),
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: const Duration(milliseconds: 190),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onLongPress() {
    if (widget.onLongPress != null) {
      HapticFeedback.mediumImpact();
      _controller.reverse();
      widget.onLongPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress != null ? _onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Heart Pop Explosive Scale Animation with Haptic Feedback & Radial Sparkles
class AnimatedHeartPop extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onToggle;
  final double size;

  const AnimatedHeartPop({
    super.key,
    required this.isLiked,
    required this.onToggle,
    this.size = 20.0,
  });

  @override
  State<AnimatedHeartPop> createState() => _AnimatedHeartPopState();
}

class _AnimatedHeartPopState extends State<AnimatedHeartPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.65), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 0.65, end: 1.38), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.38, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

    _sparkleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isLiked) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    _controller.forward(from: 0.0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size * 1.8,
          height: widget.size * 1.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radial micro-sparkles burst when liked
              AnimatedBuilder(
                animation: _sparkleAnimation,
                builder: (context, _) {
                  if (_controller.value <= 0.1 || _controller.value >= 0.95 || !widget.isLiked) {
                    return const SizedBox.shrink();
                  }
                  final progress = _sparkleAnimation.value;
                  final radius = widget.size * 0.5 + progress * (widget.size * 0.65);
                  final opacity = (1.0 - progress).clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity,
                    child: CustomPaint(
                      size: Size(widget.size * 1.8, widget.size * 1.8),
                      painter: _SparkleBurstPainter(radius: radius),
                    ),
                  );
                },
              ),
              // Main scaling heart icon
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
                child: Icon(
                  widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: widget.isLiked ? const Color(0xFFEF4444) : Colors.black.withOpacity(0.4),
                  size: widget.size,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparkleBurstPainter extends CustomPainter {
  final double radius;
  _SparkleBurstPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    const count = 6;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) - (math.pi / 2);
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      paint.color = (i % 2 == 0) ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
      canvas.drawCircle(Offset(x, y), 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleBurstPainter oldDelegate) => oldDelegate.radius != radius;
}

/// Periodic Luxury Glint/Sheen that sweeps across high-value buttons and badges
class LuxuryShimmerSweep extends StatefulWidget {
  final Widget child;
  final Duration interval;
  final Duration duration;
  final Color shimmerColor;
  final bool enabled;

  const LuxuryShimmerSweep({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 4),
    this.duration = const Duration(milliseconds: 1400),
    this.shimmerColor = Colors.white,
    this.enabled = true,
  });

  @override
  State<LuxuryShimmerSweep> createState() => _LuxuryShimmerSweepState();
}

class _LuxuryShimmerSweepState extends State<LuxuryShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;
  Timer? _intervalTimer;

  bool get _isInTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.enabled && !_isInTest) {
      _startLoop();
    }
  }

  void _startLoop() {
    _delayTimer?.cancel();
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(widget.interval + widget.duration, (_) {
      if (mounted && widget.enabled) {
        _controller.forward(from: 0.0);
      }
    });
    // First trigger after 1.2s delay
    _delayTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && widget.enabled) _controller.forward(from: 0.0);
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _intervalTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          if (progress == 0.0 || progress == 1.0) {
            return child!;
          }
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final width = bounds.width;
              final offset = (progress * 2.4 - 0.7) * width;
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  widget.shimmerColor.withOpacity(0.25),
                  widget.shimmerColor.withOpacity(0.65),
                  widget.shimmerColor.withOpacity(0.25),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                transform: _SlidingGradientTransform(offset / (width == 0 ? 1 : width)),
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double percentOffset;
  const _SlidingGradientTransform(this.percentOffset);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percentOffset, 0.0, 0.0);
  }
}

/// Pulsing Radar / Glow Badge Animation
class PulsingBadge extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxScale;

  const PulsingBadge({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF3C8A5C),
    this.maxScale = 1.06,
  });

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Smooth Animated Number Counter for Trade-in & Prices
class AnimatedPriceCounter extends StatelessWidget {
  final int targetPrice;
  final TextStyle textStyle;
  final Duration duration;

  const AnimatedPriceCounter({
    super.key,
    required this.targetPrice,
    required this.textStyle,
    this.duration = const Duration(milliseconds: 600),
  });

  String _formatNumber(int price) {
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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: (targetPrice * 0.7).toDouble(), end: targetPrice.toDouble()),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Text(
            _formatNumber(value.round()),
            style: textStyle,
          );
        },
      ),
    );
  }
}

/// Ultra-smooth, rounded Circular Loader with glowing ring (Prevents square/boxy glitches)
class EcoCircularProgressLoader extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const EcoCircularProgressLoader({
    super.key,
    this.size = 20.0,
    this.color = const Color(0xFFEA580C),
    this.strokeWidth = 2.4,
  });

  @override
  State<EcoCircularProgressLoader> createState() => _EcoCircularProgressLoaderState();
}

class _EcoCircularProgressLoaderState extends State<EcoCircularProgressLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: RotationTransition(
            turns: _controller,
            child: CircularProgressIndicator(
              strokeWidth: widget.strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
      ),
    );
  }
}

/// Luxury Pulsing GPS / Directions Radar Pin Indicator
class PulsingRadarPin extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color pulseColor;
  final IconData icon;

  const PulsingRadarPin({
    super.key,
    this.size = 38.0,
    this.primaryColor = const Color(0xFF13583C),
    this.pulseColor = const Color(0xFFEA580C),
    this.icon = Icons.my_location_rounded,
  });

  @override
  State<PulsingRadarPin> createState() => _PulsingRadarPinState();
}

class _PulsingRadarPinState extends State<PulsingRadarPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * 1.6,
        height: widget.size * 1.6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.pulseColor.withOpacity(_opacityAnimation.value),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: widget.size * 0.52),
            ),
          ],
        ),
      ),
    );
  }
}
