import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/services/storage/local_storage_service.dart';

/// Clean, Minimal & High-Impact White Onboarding Experience for EcoFone
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      category: 'CERTIFIED REFURBISHED',
      titlePart1: 'Flagships.',
      titlePart2: 'Half the Price.',
      subtitle:
          '100% original iPhones & Galaxies tested across 32 rigorous checks. Why pay full price?',
      imageAsset: 'assets/phones/iphone_14_pro.png',
      accentColor: EcoColors.vibrantOrange,
    ),
    _OnboardingSlideData(
      category: 'TOTAL PEACE OF MIND',
      titlePart1: '6 Months Warranty.',
      titlePart2: 'Zero Stress.',
      subtitle:
          'Cashless repairs & 7-day hassle-free replacements. Brand new confidence, guaranteed.',
      imageAsset: 'assets/phones/galaxy_s23_ultra.png',
      accentColor: Color(0xFF059669),
    ),
    _OnboardingSlideData(
      category: '13+ STORES & EXPRESS DELIVERY',
      titlePart1: 'Touch & Feel.',
      titlePart2: 'At 13+ Stores.',
      subtitle:
          'Test devices live at your nearest retail store, sell old phones for cash, or order online.',
      imageAsset: 'assets/phones/iphone_13.png',
      accentColor: EcoColors.vibrantOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    final storage = await LocalStorageService.getInstance();
    await storage.setHasSeenOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Top Header: Brand Logo & Minimal Skip Button
              _buildTopHeader(),

              // Center: Clean PageView with Big Phone & Bold Typography
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _buildSlideContent(slide);
                  },
                ),
              ),

              // Bottom Footer: Minimal Dot Indicators & Vibrant CTA
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Top Header: Crisp EcoFone Logo & Skip Pill ---
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Official EcoFone Brand Horizontal Logo
          Image.asset(
            'assets/logo/ecofone_horizontal_logo.png',
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/logo/logo_transparent.png',
              height: 36,
              fit: BoxFit.contain,
            ),
          ),

          // Clean Skip Button
          BouncingWidget(
            scaleFactor: 0.94,
            onTap: _completeOnboarding,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Slide Content: Single Big Phone + Big Bold Typography ---
  Widget _buildSlideContent(_OnboardingSlideData slide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        final double phoneHeight =
            (availableHeight * 0.44).clamp(170.0, 260.0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),

                    // 1. Hero: Single Large Smartphone with Studio Ground Shadow
                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: SizedBox(
                        height: phoneHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ambient light halo behind phone
                            Container(
                              width: phoneHeight * 0.85,
                              height: phoneHeight * 0.85,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    slide.accentColor.withOpacity(0.09),
                                    slide.accentColor.withOpacity(0.02),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // Soft studio drop shadow under phone
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: phoneHeight * 0.58,
                                height: 14,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.elliptical(150, 14),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // High-Definition Large Phone Photo
                            Image.asset(
                              slide.imageAsset,
                              height: phoneHeight,
                              fit: BoxFit.contain,
                              cacheHeight: 750,
                              filterQuality: FilterQuality.medium,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: slide.accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: slide.accentColor.withOpacity(0.22),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        slide.category,
                        style: TextStyle(
                          color: slide.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Huge Bold Headline (Apple/CRED Style)
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${slide.titlePart1}\n',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.8,
                            ),
                          ),
                          TextSpan(
                            text: slide.titlePart2,
                            style: TextStyle(
                              color: slide.accentColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 4. Punchy, Short Subtitle (No mess or long text)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Bottom Footer: Smooth Dots & Gradient CTA ---
  Widget _buildBottomControls() {
    final isLastSlide = _currentPage == _slides.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clean Pill Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (index) {
              final isSelected = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 5,
                width: isSelected ? 26 : 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? EcoColors.vibrantOrange
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // Big Punchy CTA Button
          BouncingWidget(
            scaleFactor: 0.97,
            onTap: _onNext,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    EcoColors.vibrantOrange,
                    Color(0xFFEA580C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: EcoColors.vibrantOrange.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastSlide ? 'Get Started' : 'Continue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 19,
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

class _OnboardingSlideData {
  final String category;
  final String titlePart1;
  final String titlePart2;
  final String subtitle;
  final String imageAsset;
  final Color accentColor;

  const _OnboardingSlideData({
    required this.category,
    required this.titlePart1,
    required this.titlePart2,
    required this.subtitle,
    required this.imageAsset,
    required this.accentColor,
  });
}
