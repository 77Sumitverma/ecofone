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

  const _WishlistItem({
    required this.id,
    required this.name,
    required this.condition,
    required this.price,
    required this.originalPrice,
    required this.icon,
    required this.stockStatus,
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
    if (mounted) setState(() {});
  }

  static const List<_WishlistItem> _catalog = [
    _WishlistItem(
      id: 'EF-101',
      name: 'iPhone 14 Pro (128 GB)',
      condition: 'Superb (Pristine)',
      price: 76999,
      originalPrice: 129900,
      icon: Icons.phone_iphone_rounded,
      stockStatus: 'Only 2 units remaining',
    ),
    _WishlistItem(
      id: 'EF-102',
      name: 'Galaxy S23 Ultra (256 GB)',
      condition: 'Superb (Pristine)',
      price: 74999,
      originalPrice: 124999,
      icon: Icons.smartphone_rounded,
      stockStatus: 'In Stock',
    ),
    _WishlistItem(
      id: 'EF-103',
      name: 'OnePlus 11 5G (128 GB)',
      condition: 'Very Good Grade',
      price: 36999,
      originalPrice: 56999,
      icon: Icons.smartphone_rounded,
      stockStatus: 'In Stock',
    ),
    _WishlistItem(
      id: 'EF-104',
      name: 'Google Pixel 7 Pro (128 GB)',
      condition: 'Superb Grade',
      price: 38999,
      originalPrice: 84999,
      icon: Icons.smartphone_rounded,
      stockStatus: 'Only 1 unit remaining',
    ),
    _WishlistItem(
      id: 'EF-105',
      name: 'iPhone 13 (128 GB)',
      condition: 'Very Good Grade',
      price: 41999,
      originalPrice: 69900,
      icon: Icons.phone_iphone_rounded,
      stockStatus: 'In Stock',
    ),
    _WishlistItem(
      id: 'EF-106',
      name: 'OnePlus Nord CE 3 (128 GB)',
      condition: 'Good Grade',
      price: 11999,
      originalPrice: 19999,
      icon: Icons.smartphone_rounded,
      stockStatus: '3 units remaining',
    ),
  ];

  List<_WishlistItem> get _items {
    return _catalog
        .where((item) => AppState.instance.wishlistedIds.contains(item.id))
        .toList();
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
    final phone = PhoneStockItem.sampleInventory.firstWhere(
      (p) => p.id == item.id || item.name.toLowerCase().contains(p.name.toLowerCase()),
      orElse: () => PhoneStockItem.sampleInventory.first,
    );

    return BouncingWidget(
      scaleFactor: 0.97,
      onTap: () {
        PhoneDetailSheet.show(
          context,
          phone,
          allPhones: PhoneStockItem.sampleInventory,
        );
      },
      onLongPress: () {
        Phone3DPopShowcase.show(
          context,
          phone,
          allPhones: PhoneStockItem.sampleInventory,
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
                    Row(
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
    final selectedStore = AppState.instance.selectedStore;
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
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            final rawDigits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
                            if (rawDigits.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
                              );
                              return;
                            }

                            if (deliveryOption == 'Doorstep Delivery' && addressController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter your delivery address')),
                              );
                              return;
                            }

                            final cName = nameController.text.trim().isEmpty
                                ? (AppState.instance.userName ?? 'Valued Customer')
                                : nameController.text.trim();
                            final tenDigit = rawDigits.length >= 10 ? rawDigits.substring(rawDigits.length - 10) : rawDigits;
                            final cPhone = '+91 $tenDigit';

                            if (!AppState.instance.isLoggedIn) {
                              AppState.instance.login(
                                name: cName,
                                phone: cPhone,
                              );
                            }

                            String brand = 'Apple';
                            final lowerName = item.name.toLowerCase();
                            if (lowerName.contains('galaxy') || lowerName.contains('samsung')) {
                              brand = 'Samsung';
                            } else if (lowerName.contains('oneplus')) {
                              brand = 'OnePlus';
                            } else if (lowerName.contains('pixel') || lowerName.contains('google')) {
                              brand = 'Google';
                            }

                            final fullAddress = deliveryOption == 'Doorstep Delivery'
                                ? '${addressController.text.trim()} ${pincodeController.text.trim().isNotEmpty ? '- ${pincodeController.text.trim()}' : ''}'
                                : '${selectedStore.name}, ${selectedStore.address}';

                            final order = PhoneOrder(
                              orderId: 'ECO-ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                              phoneId: item.id,
                              phoneName: item.name,
                              brand: brand,
                              storage: '128 GB',
                              color: 'Space Black',
                              price: item.price,
                              conditionGrade: item.condition,
                              icon: item.icon,
                              deliveryOption: deliveryOption,
                              deliveryAddress: fullAddress,
                              paymentMethod: paymentMethod,
                              paymentStatus: paymentMethod == 'Cash on Delivery' ? 'Pay on Delivery' : 'Paid Online',
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

                            AppState.instance.placeOrder(order);

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
                            'Confirm Order • ${_formatPrice(item.price)}',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
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
