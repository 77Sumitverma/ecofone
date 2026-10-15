import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/phone_3d_pop_showcase.dart';
import 'package:ecofone/core/widgets/smartphone_preview_widget.dart';
import 'package:ecofone/screens/directions_sheet.dart';
import 'package:ecofone/screens/location_sheet.dart';
import 'package:ecofone/state/app_state.dart';
import 'package:ecofone/core/widgets/pos_invoice_sheet.dart';
import 'package:ecofone/services/payment/razorpay_checkout_service.dart';

/// Interactive Draggable Pop-up Detail Sheet (60 FPS Native Physics)
class PhoneDetailSheet {
  static Future<void> show(
    BuildContext context,
    PhoneStockItem phone, {
    List<PhoneStockItem>? allPhones,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.50),
      enableDrag: true,
      useSafeArea: false,
      builder: (_) => _DraggablePhoneDetailSheet(
        phone: phone,
        allPhones: allPhones,
      ),
    );
  }
}

class _DraggablePhoneDetailSheet extends StatefulWidget {
  final PhoneStockItem phone;
  final List<PhoneStockItem>? allPhones;

  const _DraggablePhoneDetailSheet({
    required this.phone,
    this.allPhones,
  });

  @override
  State<_DraggablePhoneDetailSheet> createState() => _DraggablePhoneDetailSheetState();
}

class _DraggablePhoneDetailSheetState extends State<_DraggablePhoneDetailSheet> {
  late final DraggableScrollableController _dragController;

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: 0.72,
      minChildSize: 0.35,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.72, 1.0],
      snapAnimationDuration: const Duration(milliseconds: 240),
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: EcoColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Color(0x2A000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: PhoneDetailContent(
              phone: widget.phone,
              allPhones: widget.allPhones,
              isSheet: true,
              scrollController: scrollController,
              dragController: _dragController,
            ),
          ),
        );
      },
    );
  }
}

/// Standalone Full-Page Product Detail Screen for direct routes and testing
class PhoneDetailScreen extends StatelessWidget {
  final PhoneStockItem phone;
  final List<PhoneStockItem>? allPhones;

  const PhoneDetailScreen({
    super.key,
    required this.phone,
    this.allPhones,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      body: SafeArea(
        child: PhoneDetailContent(
          phone: phone,
          allPhones: allPhones,
          isSheet: false,
        ),
      ),
    );
  }
}

/// Shared interactive Product Detail Content Widget
class PhoneDetailContent extends StatefulWidget {
  final PhoneStockItem phone;
  final List<PhoneStockItem>? allPhones;
  final bool isSheet;
  final ScrollController? scrollController;
  final DraggableScrollableController? dragController;

  const PhoneDetailContent({
    super.key,
    required this.phone,
    this.allPhones,
    this.isSheet = false,
    this.scrollController,
    this.dragController,
  });

  @override
  State<PhoneDetailContent> createState() => _PhoneDetailContentState();
}

class _PhoneDetailContentState extends State<PhoneDetailContent> {
  static const _bgColor = EcoColors.background;
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;
  static const _softGreen = EcoColors.mintGreen;

  late PhoneStockItem _currentPhone;
  late String _selectedStorage;
  late String _selectedColor;

  List<String> get _availableStorages {
    final name = _currentPhone.name.toLowerCase();
    if (name.contains('14 pro') || name.contains('13 pro') || name.contains('ultra')) {
      return const ['128 GB', '256 GB', '512 GB', '1 TB'];
    }
    if (name.contains('iphone 11') || name.contains('iphone 12')) {
      return const ['64 GB', '128 GB', '256 GB'];
    }
    return const ['128 GB', '256 GB', '512 GB'];
  }

  int _parseStorageGb(String storageStr) {
    if (storageStr.contains('1 TB')) return 1024;
    final digits = storageStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 128;
  }

  int _getRefurbishedTierOffset(int gb, bool isFlagship) {
    if (isFlagship) {
      if (gb <= 64) return -4000;
      if (gb <= 128) return 0;
      if (gb <= 256) return 5000;
      if (gb <= 512) return 12000;
      return 20000; // 1 TB
    } else {
      if (gb <= 64) return -2500;
      if (gb <= 128) return 0;
      if (gb <= 256) return 2500;
      if (gb <= 512) return 5500;
      return 9000;
    }
  }

