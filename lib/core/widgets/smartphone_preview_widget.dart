import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';

/// Available modes for smartphone inspection
enum PhoneViewMode {
  studio360,
  cameraMacro,
  diagnosticsBench,
}

/// Color option with display name, gradient hues, and frame accents
class PhoneColorOption {
  final String name;
  final Color bodyColor;
  final Color frameColor;
  final Color accentColor;
  final bool isDark;

  const PhoneColorOption({
    required this.name,
    required this.bodyColor,
    required this.frameColor,
    required this.accentColor,
    this.isDark = true,
  });

  Color get wallpaperAccent => accentColor;
}

/// Ultra-Luxury Photorealistic Smartphone Preview & 360° Showroom Studio
class SmartphonePreviewWidget extends StatefulWidget {
  final String brand;
  final String modelName;
  final String initialColor;
  final int batteryHealth;
  final String conditionGrade;
  final String? realImageUrl;
  final List<String>? galleryUrls;
  final double height;
  final bool showControls;
  final VoidCallback? on360InspectTap;

  const SmartphonePreviewWidget({
    super.key,
    required this.brand,
    required this.modelName,
    required this.initialColor,
    required this.batteryHealth,
    required this.conditionGrade,
    this.realImageUrl,
    this.galleryUrls,
    this.height = 320,
    this.showControls = true,
    this.on360InspectTap,
  });

  @override
  State<SmartphonePreviewWidget> createState() => _SmartphonePreviewWidgetState();
}

