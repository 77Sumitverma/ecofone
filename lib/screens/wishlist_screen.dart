import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/brand_logo.dart';
import 'package:ecofone/core/widgets/phone_3d_pop_showcase.dart';
import 'package:ecofone/core/widgets/smartphone_preview_widget.dart';
import 'package:ecofone/screens/location_sheet.dart';
import 'package:ecofone/screens/phone_detail_screen.dart';
import 'package:ecofone/state/app_state.dart';
import 'package:ecofone/core/widgets/pos_invoice_sheet.dart';
import 'package:ecofone/core/widgets/saved_checkout_suggestion_card.dart';
import 'package:ecofone/services/network/connectivity_service.dart';


class WishlistScreen extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const WishlistScreen({super.key, this.onExploreTap});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistItem {
  final String id;
  final String name;
  final String condition;
  final int price;
  final int originalPrice;
  final IconData icon;
  final String stockStatus;
  final PhoneStockItem phone;

  const _WishlistItem({
    required this.id,
    required this.name,
    required this.condition,
    required this.price,
    required this.originalPrice,
    required this.icon,
    required this.stockStatus,
    required this.phone,
  });
}

class _WishlistScreenState extends State<WishlistScreen> {
  static const _bgColor = EcoColors.background;
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;
  static const _softGreen = EcoColors.mintGreen;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  List<_WishlistItem> get _items {
    final allPhones = <PhoneStockItem>[
      ...AppState.instance.liveInventory,
      ...PhoneStockItem.sampleInventory,
    ];

    final matched = <_WishlistItem>[];
    final seen = <String>{};

    for (final id in AppState.instance.wishlistedIds) {
      if (seen.contains(id)) continue;

      // 1. Try to find by id or sku in live/sample inventory
      PhoneStockItem? phone;
      for (final p in allPhones) {
        if (p.id == id || p.sku == id) {
          phone = p;
          break;
        }
      }

      // 2. Fallback to sample inventory by name match
      if (phone == null) {
        for (final p in PhoneStockItem.sampleInventory) {
          if (p.id == id || p.name.toLowerCase() == id.toLowerCase()) {
            phone = p;
            break;
          }
        }
      }

      // 3. Fallback generic PhoneStockItem if ID unknown
      phone ??= PhoneStockItem(
        id: id,
        name: 'EcoFone Certified Device',
        brand: 'Apple',
        storage: '128 GB',
        color: 'Default',
        batteryHealth: 95,
        conditionGrade: 'Superb',
        gradeDescription: 'Certified Refurbished',
        refurbishedPrice: 39999,
        originalPrice: 69999,
        stockQuantity: 1,
        icon: Icons.smartphone_rounded,
        highlights: const ['6-Month Warranty'],
      );

      seen.add(id);
      matched.add(_WishlistItem(
        id: id,
        name: phone.name.contains('(') ? phone.name : '${phone.brand} ${phone.name} (${phone.storage})',
        condition: phone.conditionGrade,
        price: phone.refurbishedPrice,
        originalPrice: phone.originalPrice,
        icon: phone.icon,
        stockStatus: phone.stockQuantity > 0
            ? (phone.stockQuantity <= 2 ? 'Only ${phone.stockQuantity} remaining' : 'In Stock')
            : 'Available on Order',
        phone: phone,
      ));
    }
    return matched;
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

  void _removeItem(int index) {
    HapticFeedback.lightImpact();
    final removed = _items[index];
    AppState.instance.toggleWishlist(removed.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.name} removed from wishlist'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: _copper,
          onPressed: () {
            HapticFeedback.lightImpact();
            AppState.instance.toggleWishlist(removed.id);
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: EcoColors.vibrantOrange,
          backgroundColor: Colors.white,
          displacement: 28,
          strokeWidth: 2.4,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            setState(() => _isLoading = true);
            await Future.delayed(const Duration(milliseconds: 650));
            if (mounted) setState(() => _isLoading = false);
          },
          child: _isLoading
              ? _buildSkeletonContent()
              : (_items.isEmpty ? _buildEmptyState() : _buildWishlistContent()),
        ),
      ),
    );
  }

  Widget _buildSkeletonContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                EcoSkeletonShimmer(child: EcoSkeletonBox(width: 170, height: 26, borderRadius: 8)),
                EcoSkeletonShimmer(child: EcoSkeletonBox(width: 50, height: 18, borderRadius: 6)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: WishlistCardSkeleton(),
              ),
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: EcoFoneHeaderLogo(
                    emblemSize: 42,
                    titleSize: 22,
                    subtitleSize: 10.5,
                    customSubtitle: 'Wishlist (${_items.length} items) • Luxury within reach',
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    for (final item in _items.toList()) {
                      AppState.instance.toggleWishlist(item.id);
                    }
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _items[index];
                return FadeSlideEntry(
                  delayMs: (index * 50).clamp(0, 300),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildItemCard(item, index),
                  ),
                );
              },
              childCount: _items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _forestGreen.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _forestGreen.withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: _forestGreen, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EcoFone 6-Month Warranty Included',
                          style: TextStyle(
                            color: _forestGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Every device on your wishlist passes rigorous quality checks and comes with 7-day replacement.',
                          style: TextStyle(
                            color: _forestGreen,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(_WishlistItem item, int index) {
    final phone = item.phone;
    final allInventory = AppState.instance.liveInventory.isNotEmpty
        ? AppState.instance.liveInventory
        : PhoneStockItem.sampleInventory;

    return BouncingWidget(
      scaleFactor: 0.97,
      onTap: () {
        PhoneDetailSheet.show(
          context,
          phone,
          allPhones: allInventory,
        );
      },
      onLongPress: () {
        Phone3DPopShowcase.show(
          context,
          phone,
          allPhones: allInventory,
          isWishlisted: true,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vector Phone Mockup Thumbnail
          Container(
            width: 76,
            height: 90,
            decoration: BoxDecoration(
              color: _forestGreen.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: MiniPhoneThumbnail(
                brand: phone.brand,
                colorName: phone.color,
                batteryHealth: phone.batteryHealth,
                realImageUrl: phone.imageUrl,
                width: 58,
                height: 82,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _softGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.condition,
                        style: const TextStyle(
                          color: _softGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeItem(index),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: const TextStyle(
                    color: _forestGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  item.stockStatus,
                  style: const TextStyle(
                    color: _copper,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatPrice(item.price),
                              style: const TextStyle(
                                color: _copper,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatPrice(item.originalPrice),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    LuxuryShimmerSweep(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showPhoneCheckoutModal(item);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _forestGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 14, color: EcoColors.brightAmber),
                            SizedBox(width: 4),
                            Text(
                              'Buy Now',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ],
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
    );
  }

  void _showPhoneCheckoutModal(_WishlistItem item) {
    int currentStep = AppState.instance.isLoggedIn ? 2 : 1;
    bool otpSent = false;
    bool isSendingOtp = false;
    bool isVerifyingOtp = false;
    String? phoneLoginError;
    String? activeDynamicOtp;
    int resendCountdown = 30;
    Timer? resendTimer;

    final phoneLoginCtrl = TextEditingController();
    final otpLoginCtrl = TextEditingController();

    void startResendTimer(void Function(void Function()) setModalState) {
      resendTimer?.cancel();
      resendCountdown = 30;
      resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (resendCountdown <= 1) {
          timer.cancel();
          setModalState(() {
            resendCountdown = 0;
          });
        } else {
          setModalState(() {
            resendCountdown--;
          });
        }
      });
    }

    final selectedStore = AppState.instance.selectedStore;
    final initialPhone = AppState.instance.userPhone ?? '';
    final cleanPhone = initialPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigit = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;
    var savedSuggestion = AppState.instance.getSavedCheckoutDetails();
    bool savedSuggestionApplied = false;
    final nameController = TextEditingController();
    final phoneController = TextEditingController(text: tenDigit);
    final addressController = TextEditingController();
    final pincodeController = TextEditingController(
      text: (savedSuggestion != null && savedSuggestion.pincode.isNotEmpty)
          ? savedSuggestion.pincode
          : AppState.instance.userLocation.pincode,
    );

    String deliveryOption = 'Doorstep Delivery';
    String paymentMethod = 'Cash on Delivery';

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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buy ${item.name}',
                                style: const TextStyle(
                                  color: _forestGreen,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatPrice(item.price)} • 6-Month Warranty & Free Delivery',
                                style: const TextStyle(color: _copper, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // STEP 1: MOBILE LOGIN VIA OTP (When user is not logged in)
                    if (currentStep == 1) ...[
                      if (!otpSent) ...[
                        TextField(
                          controller: phoneLoginCtrl,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          onChanged: (val) {
                            if (phoneLoginError != null) {
                              setModalState(() => phoneLoginError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: '10-Digit Mobile Number *',
                            hintText: '98765 43210',
                            counterText: '',
                            errorText: phoneLoginError,
                            prefixText: '+91 ',
                            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _forestGreen),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.phone_iphone_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSendingOtp
                                ? null
                                : () async {
                                    final clean = phoneLoginCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
                                    final isValidIndianNumber = RegExp(r'^[6-9]\d{9}$').hasMatch(clean);

                                    if (!isValidIndianNumber) {
                                      setModalState(() {
                                        phoneLoginError = 'Enter a valid 10-digit mobile (starts with 6, 7, 8, or 9)';
                                      });
                                      return;
                                    }

                                    setModalState(() {
                                      isSendingOtp = true;
                                      phoneLoginError = null;
                                    });

                                    await AppState.instance.sendOtp(clean);
                                    if (!modalCtx.mounted) return;

                                    final generated = AppState.instance.backend?.getActiveOtp(clean) ?? '123456';
                                    setModalState(() {
                                      isSendingOtp = false;
                                      otpSent = true;
                                      activeDynamicOtp = generated;
                                    });
                                    startResendTimer(setModalState);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSendingOtp
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Send Verification OTP',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                          ),
                        ),
                      ] else ...[
                        if (activeDynamicOtp != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F3B28), Color(0xFF16543A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.key_rounded, size: 18, color: EcoColors.brightAmber),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Dynamic In-App OTP',
                                        style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                      ),
                                      Text(
                                        activeDynamicOtp!,
                                        style: const TextStyle(
                                          color: EcoColors.brightAmber,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                BouncingWidget(
                                  scaleFactor: 0.92,
                                  onTap: () {
                                    setModalState(() {
                                      otpLoginCtrl.text = activeDynamicOtp!;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: EcoColors.brightAmber,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt_rounded, size: 14, color: _forestGreen),
                                        SizedBox(width: 3),
                                        Text(
                                          'Auto-fill',
                                          style: TextStyle(
                                            color: _forestGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        TextField(
                          controller: otpLoginCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            color: _forestGreen,
                          ),
                          decoration: InputDecoration(
                            labelText: '6-digit SMS OTP',
                            counterText: '',
                            hintText: '• • • • • •',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                resendTimer?.cancel();
                                setModalState(() {
                                  otpSent = false;
                                  otpLoginCtrl.clear();
                                });
                              },
                              icon: const Icon(Icons.arrow_back_rounded, size: 14),
                              label: const Text('Change Number', style: TextStyle(fontSize: 12)),
                            ),
                            if (resendCountdown > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Resend in ${resendCountdown}s',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: () async {
                                  final clean = phoneLoginCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
                                  await AppState.instance.sendOtp(clean);
                                  final newOtp = AppState.instance.backend?.getActiveOtp(clean) ?? '123456';
                                  setModalState(() {
                                    activeDynamicOtp = newOtp;
                                  });
                                  startResendTimer(setModalState);
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 14, color: _copper),
                                label: const Text('Resend Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _copper)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isVerifyingOtp
                                ? null
                                : () async {
                                    final enteredOtp = otpLoginCtrl.text.trim();
                                    if (enteredOtp.length < 4) {
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter the 6-digit SMS OTP')),
                                      );
                                      return;
                                    }

                                    setModalState(() => isVerifyingOtp = true);
                                    final clean = phoneLoginCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

                                    final profile = await AppState.instance.verifyOtpAndLogin(
                                      phone: clean,
                                      otp: enteredOtp,
                                    );

                                    if (profile == null) {
                                      setModalState(() => isVerifyingOtp = false);
                                      if (!modalCtx.mounted) return;
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.redAccent,
                                          content: Text('❌ Invalid OTP. Tap Auto-fill or enter correct code.'),
                                        ),
                                      );
                                      return;
                                    }

                                    resendTimer?.cancel();

                                    // Successfully logged in! Load any saved profile suggestion & advance to Order Checkout!
                                    phoneController.text = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
                                    final refreshedSuggestion = AppState.instance.getSavedCheckoutDetails();
                                    nameController.clear();
                                    addressController.clear();
                                    if (refreshedSuggestion != null && refreshedSuggestion.pincode.isNotEmpty) {
                                      pincodeController.text = refreshedSuggestion.pincode;
                                    }

                                    setModalState(() {
                                      isVerifyingOtp = false;
                                      savedSuggestion = refreshedSuggestion;
                                      savedSuggestionApplied = false;
                                      currentStep = 2;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isVerifyingOtp
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Verify & Proceed to Address',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                          ),
                        ),
                      ],
                    ]
                    // STEP 2: ADDRESS & ORDER CHECKOUT
                    else ...[
                      SavedCheckoutSuggestionCard(
                        savedDetails: savedSuggestion,
                        isApplied: savedSuggestionApplied,
                        onApplySaved: () {
                          final details = savedSuggestion;
                          if (details == null) return;
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            if (details.name.isNotEmpty) {
                              nameController.text = details.name;
                            }
                            if (details.address.isNotEmpty) {
                              addressController.text = details.address;
                            }
                            if (details.pincode.isNotEmpty) {
                              pincodeController.text = details.pincode;
                            }
                            savedSuggestionApplied = true;
                          });
                        },
                        onEnterNew: () {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            nameController.clear();
                            addressController.clear();
                            savedSuggestionApplied = false;
                          });
                        },
                      ),
                      // Fulfillment Selector
                      const Text('Fulfillment Method', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _forestGreen)),
                    const SizedBox(height: 6),
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
                                color: deliveryOption == 'Doorstep Delivery' ? _forestGreen.withOpacity(0.08) : EcoColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: deliveryOption == 'Doorstep Delivery' ? _forestGreen : Colors.black.withOpacity(0.08),
                                  width: deliveryOption == 'Doorstep Delivery' ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.local_shipping_outlined, size: 20, color: deliveryOption == 'Doorstep Delivery' ? _forestGreen : Colors.grey),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Doorstep Delivery',
                                    style: TextStyle(
                                      color: deliveryOption == 'Doorstep Delivery' ? _forestGreen : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const Text('⚡ Free (24-48 hrs)', style: TextStyle(color: EcoColors.mintGreen, fontSize: 10, fontWeight: FontWeight.w600)),
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
                                color: deliveryOption == 'Store Pickup' ? _forestGreen.withOpacity(0.08) : EcoColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: deliveryOption == 'Store Pickup' ? _forestGreen : Colors.black.withOpacity(0.08),
                                  width: deliveryOption == 'Store Pickup' ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.storefront_outlined, size: 20, color: deliveryOption == 'Store Pickup' ? _forestGreen : Colors.grey),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Store Pickup',
                                    style: TextStyle(
                                      color: deliveryOption == 'Store Pickup' ? _forestGreen : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const Text('Ready in 2 hrs', style: TextStyle(color: _copper, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (deliveryOption == 'Doorstep Delivery') ...[
                      TextField(
                        controller: addressController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Delivery Address',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.home_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pincodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Pincode',
                          counterText: '',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _forestGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded, color: _forestGreen, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${selectedStore.name} • ${selectedStore.city}',
                                style: const TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(modalCtx);
                                LocationSelectorSheet.show(context);
                              },
                              child: const Text('Switch', style: TextStyle(color: _copper, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Customer Name & Mobile
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Your Full Name',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.person_outline, size: 18),
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
                        prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment Method
                    const Text('Payment Method', style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Cash on Delivery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            selected: paymentMethod == 'Cash on Delivery',
                            selectedColor: _forestGreen,
                            labelStyle: TextStyle(color: paymentMethod == 'Cash on Delivery' ? Colors.white : _forestGreen),
                            onSelected: (_) => setModalState(() => paymentMethod = 'Cash on Delivery'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Instant UPI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            selected: paymentMethod == 'Instant UPI',
                            selectedColor: _forestGreen,
                            labelStyle: TextStyle(color: paymentMethod == 'Instant UPI' ? Colors.white : _forestGreen),
                            onSelected: (_) => setModalState(() => paymentMethod = 'Instant UPI'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Confirm Order CTA
                    LuxuryShimmerSweep(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final cName = nameController.text.trim();
                            if (cName.isEmpty || cName.length < 2) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your full name for delivery and GST invoice'),
                                  backgroundColor: _copper,
                                ),
                              );
                              return;
                            }

                            final rawDigits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
                            final tenDigit = rawDigits.length >= 10 ? rawDigits.substring(rawDigits.length - 10) : rawDigits;
                            if (tenDigit.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(tenDigit)) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid 10-digit Indian mobile number (starts with 6, 7, 8, or 9)'),
                                  backgroundColor: _copper,
                                ),
                              );
                              return;
                            }

                            if (deliveryOption == 'Doorstep Delivery') {
                              if (addressController.text.trim().length < 5) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter your full delivery address (House/Flat No., Street, Landmark)'),
                                    backgroundColor: _copper,
                                  ),
                                );
                                return;
                              }

                              final pin = pincodeController.text.trim();
                              if (pin.length != 6 || !RegExp(r'^[1-9]\d{5}$').hasMatch(pin)) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid 6-digit delivery pincode'),
                                    backgroundColor: _copper,
                                  ),
                                );
                                return;
                              }
                            }

                            final cPhone = '+91 $tenDigit';

                            if (!ConnectivityService.instance.isOnline) {
                              ConnectivityService.showNetworkErrorSnackBar(
                                context,
                                customMessage: 'No Internet Connection • Please connect to the internet to place your order',
                                onRetry: () => ConnectivityService.instance.checkNow(),
                              );
                              return;
                            }

                            if (!AppState.instance.isLoggedIn) {
                              AppState.instance.login(
                                name: cName,
                                phone: cPhone,
                              );
                            }

                            final fullAddress = deliveryOption == 'Doorstep Delivery'
                                ? '${addressController.text.trim()} ${pincodeController.text.trim().isNotEmpty ? '- ${pincodeController.text.trim()}' : ''}'
                                : '${selectedStore.name}, ${selectedStore.address}';

                            final initialOrder = PhoneOrder(
                              orderId: 'ECO-ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                              phoneId: item.phone.id,
                              phoneName: item.phone.name,
                              brand: item.phone.brand,
                              storage: item.phone.storage,
                              color: item.phone.color,
                              price: item.price,
                              conditionGrade: item.condition,
                              icon: item.icon,
                              imageUrl: item.phone.imageUrl,
                              deliveryOption: deliveryOption,
                              deliveryAddress: fullAddress,
                              paymentMethod: paymentMethod,
                              paymentStatus: paymentMethod == 'Cash on Delivery'
                                  ? 'Pay after Doorstep Inspection (COD)'
                                  : 'Paid Online • Verified',
                              orderStatus: 'CONFIRMED',
                              storeId: selectedStore.id,
                              storeName: selectedStore.name,
                              storeAddress: selectedStore.address,
                              storePhone: selectedStore.phone,
                              storeMapsUrl: selectedStore.googleMapsUrl,
                              customerName: cName,
                              customerPhone: cPhone,
                              createdAt: DateTime.now(),
                            );

                            final isOnline = paymentMethod != 'Cash on Delivery';
                            final paymentId = isOnline
                                ? 'pay_WISH_${DateTime.now().millisecondsSinceEpoch}'
                                : 'pay_COD_${DateTime.now().millisecondsSinceEpoch}';
                            final rzpOrderId = isOnline
                                ? 'order_WISH_${DateTime.now().millisecondsSinceEpoch}'
                                : 'order_COD_${DateTime.now().millisecondsSinceEpoch}';

                            final order = await AppState.instance.placeOnlineOrder(
                              order: initialOrder,
                              razorpayPaymentId: paymentId,
                              razorpayOrderId: rzpOrderId,
                            );

                            unawaited(AppState.instance.saveCheckoutProfileDetails(
                              name: cName,
                              phone: cPhone,
                              address: deliveryOption == 'Doorstep Delivery'
                                  ? addressController.text.trim()
                                  : (AppState.instance.userAddress ?? ''),
                              city: AppState.instance.userLocation.city.isNotEmpty
                                  ? AppState.instance.userLocation.city
                                  : selectedStore.city,
                              pincode: pincodeController.text.trim().isNotEmpty
                                  ? pincodeController.text.trim()
                                  : selectedStore.pincode,
                            ));

                            // Remove item from wishlist once ordered
                            AppState.instance.toggleWishlist(item.id);

                            if (!context.mounted) return;
                            Navigator.pop(modalCtx);

                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: _softGreen.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle_rounded, color: _forestGreen, size: 48),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Order Placed Successfully! 🎉',
                                      style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 17),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Order #${order.orderId}\n\nFulfillment: ${order.deliveryOption}\nTotal: ${_formatPrice(order.price)}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: _forestGreen.withOpacity(0.7), fontSize: 12),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(dialogCtx);
                                          PosInvoiceSheet.show(
                                            context,
                                            invoiceNumber: order.invoiceNumber ?? 'ECO-2026-000452',
                                            order: order,
                                          );
                                        },
                                        icon: const Icon(Icons.receipt_long_rounded, size: 15, color: Colors.white),
                                        label: const Text('View Official Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: ElevatedButton.styleFrom(backgroundColor: _forestGreen),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(dialogCtx),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _forestGreen,
                                          side: BorderSide(color: _forestGreen.withOpacity(0.3)),
                                        ),
                                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _forestGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Place Order • ${_formatPrice(item.price)}',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ], // End of STEP 2
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    resendTimer?.cancel();
  });
}


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _copper.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: _copper,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Wishlist is Empty',
              style: TextStyle(
                color: _forestGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your favorite certified refurbished smartphones and eco-tech accessories to buy later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _forestGreen.withOpacity(0.6),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            LuxuryShimmerSweep(
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onExploreTap?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Explore Devices',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