  int _getOriginalTierOffset(int gb, bool isFlagship) {
    if (isFlagship) {
      if (gb <= 64) return -8000;
      if (gb <= 128) return 0;
      if (gb <= 256) return 10000;
      if (gb <= 512) return 22000;
      return 36000; // 1 TB
    } else {
      if (gb <= 64) return -4000;
      if (gb <= 128) return 0;
      if (gb <= 256) return 5000;
      if (gb <= 512) return 11000;
      return 18000;
    }
  }

  int get _calculatedRefurbishedPrice {
    final baseGb = _parseStorageGb(_currentPhone.storage);
    final selectedGb = _parseStorageGb(_selectedStorage);
    if (baseGb == selectedGb) return _currentPhone.refurbishedPrice;

    final isFlagship = _currentPhone.refurbishedPrice >= 35000;
    final baseOffset = _getRefurbishedTierOffset(baseGb, isFlagship);
    final selectedOffset = _getRefurbishedTierOffset(selectedGb, isFlagship);
    final delta = selectedOffset - baseOffset;

    return (_currentPhone.refurbishedPrice + delta).clamp(1000, 300000);
  }

  int get _calculatedOriginalPrice {
    final baseGb = _parseStorageGb(_currentPhone.storage);
    final selectedGb = _parseStorageGb(_selectedStorage);
    if (baseGb == selectedGb) return _currentPhone.originalPrice;

    final isFlagship = _currentPhone.originalPrice >= 50000;
    final baseOffset = _getOriginalTierOffset(baseGb, isFlagship);
    final selectedOffset = _getOriginalTierOffset(selectedGb, isFlagship);
    final delta = selectedOffset - baseOffset;

    return (_currentPhone.originalPrice + delta).clamp(1000, 500000);
  }

  int get _calculatedSavingsAmount =>
      (_calculatedOriginalPrice - _calculatedRefurbishedPrice).clamp(0, 500000);

  int get _calculatedSavingsPercent => _calculatedOriginalPrice > 0
      ? (((_calculatedOriginalPrice - _calculatedRefurbishedPrice) / _calculatedOriginalPrice) * 100).round()
      : 0;

  @override
  void initState() {
    super.initState();
    _currentPhone = widget.phone;
    _selectedStorage = _currentPhone.storage;
    _selectedColor = _currentPhone.color;
    AppState.instance.addListener(_onAppStateChanged);
  }

  @override
  void didUpdateWidget(covariant PhoneDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phone.id != widget.phone.id) {
      _currentPhone = widget.phone;
      _selectedStorage = _currentPhone.storage;
      _selectedColor = _currentPhone.color;
    }
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
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

  List<PhoneStockItem> get _similarPhones {
    final catalog = widget.allPhones ?? PhoneStockItem.sampleInventory;
    return catalog.where((p) => p.id != _currentPhone.id).toList();
  }