class _SmartphonePreviewWidgetState extends State<SmartphonePreviewWidget>
    with TickerProviderStateMixin {
  late PhoneViewMode _currentMode;
  late PhoneColorOption _selectedColor;
  late List<PhoneColorOption> _availableColors;

  // 360 Rotation Physics State & Inertia Momentum
  double _rotationAngle = 0.0; // In radians (0 to 2*PI)
  bool _isAutoSpinning = false;
  late final AnimationController _spinController;
  late final AnimationController _inertiaController;
  Animation<double>? _inertiaAnimation;
  int _lastDetentIndex = -1;

  void _checkDetent(double angle) {
    final norm = (angle % (2 * math.pi));
    const step = math.pi / 2; // 0, 90, 180, 270 degrees
    final detentIndex = ((norm + step * 0.15) / step).floor() % 4;
    final diff = (norm - detentIndex * step).abs();
    if (diff < 0.08 && detentIndex != _lastDetentIndex) {
      _lastDetentIndex = detentIndex;
      HapticFeedback.selectionClick();
    } else if (diff > 0.16) {
      _lastDetentIndex = -1;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentMode = PhoneViewMode.studio360;
    _availableColors = _getBrandColors(widget.brand, widget.initialColor);
    _selectedColor = _availableColors.firstWhere(
      (c) => c.name.toLowerCase() == widget.initialColor.toLowerCase(),
      orElse: () => _availableColors.first,
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (_isAutoSpinning) {
          final next = _spinController.value * 2 * math.pi;
          _checkDetent(next);
          setState(() {
            _rotationAngle = next;
          });
        }
      });

    _inertiaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void didUpdateWidget(SmartphonePreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brand != widget.brand || oldWidget.initialColor != widget.initialColor) {
      _availableColors = _getBrandColors(widget.brand, widget.initialColor);
      _selectedColor = _availableColors.firstWhere(
        (c) => c.name.toLowerCase() == widget.initialColor.toLowerCase(),
        orElse: () => _availableColors.first,
      );
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _inertiaController.dispose();
    super.dispose();
  }

  void _toggleAutoSpin() {
    HapticFeedback.lightImpact();
    setState(() {
      _isAutoSpinning = !_isAutoSpinning;
      if (_isAutoSpinning) {
        _inertiaController.stop();
        _spinController.repeat();
      } else {
        _spinController.stop();
      }
    });
  }

  void _setPresetAngle(double radians) {
    HapticFeedback.selectionClick();
    if (_isAutoSpinning) _toggleAutoSpin();
    _inertiaController.stop();
    setState(() {
      _rotationAngle = radians;
    });
  }

  List<PhoneColorOption> _getBrandColors(String brand, String fallbackName) {
    final b = brand.toLowerCase();
    if (b.contains('apple')) {
      return const [
        PhoneColorOption(
          name: 'Space Black',
          bodyColor: Color(0xFF1C1D1F),
          frameColor: Color(0xFF2E3033),
          accentColor: Color(0xFF505357),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Deep Purple',
          bodyColor: Color(0xFF382B45),
          frameColor: Color(0xFF513F63),
          accentColor: Color(0xFF8B6BA8),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Natural Titanium',
          bodyColor: Color(0xFF8B877E),
          frameColor: Color(0xFFAAA59B),
          accentColor: Color(0xFFD6D1C6),
          isDark: false,
        ),
        PhoneColorOption(
          name: 'Midnight Blue',
          bodyColor: Color(0xFF14202E),
          frameColor: Color(0xFF22354A),
          accentColor: Color(0xFF3B5675),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Product Red',
          bodyColor: Color(0xFF941822),
          frameColor: Color(0xFFB92230),
          accentColor: Color(0xFFEF4444),
          isDark: true,
        ),
      ];
    } else if (b.contains('samsung')) {
      return const [
        PhoneColorOption(
          name: 'Phantom Black',
          bodyColor: Color(0xFF18191B),
          frameColor: Color(0xFF2A2C30),
          accentColor: Color(0xFF4C4F56),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Botanic Green',
          bodyColor: Color(0xFF25382E),
          frameColor: Color(0xFF3A5446),
          accentColor: Color(0xFF59806B),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Bora Purple',
          bodyColor: Color(0xFF67527D),
          frameColor: Color(0xFF83699D),
          accentColor: Color(0xFFB094CD),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Cream Gold',
          bodyColor: Color(0xFFE5DFC9),
          frameColor: Color(0xFFC3BCA8),
          accentColor: Color(0xFF8D8570),
          isDark: false,
        ),
      ];
    } else if (b.contains('google')) {
      return const [
        PhoneColorOption(
          name: 'Hazel & Gold',
          bodyColor: Color(0xFF576057),
          frameColor: Color(0xFFC5A038),
          accentColor: Color(0xFFF0DA8C),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Obsidian Black',
          bodyColor: Color(0xFF181A1D),
          frameColor: Color(0xFF2C2F33),
          accentColor: Color(0xFF464B52),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Snow White',
          bodyColor: Color(0xFFEFF2F6),
          frameColor: Color(0xFFCCD1D9),
          accentColor: Color(0xFF9AA0AC),
          isDark: false,
        ),
      ];
    } else {
      return const [
        PhoneColorOption(
          name: 'Titan Black',
          bodyColor: Color(0xFF1A1D21),
          frameColor: Color(0xFF2E333B),
          accentColor: Color(0xFF4B535E),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Emerald Green',
          bodyColor: Color(0xFF123F30),
          frameColor: Color(0xFF1E634C),
          accentColor: Color(0xFF38A982),
          isDark: true,
        ),
        PhoneColorOption(
          name: 'Blue Tide',
          bodyColor: Color(0xFF1B3556),
          frameColor: Color(0xFF2A4E7D),
          accentColor: Color(0xFF4678BA),
          isDark: true,
        ),
      ];
    }
  }

  String _getAngleDescription(double radians) {
    final deg = ((radians * 180 / math.pi) % 360).round();
    if (deg >= 338 || deg < 23) {
      return '0° Front OLED Display';
    } else if (deg >= 23 && deg < 68) {
      return '45° 3D Isometric View';
    } else if (deg >= 68 && deg < 113) {
      return '90° Slim Side Profile';
    } else if (deg >= 113 && deg < 158) {
      return '135° Rear Perspective';
    } else if (deg >= 158 && deg < 203) {
      return '180° Back Glass Chassis';
    } else if (deg >= 203 && deg < 248) {
      return '225° Rear Left Perspective';
    } else if (deg >= 248 && deg < 293) {
      return '270° Left Bezel Profile';
    } else {
      return '315° Front Left Angle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Navigation Mode Tabs
        if (widget.showControls) _buildModeTabs(),

        const SizedBox(height: 10),

        // 2. Main Studio Viewport
        _buildActiveViewport(),

        const SizedBox(height: 10),

        // 3. 360 Preset Angle Chips (When in 360 Studio Mode)
        if (_currentMode == PhoneViewMode.studio360) ...[
          _build360AnglePresets(),
          const SizedBox(height: 8),
        ],

        // 4. Color Swatch Selector Row
        if (widget.showControls) _buildColorSwatchRow(),
      ],
    );
  }

  // --- 1. Mode Tabs ---
  Widget _buildModeTabs() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          _buildTabItem(PhoneViewMode.studio360, '🔄 360° Studio', Icons.threed_rotation_rounded),
          _buildTabItem(PhoneViewMode.cameraMacro, '📸 Macro Lens', Icons.camera_rounded),
          _buildTabItem(PhoneViewMode.diagnosticsBench, '🔬 32-Pt Rig', Icons.science_rounded),
        ],
      ),
    );
  }

  Widget _buildTabItem(PhoneViewMode mode, String label, IconData icon) {
    final isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            setState(() {
              _currentMode = mode;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? EcoColors.forestGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: EcoColors.forestGreen.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : EcoColors.forestGreen.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // --- 2. Active Viewport Switcher ---
  Widget _buildActiveViewport() {
    switch (_currentMode) {
      case PhoneViewMode.studio360:
        return _build360DegreeStudioViewport();
      case PhoneViewMode.cameraMacro:
        return _buildCameraMacroViewport();
      case PhoneViewMode.diagnosticsBench:
        return _buildDiagnosticsHUDViewport();
    }
  }

  // =========================================================================
  // VIEWPORT 1: ULTRA-LUXURY 360° STUDIO VIEWPORT (Inertia & Detents)
  // =========================================================================
  Widget _build360DegreeStudioViewport() {
    final normalized = (_rotationAngle % (2 * math.pi));
    final isFrontFacing = normalized < (math.pi / 2) || normalized > (3 * math.pi / 2);
    final currentAngleLabel = _getAngleDescription(_rotationAngle);

    return GestureDetector(
      onHorizontalDragStart: (_) {
        _inertiaController.stop();
        if (_isAutoSpinning) _toggleAutoSpin();
      },
      onHorizontalDragUpdate: (details) {
        final double delta = details.primaryDelta! * 0.015;
        final double newAngle = (_rotationAngle + delta) % (2 * math.pi);
        _checkDetent(newAngle);
        setState(() {
          _rotationAngle = newAngle;
        });
      },
      onHorizontalDragEnd: (details) {
        final vx = details.primaryVelocity ?? 0.0;
        if (vx.abs() > 100) {
          final double flingRadians = (vx * 0.0018).clamp(-math.pi * 3, math.pi * 3);
          final double startAngle = _rotationAngle;
          final double targetAngle = startAngle + flingRadians;

          _inertiaAnimation = Tween<double>(begin: startAngle, end: targetAngle).animate(
            CurvedAnimation(parent: _inertiaController, curve: Curves.easeOutCubic),
          )..addListener(() {
              final cur = _inertiaAnimation!.value % (2 * math.pi);
              _checkDetent(cur);
              setState(() {
                _rotationAngle = cur;
              });
            });

          _inertiaController.forward(from: 0.0);
        }
      },
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF1F5F2),
              Color(0xFFE2E8E4),
            ],
            center: Alignment(0, -0.2),
            radius: 1.1,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Showcase Halo Glow behind phone
            Positioned(
              child: Container(
                width: 170,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _selectedColor.accentColor.withOpacity(0.20),
                      _selectedColor.bodyColor.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Studio Stage Light Beam & Circular Pedestal
            Positioned(
              bottom: 30,
              child: Container(
                width: 170,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: RadialGradient(
                    colors: [
                      _selectedColor.accentColor.withOpacity(0.35),
                      Colors.black.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Dynamic Ground Contact Shadow
            Positioned(
              bottom: 36,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: (120 + math.cos(_rotationAngle).abs() * 32).clamp(90.0, 155.0),
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // 3D Smooth Perspective Phone Renderer (Isolated RepaintBoundary for 60/120 FPS)
            RepaintBoundary(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0014)
                  ..rotateY(_rotationAngle),
                child: isFrontFacing
                    ? _buildUltraRealisticFrontDisplay()
                    : _buildUltraRealisticBackChassis(),
              ),
            ),

            // Top Left: Live Angle Readout Pill
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.screen_rotation_rounded, size: 12, color: EcoColors.forestGreen),
                    const SizedBox(width: 4),
                    Text(
                      currentAngleLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: EcoColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Right: Auto-Spin Toggle & Fullscreen Modal Launch
            Positioned(
              top: 10,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Auto-Spin 360 Button
                  GestureDetector(
                    onTap: _toggleAutoSpin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isAutoSpinning ? EcoColors.vibrantOrange : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isAutoSpinning ? EcoColors.vibrantOrange : Colors.black.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isAutoSpinning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 13,
                            color: _isAutoSpinning ? Colors.white : EcoColors.forestGreen,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _isAutoSpinning ? 'Pause' : 'Auto Spin',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isAutoSpinning ? Colors.white : EcoColors.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Fullscreen Modal
                  GestureDetector(
                    onTap: widget.on360InspectTap ?? _showFullscreen360Modal,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: const Icon(Icons.fullscreen_rounded, size: 16, color: EcoColors.forestGreen),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Center: Gesture Swipe Hint
            Positioned(
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Drag left/right to rotate 360°',
                      style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. ULTRA-REALISTIC FRONT OLED DISPLAY
  // ==========================================
  Widget _buildUltraRealisticFrontDisplay() {
    final isApple = widget.brand.toLowerCase().contains('apple');

    return Container(
      width: 146,
      height: 258,
      decoration: BoxDecoration(
        color: _selectedColor.frameColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _selectedColor.accentColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _selectedColor.accentColor.withOpacity(0.85),
          width: 2.2,
        ),
      ),
      padding: const EdgeInsets.all(3.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF030712),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.black, width: 1.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photorealistic OLED Wallpaper with Fluid Curves
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _selectedColor.bodyColor.withOpacity(0.95),
                      const Color(0xFF090D16),
                      _selectedColor.wallpaperAccent.withOpacity(0.4),
                      const Color(0xFF020617),
                    ],
                    stops: const [0.0, 0.45, 0.8, 1.0],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),

              // Wallpaper Mesh Flare Accent
              Positioned(
                top: 40,
                right: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _selectedColor.wallpaperAccent.withOpacity(0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Glass Glare Specular Light
              Positioned.fill(
                child: CustomPaint(
                  painter: _GlassGlarePainter(angle: _rotationAngle),
                ),
              ),

              // Top Status Bar: Time & Connectivity
              Positioned(
                top: 5,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '9:41',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.signal_cellular_alt_rounded, size: 8.5, color: Colors.white),
                        const SizedBox(width: 2.5),
                        const Icon(Icons.wifi_rounded, size: 8.5, color: Colors.white),
                        const SizedBox(width: 3),
                        Container(
                          width: 13,
                          height: 6.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.white, width: 0.8),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 8,
                              height: 4,
                              color: EcoColors.mintGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dynamic Island (Apple) vs Punch Hole (Android)
              Positioned(
                top: 5,
                left: 0,
                right: 0,
                child: Center(
                  child: isApple
                      ? Container(
                          width: 42,
                          height: 11.5,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.white12, width: 0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 5.5,
                                height: 5.5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0D1E2D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 3.5,
                                height: 3.5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: 7.5,
                          height: 7.5,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                        ),
                ),
              ),

              // Lock Screen Big Time
              Positioned(
                top: 42,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      '09:41',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Sunday, 6 September',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Mid Screen: EcoFone Verified Seal Card
              Positioned(
                top: 115,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, size: 11, color: EcoColors.mintGreen),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.conditionGrade.split(' ').first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🔋 ${widget.batteryHealth}% Battery • Certified Rig',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 7.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Lockscreen Action Icons
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flashlight_on_rounded, size: 11, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Home Indicator Bar
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 42,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(2),
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

  // ==========================================
  // 2. ULTRA-REALISTIC BACK GLASS CHASSIS
  // ==========================================
  Widget _buildUltraRealisticBackChassis() {
    return Container(
      width: 146,
      height: 258,
      decoration: BoxDecoration(
        color: _selectedColor.bodyColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.bodyColor.withOpacity(0.45),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _selectedColor.frameColor,
          width: 2.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Frosted Matte Glass Texture & Multi-Tone Lighting
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.28),
                      Colors.transparent,
                      Colors.black.withOpacity(0.32),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Back Glass Specular Shine
            Positioned.fill(
              child: CustomPaint(
                painter: _GlassGlarePainter(angle: _rotationAngle + math.pi),
              ),
            ),

            // Brand-Specific Precision Camera Island
            Positioned(
              top: 10,
              left: 10,
              child: _buildPrecisionCameraModule(),
            ),

            // Center: Metallic Chrome Brand Emblem
            Center(
              child: _buildCenterBrandLogo(),
            ),

            // Bottom: Laser-Engraved Rig Badge
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'EcoFone Certified 32-Pt Rig',
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      color: _selectedColor.isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Grade: ${widget.conditionGrade}',
                    style: TextStyle(
                      fontSize: 6.5,
                      color: _selectedColor.isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterBrandLogo() {
    final b = widget.brand.toLowerCase();
    final isDark = _selectedColor.isDark;
    final color = isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4);

    if (b.contains('apple')) {
      return Icon(Icons.apple, size: 30, color: color);
    } else if (b.contains('samsung')) {
      return Text(
        'SAMSUNG',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
          color: color,
        ),
      );
    } else if (b.contains('google')) {
      return Text(
        'G',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      );
    } else {
      return Text(
        widget.brand.toUpperCase(),
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
          color: color,
        ),
      );
    }
  }

  Widget _buildPrecisionCameraModule() {
    final b = widget.brand.toLowerCase();

    if (b.contains('apple')) {
      // Apple Pro Triangular Triple Camera Island with Glass Plateau
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: _selectedColor.frameColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(1.5, 2.5),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
        ),
        child: Stack(
          children: [
            Positioned(top: 6, left: 6, child: _buildPrecisionLens(size: 22)),
            Positioned(bottom: 6, left: 6, child: _buildPrecisionLens(size: 22)),
            Positioned(top: 20, right: 6, child: _buildPrecisionLens(size: 22)),
            // True Tone Flash
            Positioned(
              top: 7,
              right: 10,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9DB),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4A373), width: 0.8),
                ),
              ),
            ),
            // LiDAR Scanner
            Positioned(
              bottom: 8,
              right: 10,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (b.contains('samsung')) {
      // Samsung Floating Vertical Triple Lens Matrix
      return Column(
        children: [
          _buildPrecisionLens(size: 20, hasOuterRing: true),
          const SizedBox(height: 5),
          _buildPrecisionLens(size: 20, hasOuterRing: true),
          const SizedBox(height: 5),
          _buildPrecisionLens(size: 20, hasOuterRing: true),
        ],
      );
    } else if (b.contains('google')) {
      // Google Pixel Metallic Camera Visor
      return Container(
        width: 120,
        height: 32,
        decoration: BoxDecoration(
          color: _selectedColor.frameColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white24, width: 0.8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _buildPrecisionLens(size: 15),
                  const SizedBox(width: 3),
                  _buildPrecisionLens(size: 15),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _buildPrecisionLens(size: 14),
          ],
        ),
      );
    } else {
      // Circular Camera Dial
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1B2028),
          shape: BoxShape.circle,
          border: Border.all(color: _selectedColor.accentColor.withOpacity(0.5), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildPrecisionLens(size: 15),
              _buildPrecisionLens(size: 15),
              _buildPrecisionLens(size: 15),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPrecisionLens({required double size, bool hasOuterRing = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        shape: BoxShape.circle,
        border: Border.all(
          color: hasOuterRing ? _selectedColor.frameColor : const Color(0xFF475569),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.58,
          height: size * 0.58,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color(0xFF0284C7),
                Color(0xFF1E1B4B),
                Color(0xFF020617),
              ],
              center: Alignment(-0.3, -0.3),
            ),
          ),
          child: Align(
            alignment: const Alignment(-0.35, -0.35),
            child: Container(
              width: 2.5,
              height: 2.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 360 Preset Angle Chips ---
  Widget _build360AnglePresets() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _buildPresetChip('0° Front', 0.0),
          _buildPresetChip('45° 3D', math.pi / 4),
          _buildPresetChip('90° Side', math.pi / 2),
          _buildPresetChip('180° Back', math.pi),
          _buildPresetChip('270° Bezel', 3 * math.pi / 2),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, double radians) {
    final isMatching = ((_rotationAngle - radians) % (2 * math.pi)).abs() < 0.2;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _setPresetAngle(radians),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: isMatching ? EcoColors.forestGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMatching ? EcoColors.forestGreen : Colors.black.withOpacity(0.1),
            ),
            boxShadow: [
              if (isMatching)
                BoxShadow(
                  color: EcoColors.forestGreen.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isMatching ? FontWeight.bold : FontWeight.w600,
              color: isMatching ? Colors.white : EcoColors.forestGreen,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // VIEWPORT 2: CAMERA MACRO LENS VIEWPORT
  // =========================================================================
  Widget _buildCameraMacroViewport() {
    return Container(
      height: widget.height,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EcoColors.mintGreen.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF64748B), width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withOpacity(0.4),
                  blurRadius: 22,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF1E1B4B), Colors.black],
                    center: Alignment(-0.2, -0.2),
                  ),
                ),
                child: const Center(
                  child: Text(
                    '4K 60FPS OIS',
                    style: TextStyle(color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: EcoColors.mintGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: EcoColors.mintGreen.withOpacity(0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 13, color: EcoColors.mintGreen),
                SizedBox(width: 4),
                Text(
                  'Sapphire Crystal • Zero Scratches Certified',
                  style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dual OIS Sensor-Shift • Laser Autofocus 100% Calibrated',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEWPORT 3: 32-POINT TEST BENCH DIAGNOSTICS HUD
  // =========================================================================
  Widget _buildDiagnosticsHUDViewport() {
    return Container(
      height: widget.height,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF08140E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EcoColors.mintGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_rounded, size: 16, color: EcoColors.mintGreen),
                  SizedBox(width: 6),
                  Text(
                    '32-Point Test Bench Diagnostics',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: EcoColors.mintGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '100% PASS',
                  style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 14),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildHUDItem('Original Display & Touch Matrix', '100% Passed (Zero dead pixels)', Icons.touch_app_rounded),
                _buildHUDItem('Battery Health', '${widget.batteryHealth}% Peak Endurance Verified', Icons.battery_charging_full_rounded),
                _buildHUDItem('Biometrics (Face/Touch ID)', 'Active & Response-Calibrated', Icons.fingerprint_rounded),
                _buildHUDItem('Camera Optics & LiDAR', 'Dual OIS 4K Focus Verified', Icons.camera_alt_rounded),
                _buildHUDItem('Motherboard & Sensors', '0% Moisture • Thermal Diagnostics OK', Icons.memory_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDItem(String title, String status, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: EcoColors.mintGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                Text(status, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 8.5)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, size: 14, color: EcoColors.mintGreen),
        ],
      ),
    );
  }

  // --- Color Swatches ---
  Widget _buildColorSwatchRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chassis Color: ',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: EcoColors.forestGreen.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 6),
        ..._availableColors.map((colorOption) {
          final isSelected = colorOption.name == _selectedColor.name;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                HapticFeedback.selectionClick();
                setState(() => _selectedColor = colorOption);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? EcoColors.vibrantOrange : Colors.black.withOpacity(0.12),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colorOption.bodyColor,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: 12,
                        color: colorOption.isDark ? Colors.white : Colors.black87,
                      )
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showFullscreen360Modal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Phone360InspectorModal(
        brand: widget.brand,
        modelName: widget.modelName,
        selectedColor: _selectedColor,
        batteryHealth: widget.batteryHealth,
        conditionGrade: widget.conditionGrade,
      ),
    );
  }
}

/// Custom painter for dynamic glass specular glare
class _GlassGlarePainter extends CustomPainter {
  final double angle;

  _GlassGlarePainter({this.angle = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final shift = math.sin(angle);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(shift, -1.0),
        end: Alignment(-shift, 1.0),
        colors: [
          Colors.white.withOpacity(0.28),
          Colors.white.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.7],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.6)
      ..lineTo(0, size.height * 0.9)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassGlarePainter oldDelegate) => oldDelegate.angle != angle;
}

// =========================================================================
// MINI PHONE THUMBNAIL (For Stock Grid Cards & Wishlist Tiles)
// =========================================================================
class MiniPhoneThumbnail extends StatelessWidget {
  final String brand;
  final String colorName;
  final int batteryHealth;
  final String? realImageUrl;
  final double width;
  final double height;

  const MiniPhoneThumbnail({
    super.key,
    required this.brand,
    required this.colorName,
    required this.batteryHealth,
    this.realImageUrl,
    this.width = 62,
    this.height = 104,
  });

  @override
  Widget build(BuildContext context) {
    final isApple = brand.toLowerCase().contains('apple');
    final cleanUrl = realImageUrl?.replaceAll('.jpg', '.png');
    final hasRealImage = cleanUrl != null && cleanUrl.isNotEmpty;

    if (hasRealImage) {
      final isAsset = cleanUrl.startsWith('assets/') || !cleanUrl.startsWith('http');
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft subtle ground shadow beneath smartphone
            Positioned(
              bottom: 2,
              child: Container(
                width: width * 0.7,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            // High-Definition Original Phone Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isAsset
                  ? Image.asset(
                      cleanUrl,
                      width: width,
                      height: height,
                      cacheWidth: (width * 3.0).round().clamp(150, 800),
                      cacheHeight: (height * 3.0).round().clamp(200, 1200),
                      filterQuality: FilterQuality.medium,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildVectorCard(isApple),
                    )
                  : Image.network(
                      cleanUrl,
                      width: width,
                      height: height,
                      cacheWidth: (width * 3.0).round().clamp(150, 800),
                      cacheHeight: (height * 3.0).round().clamp(200, 1200),
                      filterQuality: FilterQuality.medium,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildVectorCard(isApple),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                              color: EcoColors.forestGreen,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Battery Health Badge Pill
            if (batteryHealth > 0)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13583C),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 8, color: Colors.white),
                      Text(
                        '$batteryHealth%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
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

    return _buildVectorCard(isApple);
  }

  Widget _buildVectorCard(bool isApple) {
    final phoneColor = _resolveColor(colorName);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: phoneColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.2),
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B1120),
            gradient: LinearGradient(
              colors: [
                phoneColor.withOpacity(0.9),
                const Color(0xFF030712),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              _buildVectorInterior(isApple),
              // Bottom: Battery Pill
              Positioned(
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                  ),
                  child: Text(
                    '$batteryHealth%',
                    style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVectorInterior(bool isApple) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 3,
          child: isApple
              ? Container(
                  width: 18,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                ),
        ),
        Center(
          child: Icon(
            isApple ? Icons.apple : Icons.smartphone_rounded,
            size: 20,
            color: Colors.white.withOpacity(0.35),
          ),
        ),
      ],
    );
  }

  Color _resolveColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('black') || n.contains('space') || n.contains('obsidian')) {
      return const Color(0xFF202226);
    } else if (n.contains('purple')) {
      return const Color(0xFF553D66);
    } else if (n.contains('blue') || n.contains('midnight')) {
      return const Color(0xFF1B314B);
    } else if (n.contains('green') || n.contains('hazel')) {
      return const Color(0xFF264635);
    } else if (n.contains('red')) {
      return const Color(0xFF9E1B26);
    } else if (n.contains('gold') || n.contains('cream')) {
      return const Color(0xFFD4AF37);
    } else {
      return const Color(0xFF64748B);
    }
  }
}

// =========================================================================
// FULLSCREEN 360-DEGREE INTERACTIVE INSPECTOR MODAL
// =========================================================================
class Phone360InspectorModal extends StatefulWidget {
  final String brand;
  final String modelName;
  final PhoneColorOption selectedColor;
  final int batteryHealth;
  final String conditionGrade;

  const Phone360InspectorModal({
    super.key,
    required this.brand,
    required this.modelName,
    required this.selectedColor,
    required this.batteryHealth,
    required this.conditionGrade,
  });

  @override
  State<Phone360InspectorModal> createState() => _Phone360InspectorModalState();
}

class _Phone360InspectorModalState extends State<Phone360InspectorModal>
    with SingleTickerProviderStateMixin {
  double _rotationAngle = 0.0;
  bool _isAutoSpinning = true;
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (_isAutoSpinning) {
          setState(() {
            _rotationAngle = _spinController.value * 2 * math.pi;
          });
        }
      });
    _spinController.repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _toggleAutoSpin() {
    setState(() {
      _isAutoSpinning = !_isAutoSpinning;
      if (_isAutoSpinning) {
        _spinController.repeat();
      } else {
        _spinController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalized = (_rotationAngle % (2 * math.pi));
    final isFront = normalized < (math.pi / 2) || normalized > (3 * math.pi / 2);

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.modelName} 360° Showroom',
                    style: const TextStyle(
                      color: EcoColors.forestGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Color: ${widget.selectedColor.name} • ${widget.conditionGrade}',
                    style: const TextStyle(color: EcoColors.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 360 Drag Viewport
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                if (_isAutoSpinning) _toggleAutoSpin();
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _rotationAngle = (_rotationAngle + details.primaryDelta! * 0.015) % (2 * math.pi);
                });
              },
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0014)
                    ..rotateY(_rotationAngle),
                  child: isFront
                      ? _buildFrontFullscreenMockup()
                      : _buildBackFullscreenMockup(),
                ),
              ),
            ),
          ),

          // 360 Degree Rotation Slider
          Slider(
            value: (_rotationAngle % (2 * math.pi)),
            min: 0,
            max: 2 * math.pi,
            activeColor: EcoColors.forestGreen,
            inactiveColor: Colors.grey.shade200,
            onChanged: (val) {
              if (_isAutoSpinning) _toggleAutoSpin();
              setState(() {
                _rotationAngle = val;
              });
            },
          ),

          const SizedBox(height: 4),

          // Auto-Spin & Control Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleAutoSpin,
                  icon: Icon(
                    _isAutoSpinning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: EcoColors.forestGreen,
                  ),
                  label: Text(
                    _isAutoSpinning ? 'Pause 360° Spin' : 'Resume Auto Spin',
                    style: const TextStyle(color: EcoColors.forestGreen, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: EcoColors.forestGreen.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrontFullscreenMockup() {
    return Container(
      width: 160,
      height: 285,
      decoration: BoxDecoration(
        color: widget.selectedColor.frameColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: widget.selectedColor.accentColor, width: 2),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF030712),
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              widget.selectedColor.bodyColor.withOpacity(0.95),
              const Color(0xFF090D16),
              widget.selectedColor.wallpaperAccent.withOpacity(0.4),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_iphone_rounded, size: 40, color: Colors.white70),
              SizedBox(height: 8),
              Text(
                'Front OLED Display 0°',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '100% Scratch-Free Display',
                style: TextStyle(color: EcoColors.mintGreen, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackFullscreenMockup() {
    return Container(
      width: 160,
      height: 285,
      decoration: BoxDecoration(
        color: widget.selectedColor.bodyColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: widget.selectedColor.bodyColor.withOpacity(0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: widget.selectedColor.frameColor, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_rounded, size: 40, color: Colors.white.withOpacity(0.85)),
            const SizedBox(height: 8),
            const Text(
              'Back Glass 180°',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'Color: ${widget.selectedColor.name}',
              style: const TextStyle(color: EcoColors.mintGreen, fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
