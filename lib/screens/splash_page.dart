import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ecofone/models/inventory_model.dart';
import 'package:ecofone/core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // ---- Brand config ---------------------------------------------------
  static const _logoAssetPath = 'assets/logo/ecofone_horizontal_logo.png';
  static const _logoWidthFraction = 0.72; // Official horizontal brand logo banner

  // Colors pulled from the EcoFone logo itself.
  static const _bgTop = EcoColors.darkEmerald; // deep forest emerald green
  static const _bgBottom = Color(0xFF1F0D03); // dark bronze/espresso
  static const _glowColorGreen = EcoColors.forestGreen;
  static const _glowColorCopper = EcoColors.vibrantOrange;
  // ---------------------------------------------------------------------

  static const _entryDuration = Duration(milliseconds: 1100);
  static const _holdDuration = Duration(milliseconds: 1100);
  static const _exitDuration = Duration(milliseconds: 500);






  late final AnimationController _entryController;
  late final AnimationController _glowController;
  late final AnimationController _exitController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowPulse;
  late final Animation<double> _exitOpacity;

  bool _navigated = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final item in PhoneStockItem.sampleInventory) {
        final url = item.imageUrl?.replaceAll('.jpg', '.png');
        if (url != null && url.isNotEmpty) {
          precacheImage(AssetImage(url), context);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: _entryDuration,
    );
    _logoFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    // Slow continuous glow pulse — subtle, not flashy.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: _exitDuration,
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _runSplashSequence();
  }

  Future<void> _runSplashSequence() async {
    await _entryController.forward();
    if (!mounted) return;

    await Future.delayed(_holdDuration);
    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = MediaQuery.sizeOf(context).width * _logoWidthFraction;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) =>
            Opacity(opacity: _exitOpacity.value, child: child),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgTop, _bgBottom],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation:
                  Listenable.merge([_entryController, _glowController]),
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft two-tone glow (green + copper) behind the logo,
                    // pulsing gently and independently of the entry reveal.
                    Opacity(
                      opacity:
                          (_logoFade.value * _glowPulse.value).clamp(0.0, 1.0),
                      child: Container(
                        width: logoWidth * 1.3,
                        height: logoWidth * 0.7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(logoWidth * 0.35),
                          gradient: RadialGradient(
                            colors: [
                              _glowColorCopper.withOpacity(0.28),
                              _glowColorGreen.withOpacity(0.18),
                              _glowColorGreen.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Logo (already includes wordmark + tagline).
                    Opacity(
                      opacity: _logoFade.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    ),
                  ],
                );
              },
              child: Image.asset(
                _logoAssetPath,
                width: logoWidth,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/logo/logo_transparent.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}