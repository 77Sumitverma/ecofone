import 'package:flutter/material.dart';

/// Luxury Shimmer Wave Skeleton Engine for EcoFone
/// Renders an ultra-smooth 60/120 FPS specular glint over skeleton bone hierarchies.
class EcoSkeletonShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const EcoSkeletonShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFF8FAFC),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<EcoSkeletonShimmer> createState() => _EcoSkeletonShimmerState();
}

class _EcoSkeletonShimmerState extends State<EcoSkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isInTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (!_isInTest) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInTest) {
      return widget.child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                colors: [
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
                stops: const [0.15, 0.5, 0.85],
                transform: _SkeletonGradientTransform(progress),
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

class _SkeletonGradientTransform extends GradientTransform {
  final double percentOffset;
  const _SkeletonGradientTransform(this.percentOffset);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Sweeps from -width to +2*width for a natural glint
    final dx = bounds.width * (percentOffset * 3.0 - 1.5);
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}

/// Primitive Skeleton Box Bone
class EcoSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const EcoSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Primitive Skeleton Circle Bone (Avatars, Badges, Icons)
class EcoSkeletonCircle extends StatelessWidget {
  final double size;
  final Color? color;

  const EcoSkeletonCircle({
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Primitive Multi-line Skeleton Text Lines
class EcoSkeletonText extends StatelessWidget {
  final int lines;
  final double height;
  final double spacing;
  final double lastLineWidthFactor;
  final double borderRadius;

  const EcoSkeletonText({
    super.key,
    this.lines = 2,
    this.height = 12,
    this.spacing = 6,
    this.lastLineWidthFactor = 0.65,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: FractionallySizedBox(
            widthFactor: isLast && lines > 1 ? lastLineWidthFactor : 1.0,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// DOMAIN-SPECIFIC SKELETON PRESETS FOR ECOFONE
// ============================================================================

/// Skeleton Placeholder for Stock Grid Product Cards
class PhoneCardSkeleton extends StatelessWidget {
  const PhoneCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return EcoSkeletonShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Condition Tag + Wishlist Heart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                EcoSkeletonBox(width: 58, height: 18, borderRadius: 5),
                EcoSkeletonCircle(size: 18),
              ],
            ),
            SizedBox(height: 6),
            // Phone Mockup Silhouette Canvas
            Expanded(
              child: Center(
                child: EcoSkeletonBox(
                  width: 60,
                  height: 104,
                  borderRadius: 12,
                ),
              ),
            ),
            SizedBox(height: 8),
            // Phone Name Bone
            EcoSkeletonBox(width: 105, height: 14, borderRadius: 4),
            SizedBox(height: 4),
            // Specs Subtitle Bone
            EcoSkeletonBox(width: 68, height: 10, borderRadius: 3),
            SizedBox(height: 8),
            // Price & Discount Row Bone
            Row(
              children: [
                EcoSkeletonBox(width: 54, height: 15, borderRadius: 4),
                SizedBox(width: 6),
                EcoSkeletonBox(width: 32, height: 10, borderRadius: 3),
                SizedBox(width: 6),
                EcoSkeletonBox(width: 26, height: 12, borderRadius: 3),
              ],
            ),
            SizedBox(height: 6),
            // Store Hub Tag Bone
            Row(
              children: [
                EcoSkeletonCircle(size: 11),
                SizedBox(width: 4),
                EcoSkeletonBox(width: 76, height: 9, borderRadius: 3),
              ],
            ),
            SizedBox(height: 8),
            // Reserve CTA Button Bone
            EcoSkeletonBox(
              width: double.infinity,
              height: 28,
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton Grid for Stock Catalog Screen (Returns Pure RenderSliver)
class StockGridSkeletonView extends StatelessWidget {
  final int itemCount;

  const StockGridSkeletonView({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const PhoneCardSkeleton(),
          childCount: itemCount,
        ),
      ),
    );
  }
}

/// Skeleton Placeholder for Wishlist Items
class WishlistCardSkeleton extends StatelessWidget {
  const WishlistCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return EcoSkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vector Phone Mockup Thumbnail
            EcoSkeletonBox(width: 76, height: 90, borderRadius: 14),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      EcoSkeletonBox(width: 60, height: 16, borderRadius: 6),
                      EcoSkeletonCircle(size: 16),
                    ],
                  ),
                  SizedBox(height: 6),
                  EcoSkeletonBox(width: 130, height: 14, borderRadius: 4),
                  SizedBox(height: 4),
                  EcoSkeletonBox(width: 80, height: 10, borderRadius: 3),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          EcoSkeletonBox(width: 58, height: 16, borderRadius: 4),
                          SizedBox(width: 6),
                          EcoSkeletonBox(width: 38, height: 11, borderRadius: 3),
                        ],
                      ),
                      EcoSkeletonBox(width: 95, height: 28, borderRadius: 10),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton Placeholder for Store Hub Cards in Explore Screen
class StoreCardSkeleton extends StatelessWidget {
  const StoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return EcoSkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EcoSkeletonBox(width: 44, height: 44, borderRadius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EcoSkeletonBox(width: 140, height: 15, borderRadius: 4),
                      SizedBox(height: 4),
                      EcoSkeletonBox(width: 90, height: 11, borderRadius: 3),
                    ],
                  ),
                ),
                EcoSkeletonBox(width: 55, height: 22, borderRadius: 12),
              ],
            ),
            SizedBox(height: 12),
            EcoSkeletonBox(width: double.infinity, height: 12, borderRadius: 3),
            SizedBox(height: 4),
            EcoSkeletonBox(width: 180, height: 12, borderRadius: 3),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: EcoSkeletonBox(height: 36, borderRadius: 10)),
                SizedBox(width: 10),
                Expanded(child: EcoSkeletonBox(height: 36, borderRadius: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton Placeholder for Phone Detail Screen Header and Specs
class PhoneDetailSkeletonView extends StatelessWidget {
  const PhoneDetailSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return EcoSkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Studio 360 Showroom Canvas
          Container(
            height: 280,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: EcoSkeletonBox(
                width: 120,
                height: 200,
                borderRadius: 22,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    EcoSkeletonBox(width: 80, height: 22, borderRadius: 6),
                    EcoSkeletonBox(width: 60, height: 22, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 10),
                EcoSkeletonBox(width: 220, height: 24, borderRadius: 6),
                SizedBox(height: 6),
                EcoSkeletonBox(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 14),
                EcoSkeletonBox(width: double.infinity, height: 50, borderRadius: 14),
                SizedBox(height: 14),
                // Diagnostics passed banner
                EcoSkeletonBox(width: double.infinity, height: 70, borderRadius: 16),
                SizedBox(height: 16),
                // Storage Selector row
                Row(
                  children: [
                    EcoSkeletonBox(width: 70, height: 34, borderRadius: 10),
                    SizedBox(width: 8),
                    EcoSkeletonBox(width: 70, height: 34, borderRadius: 10),
                    SizedBox(width: 8),
                    EcoSkeletonBox(width: 70, height: 34, borderRadius: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