  void _sharePhone() {
    Clipboard.setData(
      ClipboardData(
        text: 'Check out this certified refurbished ${_currentPhone.name} ($_selectedStorage, $_selectedColor) on EcoFone for ${_formatPrice(_calculatedRefurbishedPrice)} with 6-Month Warranty!',
      ),
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Link copied to clipboard! Share it anywhere.'),
        backgroundColor: _forestGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _switchToPhone(PhoneStockItem phone) {
    setState(() {
      _currentPhone = phone;
      _selectedStorage = phone.storage;
      _selectedColor = phone.color;
    });
  }

  void _toggleExpansion() {
    if (widget.dragController != null && widget.dragController!.isAttached) {
      final current = widget.dragController!.size;
      if (current < 0.88) {
        widget.dragController!.animateTo(
          1.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        widget.dragController!.animateTo(
          0.72,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWishlisted = AppState.instance.isWishlisted(_currentPhone.id);
    final selectedStore = AppState.instance.selectedStore;
    final distanceKm = AppState.instance.getLiveDistanceFrom(selectedStore);

    return Column(
      children: [
        // 1. Adaptive Header (Smoothly responds to drag extent)
        _buildAdaptiveHeader(isWishlisted),

        // 2. Main Scrollable Product Body (Uses ClampingScrollPhysics in Sheet to avoid gesture conflict)
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: widget.isSheet
                ? const ClampingScrollPhysics()
                : const BouncingScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(_currentPhone.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Hero Device Showcase
                    _buildHeroShowcase(),

                    // B. Title, Pricing & Value Deal Box
                    _buildTitleAndPricingCard(),

                    const SizedBox(height: 12),

                    // C. Variant Selectors (Storage & Color)
                    _buildVariantSelectors(),

                    const SizedBox(height: 12),

                    // D. 32-Point Diagnostics & Quality Checklist
                    _buildQualityChecklistCard(),

                    const SizedBox(height: 12),

                    // E. Physical Retail Store Availability Hub
                    _buildStoreAvailabilityCard(selectedStore, distanceKm),

                    const SizedBox(height: 16),

                    // F. "Similar Refurbished Phones You May Like"
                    _buildSimilarPhonesSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. Sticky Bottom Action Bar
        _buildStickyBottomBar(selectedStore),
      ],
    );
  }

  // --- Adaptive Header ---
  Widget _buildAdaptiveHeader(bool isWishlisted) {
    if (widget.dragController == null || !widget.isSheet) {
      return _buildHeaderContent(isWishlisted, isExpanded: true);
    }

    return AnimatedBuilder(
      animation: widget.dragController!,
      builder: (context, child) {
        final double size = widget.dragController!.isAttached ? widget.dragController!.size : 0.72;
        final bool isExpanded = size >= 0.92;
        return _buildHeaderContent(isWishlisted, isExpanded: isExpanded);
      },
    );
  }

  Widget _buildHeaderContent(bool isWishlisted, {required bool isExpanded}) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, widget.isSheet ? 8 : 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(isExpanded ? 0.08 : 0.04),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Edge Up Arrow Pull Pill (Tappable to expand with smooth spring animation)
          if (widget.isSheet)
            _BlinkingUpArrowPill(
              isExpanded: isExpanded,
              onTap: _toggleExpansion,
            ),

          // Header Row with Title, Navigation, Share & Wishlist
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  widget.isSheet && !isExpanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  size: widget.isSheet && !isExpanded ? 26 : 19,
                  color: _forestGreen,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleExpansion,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPhone.name,
                        style: const TextStyle(
                          color: _forestGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 12, color: _softGreen),
                          const SizedBox(width: 4),
                          Text(
                            'EcoFone Certified Refurbished',
                            style: TextStyle(
                              color: _forestGreen.withOpacity(0.65),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.isSheet)
                BouncingWidget(
                  scaleFactor: 0.92,
                  onTap: _toggleExpansion,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? EcoColors.forestGreen.withOpacity(0.08)
                          : const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isExpanded
                            ? EcoColors.forestGreen.withOpacity(0.2)
                            : const Color(0xFFA7F3D0),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_double_arrow_down_rounded
                          : Icons.keyboard_double_arrow_up_rounded,
                      size: 19,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
              IconButton(
                onPressed: _sharePhone,
                icon: const Icon(Icons.share_outlined, size: 20, color: _forestGreen),
                tooltip: 'Share Phone',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              AnimatedHeartPop(
                isLiked: isWishlisted,
                size: 22,
                onToggle: () {
                  AppState.instance.toggleWishlist(_currentPhone.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- A. Hero Phone Showcase Carousel / Preview ---
  Widget _buildHeroShowcase() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          // Top Tags: Clean Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: EcoColors.mintLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 13, color: EcoColors.mintGreen),
                    const SizedBox(width: 4),
                    Text(
                      _currentPhone.conditionGrade,
                      style: const TextStyle(
                        color: EcoColors.mintGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: EcoColors.softOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, size: 13, color: EcoColors.vibrantOrange),
                    const SizedBox(width: 3),
                    Text(
                      '${_currentPhone.stockQuantity} In Stock',
                      style: const TextStyle(
                        color: EcoColors.vibrantOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Central Clean Phone Graphic Preview
          SizedBox(
            height: 190,
            child: Center(
              child: MiniPhoneThumbnail(
                brand: _currentPhone.brand,
                colorName: _selectedColor,
                batteryHealth: _currentPhone.batteryHealth,
                realImageUrl: _currentPhone.imageUrl,
                width: 140,
                height: 185,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quality Grade Subtext
          Text(
            _currentPhone.gradeDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _forestGreen.withOpacity(0.65),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- B. Title & Pricing Section ---
  Widget _buildTitleAndPricingCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_currentPhone.name} ($_selectedStorage, $_selectedColor)',
            style: const TextStyle(
              color: _forestGreen,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatPrice(_calculatedRefurbishedPrice),
                style: const TextStyle(
                  color: _forestGreen,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatPrice(_calculatedOriginalPrice),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                  decoration: TextDecoration.lineThrough,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _softGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Save ${_formatPrice(_calculatedSavingsAmount)} ($_calculatedSavingsPercent% OFF)',
                  style: const TextStyle(
                    color: _softGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Clean Assurance Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: EcoColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 16, color: _forestGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Free Express Doorstep Delivery & 2-Hr Store Pickup • 6-Month Warranty',
                    style: TextStyle(
                      color: _forestGreen,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- C. Variant Selectors (Storage & Color) ---
  Widget _buildVariantSelectors() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage Selector
          const Text(
            'Storage Capacity',
            style: TextStyle(
              color: _forestGreen,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableStorages.map((storage) {
              final isSelected = storage == _selectedStorage;
              final selectedGb = _parseStorageGb(storage);
              final baseGb = _parseStorageGb(_currentPhone.storage);
              final isFlagship = _currentPhone.refurbishedPrice >= 35000;
              final diff = _getRefurbishedTierOffset(selectedGb, isFlagship) -
                  _getRefurbishedTierOffset(baseGb, isFlagship);

              String? diffLabel;
              if (diff > 0) {
                diffLabel = '+₹$diff';
              } else if (diff < 0) {
                diffLabel = '-₹${diff.abs()}';
              }

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(storage),
                    if (diffLabel != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        diffLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white.withOpacity(0.85) : EcoColors.vibrantOrange,
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                selectedColor: _forestGreen,
                backgroundColor: EcoColors.background,
                side: BorderSide(
                  color: isSelected ? _forestGreen : Colors.black.withOpacity(0.08),
                  width: 1.0,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _forestGreen,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val && _selectedStorage != storage) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedStorage = storage);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Color Selector
          Row(
            children: [
              const Text(
                'Color: ',
                style: TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              Text(
                _selectedColor,
                style: TextStyle(
                  color: _forestGreen.withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: {_currentPhone.color, 'Space Black', 'Midnight Blue'}.map((color) {
              final isSelected = color == _selectedColor;
              return ChoiceChip(
                label: Text(color),
                selected: isSelected,
                selectedColor: _copper,
                backgroundColor: EcoColors.background,
                side: BorderSide(
                  color: isSelected ? _copper : Colors.black.withOpacity(0.08),
                  width: 1.0,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _forestGreen,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val && _selectedColor != color) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColor = color);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- D. 32-Point Diagnostics & Quality Checklist ---
  Widget _buildQualityChecklistCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: _forestGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'EcoFone Quality Assurance',
                style: TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildChecklistRow(
            icon: Icons.battery_charging_full_rounded,
            title: 'Battery Health: ${_currentPhone.batteryHealth}% Original Capacity',
            subtitle: 'Tested under high workload, guaranteed all-day endurance',
            color: _softGreen,
          ),
          const Divider(height: 20, thickness: 0.5),

          _buildChecklistRow(
            icon: Icons.security_rounded,
            title: '6-Month Comprehensive Warranty',
            subtitle: 'Free repair or instant replacement at any EcoFone retail hub',
            color: _forestGreen,
          ),
          const Divider(height: 20, thickness: 0.5),

          _buildChecklistRow(
            icon: Icons.checklist_rtl_rounded,
            title: '32-Point Hardware & Software Diagnostics Passed',
            subtitle: 'Display, Face ID/Touch ID, Cameras, Audio, Motherboard 100% Verified',
            color: _copper,
          ),
          const Divider(height: 20, thickness: 0.5),

          _buildChecklistRow(
            icon: Icons.inventory_2_outlined,
            title: 'In the Box',
            subtitle: 'Certified Phone, Fast USB-C Cable, Warranty Pass & GST Bill',
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _forestGreen.withOpacity(0.65),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- E. Store Availability Card ---
  Widget _buildStoreAvailabilityCard(EcoStore selectedStore, double distanceKm) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.storefront_rounded, color: _forestGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Available at Retail Hub',
                    style: TextStyle(
                      color: _forestGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => LocationSelectorSheet.show(context),
                child: const Text(
                  'Switch Store',
                  style: TextStyle(
                    color: _copper,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStore.name,
                  style: const TextStyle(
                    color: _forestGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  selectedStore.address,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.pin_drop_rounded, size: 14, color: _copper),
                    const SizedBox(width: 4),
                    Text(
                      '$distanceKm km from your location',
                      style: const TextStyle(
                        color: _copper,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => StoreDirectionsSheet.show(context, selectedStore),
                      child: const Row(
                        children: [
                          Icon(Icons.directions_rounded, size: 14, color: _forestGreen),
                          SizedBox(width: 2),
                          Text(
                            'Get Route',
                            style: TextStyle(
                              color: _forestGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- F. "Similar Refurbished Phones" (Fluid in-place switcher) ---
  Widget _buildSimilarPhonesSection() {
    final similar = _similarPhones;
    if (similar.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Similar Refurbished Phones',
                  style: TextStyle(
                    color: _forestGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${similar.length} Deals',
                  style: TextStyle(
                    color: _forestGreen.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: similar.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final otherPhone = similar[index];
                return _buildSimilarPhoneCard(otherPhone);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarPhoneCard(PhoneStockItem phone) {
    return BouncingWidget(
      scaleFactor: 0.96,
      onTap: () {
        _switchToPhone(phone);
        if (widget.scrollController?.hasClients ?? false) {
          widget.scrollController?.animateTo(
            0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      },
      onLongPress: () {
        Phone3DPopShowcase.show(
          context,
          phone,
          allPhones: widget.allPhones,
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Center(
                child: MiniPhoneThumbnail(
                  brand: phone.brand,
                  colorName: phone.color,
                  batteryHealth: phone.batteryHealth,
                  realImageUrl: phone.imageUrl,
                  width: 55,
                  height: 95,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              phone.name,
              style: const TextStyle(
                color: _forestGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${phone.storage} • ${phone.color}',
              style: TextStyle(
                color: _forestGreen.withOpacity(0.65),
                fontSize: 10.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Price
            Row(
              children: [
                Flexible(
                  child: Text(
                    _formatPrice(phone.refurbishedPrice),
                    style: const TextStyle(
                      color: _forestGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${phone.savingsPercent}%',
                  style: const TextStyle(
                    color: _softGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Sticky Bottom Action Bar ---
  Widget _buildStickyBottomBar(EcoStore selectedStore) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _openWhatsAppInquiry(selectedStore);
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: _copper, size: 18),
            label: const Text('Inquire'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _copper,
              side: const BorderSide(color: _copper),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LuxuryShimmerSweep(
              interval: const Duration(seconds: 4),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showCheckoutBottomSheet(selectedStore);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18, color: EcoColors.brightAmber),
                    const SizedBox(width: 6),
                    Text(
                      'Buy Now • ${_formatPrice(_calculatedRefurbishedPrice)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openWhatsAppInquiry(EcoStore store) async {
    final message = 'Hi EcoFone Support, I am interested in buying ${_currentPhone.name} ($_selectedStorage, $_selectedColor) priced at ${_formatPrice(_calculatedRefurbishedPrice)}. Is it in stock for immediate order?';
    final encoded = Uri.encodeComponent(message);
    final rawPhone = store.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final target = rawPhone.length == 10 ? '91$rawPhone' : rawPhone;
    final uri = Uri.parse('https://wa.me/$target?text=$encoded');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Clipboard.setData(ClipboardData(text: store.phone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Store Phone copied: ${store.phone}')),
        );
      }
    }
  }

  /// Modern E-Commerce Checkout Sheet (Cashify & Flipkart Standard Flow)
  void _showCheckoutBottomSheet(EcoStore selectedStore) {
    final initialPhone = AppState.instance.userPhone ?? '';
    final cleanPhone = initialPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigit = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;
    final nameController = TextEditingController(text: AppState.instance.userName ?? '');
    final phoneController = TextEditingController(text: tenDigit);
    final addressController = TextEditingController(
      text: AppState.instance.userLocation.city.isNotEmpty
          ? '${AppState.instance.userLocation.city}, Uttar Pradesh'
          : '',
    );
    final pincodeController = TextEditingController(text: AppState.instance.userLocation.pincode);

    String deliveryOption = 'Doorstep Delivery'; // 'Doorstep Delivery' or 'Store Pickup'
    String paymentMethod = 'Cash on Delivery'; // 'Cash on Delivery', 'Instant UPI', 'Card / NetBanking'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Checkout',
                                style: TextStyle(
                                  color: _forestGreen,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_currentPhone.name} ($_selectedStorage, $_selectedColor)',
                                style: TextStyle(
                                  color: _forestGreen.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 1. Delivery / Pickup Toggle Selector
                    const Text(
                      'Fulfillment Method',
                      style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() => deliveryOption = 'Doorstep Delivery');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: deliveryOption == 'Doorstep Delivery'
                                    ? _forestGreen.withOpacity(0.08)
                                    : EcoColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: deliveryOption == 'Doorstep Delivery'
                                      ? _forestGreen
                                      : Colors.black.withOpacity(0.08),
                                  width: deliveryOption == 'Doorstep Delivery' ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 20,
                                    color: deliveryOption == 'Doorstep Delivery' ? _forestGreen : Colors.grey,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Doorstep Delivery',
                                    style: TextStyle(
                                      color: deliveryOption == 'Doorstep Delivery' ? _forestGreen : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const Text(
                                    '⚡ Free (24-48 hrs)',
                                    style: TextStyle(color: EcoColors.mintGreen, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() => deliveryOption = 'Store Pickup');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: deliveryOption == 'Store Pickup'
                                    ? _forestGreen.withOpacity(0.08)
                                    : EcoColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: deliveryOption == 'Store Pickup'
                                      ? _forestGreen
                                      : Colors.black.withOpacity(0.08),
                                  width: deliveryOption == 'Store Pickup' ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.storefront_outlined,
                                    size: 20,
                                    color: deliveryOption == 'Store Pickup' ? _forestGreen : Colors.grey,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Store Pickup',
                                    style: TextStyle(
                                      color: deliveryOption == 'Store Pickup' ? _forestGreen : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const Text(
                                    'Ready in 2 hrs',
                                    style: TextStyle(color: _copper, fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 2. Address / Store details section
                    if (deliveryOption == 'Doorstep Delivery') ...[
                      const Text(
                        'Delivery Address & Pincode',
                        style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: addressController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Flat / House / Street Address',
                          hintText: 'e.g. Flat 302, Green Park Avenue',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.home_outlined, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pincodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Delivery Pincode',
                          counterText: '',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ] else ...[
                      // Store Pickup Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _forestGreen.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _forestGreen.withOpacity(0.12)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded, color: _forestGreen, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${selectedStore.name} • ${selectedStore.city}',
                                    style: const TextStyle(
                                      color: _forestGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    selectedStore.address,
                                    style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 10.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(modalCtx);
                                LocationSelectorSheet.show(context);
                              },
                              child: const Text(
                                'Switch',
                                style: TextStyle(
                                  color: _copper,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 3. Customer Info (Name & Phone)
                    const Text(
                      'Contact Information',
                      style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Your Full Name',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: '10-Digit Mobile Number',
                        counterText: '',
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _forestGreen),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Payment Method
                    const Text(
                      'Payment Method',
                      style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: [
                        _buildPaymentTile(
                          icon: Icons.payments_outlined,
                          title: 'Cash on Delivery (Pay after device inspection)',
                          selected: paymentMethod == 'Cash on Delivery',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModalState(() => paymentMethod = 'Cash on Delivery');
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildPaymentTile(
                          icon: Icons.qr_code_2_rounded,
                          title: 'Instant UPI (Google Pay, PhonePe, Paytm)',
                          selected: paymentMethod == 'Instant UPI',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModalState(() => paymentMethod = 'Instant UPI');
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildPaymentTile(
                          icon: Icons.credit_card_outlined,
                          title: 'Credit / Debit Card / NetBanking',
                          selected: paymentMethod == 'Card / NetBanking',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModalState(() => paymentMethod = 'Card / NetBanking');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 5. Price & Savings Breakdown Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: EcoColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Device Refurbished Price', style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 12)),
                              Text(_formatPrice(_calculatedRefurbishedPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('6-Month Warranty', style: TextStyle(color: EcoColors.mintGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('FREE (₹1,999)', style: TextStyle(color: EcoColors.mintGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Express Delivery & Packaging', style: TextStyle(color: EcoColors.mintGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('FREE', style: TextStyle(color: EcoColors.mintGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 14, thickness: 0.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(color: _forestGreen, fontWeight: FontWeight.w900, fontSize: 14)),
                              Text(
                                _formatPrice(_calculatedRefurbishedPrice),
                                style: const TextStyle(color: _forestGreen, fontWeight: FontWeight.w900, fontSize: 17),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Order CTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final customerName = nameController.text.trim().isEmpty
                              ? (AppState.instance.userName ?? 'Valued Customer')
                              : nameController.text.trim();
                          final rawDigits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

                          if (rawDigits.length < 10) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
                            );
                            return;
                          }

                          if (deliveryOption == 'Doorstep Delivery' && addressController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter your delivery address')),
                            );
                            return;
                          }

                          final tenDigitPhone = rawDigits.length >= 10 ? rawDigits.substring(rawDigits.length - 10) : rawDigits;
                          final formattedPhone = '+91 $tenDigitPhone';
                          final orderId = 'ECO-ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

                          final fullAddress = deliveryOption == 'Doorstep Delivery'
                              ? '${addressController.text.trim()} ${pincodeController.text.trim().isNotEmpty ? '- ${pincodeController.text.trim()}' : ''}'
                              : '${selectedStore.name}, ${selectedStore.address}';

                          final initialOrder = PhoneOrder(
                            orderId: orderId,
                            phoneId: _currentPhone.id,
                            phoneName: _currentPhone.name,
                            brand: _currentPhone.brand,
                            storage: _selectedStorage,
                            color: _selectedColor,
                            price: _calculatedRefurbishedPrice,
                            conditionGrade: _currentPhone.conditionGrade,
                            imageUrl: _currentPhone.imageUrl,
                            icon: _currentPhone.icon,
                            deliveryOption: deliveryOption,
                            deliveryAddress: fullAddress,
                            customerCity: selectedStore.city,
                            customerPincode: pincodeController.text.trim().isNotEmpty ? pincodeController.text.trim() : selectedStore.pincode,
                            paymentMethod: paymentMethod,
                            paymentStatus: paymentMethod == 'Cash on Delivery' ? 'Pay on Delivery' : 'Paid Online',
                            orderStatus: 'CONFIRMED',
                            storeId: selectedStore.id,
                            storeName: selectedStore.name,
                            storeAddress: selectedStore.address,
                            storePhone: selectedStore.phone,
                            storeMapsUrl: selectedStore.googleMapsUrl,
                            customerName: customerName,
                            customerPhone: formattedPhone,
                            createdAt: DateTime.now(),
                          );

                          PhoneOrder finalOrder = initialOrder;
                          final isOnline = paymentMethod != 'Cash on Delivery';

                          if (isOnline) {
                            // POS Integration: Simulate/process Razorpay checkout and allocate serialized IMEI from POS
                            final rzpService = RazorpayCheckoutService();
                            final rzpResult = rzpService.generateMockPaymentSuccess();
                            final paymentId = rzpResult['razorpay_payment_id']!;
                            final rzpOrderId = rzpResult['razorpay_order_id']!;

                            finalOrder = await AppState.instance.placeOnlineOrder(
                              order: initialOrder.copyWith(
                                paymentMethod: 'Online Razorpay ($paymentMethod)',
                                paymentStatus: 'Paid Online • Verified',
                              ),
                              razorpayPaymentId: paymentId,
                              razorpayOrderId: rzpOrderId,
                            );
                          } else {
                            AppState.instance.placeOrder(initialOrder);
                          }

                          if (!AppState.instance.isLoggedIn) {
                            AppState.instance.login(name: customerName, phone: formattedPhone);
                          }

                          if (!context.mounted) return;
                          Navigator.pop(modalCtx);
                          _showOrderSuccessDialog(finalOrder);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: EcoColors.brightAmber, size: 19),
                            const SizedBox(width: 6),
                            Text(
                              'Confirm Order • ${_formatPrice(_calculatedRefurbishedPrice)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentTile({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _forestGreen.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _forestGreen : Colors.black.withOpacity(0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? _forestGreen : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? _forestGreen : Colors.black87,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: _forestGreen, size: 16),
          ],
        ),
      ),
    );
  }


  void _showOrderSuccessDialog(PhoneOrder order) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _softGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: _softGreen, size: 44),
            ),
            const SizedBox(height: 12),
            const Text(
              'Order Placed Successfully! 🎉',
              style: TextStyle(
                color: _forestGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: EcoColors.brightAmber.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ORDER ID: #${order.orderId}',
                style: const TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EcoColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 ${order.phoneName} (${order.storage}, ${order.color})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _forestGreen),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📦 Fulfillment: ${order.deliveryOption}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '💳 Payment: ${order.paymentMethod} (${order.paymentStatus})',
                    style: const TextStyle(fontSize: 11, color: _copper, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '📍 Address: ${order.deliveryAddress}',
                    style: TextStyle(fontSize: 10.5, color: Colors.black.withOpacity(0.6)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              order.deliveryOption == 'Doorstep Delivery'
                  ? 'Your order is confirmed! Our courier partner will deliver within 24-48 hours.'
                  : 'Ready for pickup in 2 hours at ${order.storeName}. Show your Order ID at the counter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _forestGreen.withOpacity(0.7), fontSize: 11.5, height: 1.3),
            ),
            if (order.invoiceNumber != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _forestGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _forestGreen.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TAX INVOICE', style: TextStyle(color: _forestGreen, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        Text(order.invoiceNumber!, style: const TextStyle(color: _forestGreen, fontWeight: FontWeight.w900, fontSize: 12)),
                      ],
                    ),
                    if (order.imei1 != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('ALLOCATED IMEI', style: TextStyle(color: Colors.black54, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          Text(order.imei1!, style: const TextStyle(color: _copper, fontWeight: FontWeight.w800, fontSize: 11)),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    PosInvoiceSheet.show(context, invoiceNumber: order.invoiceNumber!, order: order);
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white),
                  label: const Text('View Tax Invoice & Warranty Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (order.deliveryOption == 'Store Pickup') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        final store = AppState.allStores.firstWhere(
                          (s) => s.id == order.storeId,
                          orElse: () => AppState.instance.selectedStore,
                        );
                        StoreDirectionsSheet.show(context, store);
                      },
                      icon: const Icon(Icons.directions_rounded, size: 15, color: _forestGreen),
                      label: const Text('Store Route', style: TextStyle(fontSize: 11.5, color: _forestGreen, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _forestGreen.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _forestGreen,
                      side: BorderSide(color: _forestGreen.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Continue Shopping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

/// Animated floating & pulsing Up/Down arrow pill on top edge of the sheet
class _BlinkingUpArrowPill extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _BlinkingUpArrowPill({
    Key? key,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_BlinkingUpArrowPill> createState() => _BlinkingUpArrowPillState();
}

class _BlinkingUpArrowPillState extends State<_BlinkingUpArrowPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _translateAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.55, end: 1.0).animate(
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
    const Color activeColor = Color(0xFF059669); // Emerald Mint Green

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, widget.isExpanded ? 0 : _translateAnimation.value),
                child: Opacity(
                  opacity: widget.isExpanded ? 0.85 : _opacityAnimation.value,
                  child: Icon(
                    widget.isExpanded
                        ? Icons.keyboard_double_arrow_down_rounded
                        : Icons.keyboard_double_arrow_up_rounded,
                    size: 26,
                    color: activeColor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
