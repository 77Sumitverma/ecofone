import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/brand_logo.dart';
import 'package:ecofone/screens/directions_sheet.dart';
import 'package:ecofone/screens/location_sheet.dart';
import 'package:ecofone/state/app_state.dart';
import 'package:ecofone/core/widgets/pos_invoice_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onTradeInTap;

  const ProfileScreen({super.key, this.onTradeInTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _bgColor = EcoColors.background;
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;

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

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AppState.instance.isLoggedIn;
    final orders = AppState.instance.orders;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Top App Bar
            _buildTopAppBar(),

            // 2. User Profile / Guest Card
            SliverToBoxAdapter(
              child: FadeSlideEntry(
                delayMs: 0,
                child: isLoggedIn ? _buildLoggedInHeaderCard() : _buildGuestHeaderCard(),
              ),
            ),

            // 3. Active Orders & Purchases (If any exist)
            if (isLoggedIn && orders.isNotEmpty)
              _buildOrdersSection(orders),

            // 4. Clean Grouped Menu & Actions
            SliverToBoxAdapter(
              child: FadeSlideEntry(
                delayMs: 60,
                child: _buildGroupedMenuSection(isLoggedIn),
              ),
            ),

            // 5. Minimal Footer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      'EcoFone • Luxury Re-Commerce Hub',
                      style: TextStyle(
                        color: _forestGreen.withOpacity(0.45),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0 • 100% Certified Devices',
                      style: TextStyle(
                        color: _forestGreen.withOpacity(0.35),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. TOP APP BAR
  // =========================================================================
  Widget _buildTopAppBar() {
    final activeStore = AppState.instance.selectedStore;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Profile',
              style: TextStyle(
                color: _forestGreen,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            BouncingWidget(
              scaleFactor: 0.94,
              onTap: () => LocationSelectorSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _forestGreen.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: _copper),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        activeStore.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _forestGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _forestGreen),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. HERO PROFILE CARD (LOGGED-IN)
  // =========================================================================
  Widget _buildLoggedInHeaderCard() {
    final name = AppState.instance.userName ?? 'Valued Customer';
    final phone = AppState.instance.userPhone ?? '';
    final email = AppState.instance.userEmail ?? '';
    final initials = _getInitials(name);
    final activeStore = AppState.instance.selectedStore;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3B28), Color(0xFF0A2B1D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F3B28).withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [EcoColors.brightAmber, EcoColors.vibrantOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: EcoColors.brightAmber.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0B2A1C),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: EcoColors.brightAmber,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.5,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, color: EcoColors.mintGreen, size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone.isNotEmpty ? phone : email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📍 ${activeStore.area.isNotEmpty ? activeStore.area : activeStore.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EcoColors.mintLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Edit button
            IconButton(
              onPressed: _showEditProfileModal,
              icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
              tooltip: 'Edit Profile',
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // GUEST HEADER CARD (WHEN LOGGED OUT)
  // =========================================================================
  Widget _buildGuestHeaderCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const EcoFoneFullLogo(size: 64, showTagline: false),
            const SizedBox(height: 10),
            const Text(
              'Welcome to EcoFone',
              style: TextStyle(
                color: _forestGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in with your mobile number to view orders, live delivery tracking & warranty passes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _forestGreen.withOpacity(0.6),
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            BouncingWidget(
              scaleFactor: 0.96,
              onTap: _showLoginModal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_forestGreen, EcoColors.darkEmerald],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _forestGreen.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, size: 18, color: EcoColors.brightAmber),
                    SizedBox(width: 6),
                    Text(
                      'Login / Sign Up with Mobile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
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

  // =========================================================================
  // 3. ORDERS SECTION (ACTIVE PURCHASES & ORDERS)
  // =========================================================================
  Widget _buildOrdersSection(List<PhoneOrder> orders) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_mall_outlined, color: _forestGreen, size: 17),
                    SizedBox(width: 6),
                    Text(
                      'My Orders & Purchases',
                      style: TextStyle(
                        color: _forestGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _forestGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${orders.length} ${orders.length == 1 ? 'Order' : 'Orders'}',
                    style: const TextStyle(
                      color: _forestGreen,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...orders.map((order) => _buildOrderCard(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(PhoneOrder order) {
    final isDelivery = order.deliveryOption == 'Doorstep Delivery';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Order Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: EcoColors.mintGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: _forestGreen, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        isDelivery ? 'EXPRESS SHIPPING • CONFIRMED' : 'READY FOR STORE PICKUP',
                        style: const TextStyle(
                          color: _forestGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showDigitalReceiptModal(order),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 14, color: _copper),
                      const SizedBox(width: 3),
                      Text(
                        '#${order.orderId}',
                        style: const TextStyle(
                          color: _copper,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Phone Overview Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _forestGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: order.imageUrl != null && order.imageUrl!.isNotEmpty
                      ? (order.imageUrl!.startsWith('assets/')
                          ? Image.asset(order.imageUrl!, fit: BoxFit.contain)
                          : Image.network(
                              order.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.phone_iphone_rounded, color: _forestGreen, size: 24),
                            ))
                      : const Icon(Icons.phone_iphone_rounded, color: _forestGreen, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.phoneName,
                        style: const TextStyle(
                          color: _forestGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${order.storage} • ${order.color} • Grade ${order.conditionGrade}',
                        style: TextStyle(
                          color: _forestGreen.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(order.price),
                      style: const TextStyle(
                        color: _copper,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      order.paymentStatus,
                      style: const TextStyle(color: EcoColors.mintGreen, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Perforated Divider
          CustomPaint(
            size: const Size(double.infinity, 12),
            painter: TicketDividerPainter(
              color: Colors.grey.shade200,
              cutoutColor: _bgColor,
            ),
          ),

          const SizedBox(height: 6),

          // 4. Delivery Address / Store Pickup Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isDelivery
                        ? '🚚 Delivery to: ${order.deliveryAddress}'
                        : '🏬 Pickup: ${order.storeName}',
                    style: TextStyle(
                      color: _forestGreen.withOpacity(0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 5. Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                if (!isDelivery) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => StoreDirectionsSheet.show(context, order.store),
                      icon: const Icon(Icons.directions_rounded, size: 13, color: _forestGreen),
                      label: const Text('Route', style: TextStyle(fontSize: 11, color: _forestGreen, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: BorderSide(color: _forestGreen.withOpacity(0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.storePhone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📞 Store phone copied: ${order.storePhone}'),
                            backgroundColor: _forestGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_rounded, size: 13, color: Colors.white),
                      label: const Text('Call Store', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _forestGreen,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showOrderTrackingDialog(order),
                      icon: const Icon(Icons.local_shipping_outlined, size: 13, color: _forestGreen),
                      label: const Text('Track Order', style: TextStyle(fontSize: 11, color: _forestGreen, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: BorderSide(color: _forestGreen.withOpacity(0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        PosInvoiceSheet.show(
                          context,
                          invoiceNumber: order.invoiceNumber ?? 'ECO-2026-000452',
                          order: order,
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 13, color: Colors.white),
                      label: const Text('Tax Invoice & Warranty', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _forestGreen,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDigitalReceiptModal(order),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: _copper),
                  tooltip: 'View Digital Receipt',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: () => _showCancelOrderDialog(order.orderId),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 17),
                  tooltip: 'Cancel Order',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderTrackingDialog(PhoneOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (trackCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Delivery Tracking',
                      style: TextStyle(
                        color: _forestGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order #${order.orderId}',
                      style: const TextStyle(color: _copper, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(trackCtx),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tracking Milestones
            _buildTrackingStep(
              title: 'Order Placed & Verified',
              subtitle: 'Order successfully confirmed with EcoFone Hub',
              isCompleted: true,
              isCurrent: false,
            ),
            _buildTrackingStep(
              title: '32-Point Quality Diagnostic Check',
              subtitle: 'Battery, display, cameras & hardware inspected & certified',
              isCompleted: true,
              isCurrent: false,
            ),
            _buildTrackingStep(
              title: 'Packed & Dispatched for Express Delivery',
              subtitle: 'Handed over to verified courier partner (Bluedart / Delhivery)',
              isCompleted: true,
              isCurrent: true,
            ),
            _buildTrackingStep(
              title: 'Out for Delivery',
              subtitle: 'Courier executive will arrive at your address',
              isCompleted: false,
              isCurrent: false,
            ),
            _buildTrackingStep(
              title: 'Delivered with 6-Month Warranty',
              subtitle: 'Physical device inspection & unboxing at your doorstep',
              isCompleted: false,
              isCurrent: false,
              isLast: true,
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EcoColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, color: _forestGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Delivery Address: ${order.deliveryAddress}',
                      style: const TextStyle(color: _forestGreen, fontSize: 11.5, fontWeight: FontWeight.w600),
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

  Widget _buildTrackingStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    final color = isCompleted ? _forestGreen : (isCurrent ? _copper : Colors.grey.shade400);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? _forestGreen : (isCurrent ? _copper : Colors.grey.shade200),
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check_rounded : (isCurrent ? Icons.circle : Icons.radio_button_unchecked_rounded),
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isCompleted ? _forestGreen : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 4. CLEAN GROUPED MENU SECTION
  // =========================================================================
  Widget _buildGroupedMenuSection(bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group 1: Store & Services
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.currency_exchange_rounded,
                  iconColor: _copper,
                  title: 'Sell Old Phone (Instant Cash)',
                  subtitle: '15-Minute instant UPI payout at store',
                  onTap: widget.onTradeInTap,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.storefront_rounded,
                  iconColor: _forestGreen,
                  title: 'EcoFone Retail Store Hubs',
                  subtitle: 'View 13 store locations, timings & map routes',
                  onTap: () => LocationSelectorSheet.show(context),
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF0284C7),
                  title: '6-Month Comprehensive Warranty',
                  subtitle: '100% cashless repair & replacement policy',
                  onTap: _showWarrantyDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Group 2: Help & Account Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.headset_mic_outlined,
                  iconColor: EcoColors.darkEmerald,
                  title: 'Store Hotline & Support',
                  subtitle: 'Direct manager contact & WhatsApp assistance',
                  onTap: _showSupportDialog,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: EcoColors.vibrantOrange,
                  title: 'App Tour & EcoFone Intro',
                  subtitle: 'View the 3-screen welcome onboarding',
                  onTap: () {
                    Navigator.of(context).pushNamed('/onboarding');
                  },
                ),
                if (isLoggedIn) ...[
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: _forestGreen,
                    title: 'Edit Profile & Preferences',
                    subtitle: 'Name, email, and preferred city',
                    onTap: _showEditProfileModal,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.redAccent,
                    title: 'Log Out',
                    subtitle: 'Data remains safely backed up in Cloud',
                    isDestructive: true,
                    onTap: _showLogoutDialog,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red.shade700 : _forestGreen,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: _forestGreen.withOpacity(0.55),
          fontSize: 10.5,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 52,
      endIndent: 14,
      color: Colors.grey.shade100,
    );
  }

  // =========================================================================
  // DIGITAL ORDER RECEIPT & WARRANTY PASS MODAL
  // =========================================================================
  void _showDigitalReceiptModal(PhoneOrder order) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _forestGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 5),
                  Text('CERTIFIED ORDER & WARRANTY PASS', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Simulated High-Res QR Code Card
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 88, color: _forestGreen),
                  const SizedBox(height: 2),
                  Text(
                    order.orderId,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text(
              order.phoneName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _forestGreen),
            ),
            Text(
              '${order.storage} • ${order.color} • Grade ${order.conditionGrade}',
              style: TextStyle(fontSize: 11.5, color: _forestGreen.withOpacity(0.65)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '💰 Amount: ${_formatPrice(order.price)} (${order.paymentMethod})',
                    style: const TextStyle(fontSize: 11, color: _forestGreen, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '📦 ${order.deliveryOption}\n${order.deliveryAddress}',
                    style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.65)),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                label: const Text('View Official POS Tax Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),

            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: _forestGreen)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // OTHER MODALS (LOGIN, EDIT, LOGOUT, SUPPORT, WARRANTY)
  // =========================================================================
  void _showLoginModal() {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    bool otpSent = false;
    bool isSendingOtp = false;
    bool isVerifying = false;
    String? phoneError;
    String? activeDynamicOtp;
    int resendCountdown = 30;
    Timer? resendTimer;

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 26,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _forestGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_person_rounded, color: _forestGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otpSent ? 'Enter Verification Code' : 'Mobile Login / Sign Up',
                              style: const TextStyle(
                                color: _forestGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              otpSent
                                  ? 'Enter 6-digit OTP sent to +91 ${phoneCtrl.text.trim()}'
                                  : 'Access your orders, tracking & warranty details',
                              style: TextStyle(color: _forestGreen.withOpacity(0.6), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!otpSent) ...[
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Your Full Name (Optional)',
                        hintText: 'e.g. Rahul Sharma',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      onChanged: (val) {
                        if (phoneError != null) {
                          setModalState(() => phoneError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: '10-digit Mobile Number',
                        hintText: '98765 43210',
                        counterText: '',
                        errorText: phoneError,
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _forestGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone_iphone_rounded),
                      ),
                    ),
                  ] else ...[
                    // Interactive Dynamic OTP Showcase Card
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
                                  otpCtrl.text = activeDynamicOtp!;
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
                                        fontSize: 11,
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
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Enter 6-digit SMS OTP',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.security_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Countdown Timer & Change Number Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => setModalState(() {
                            resendTimer?.cancel();
                            otpSent = false;
                            otpCtrl.clear();
                          }),
                          icon: const Icon(Icons.edit_outlined, size: 14),
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
                              final clean = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
                              final messenger = ScaffoldMessenger.of(context);
                              await AppState.instance.sendOtp(clean);
                              final newOtp = AppState.instance.backend?.getActiveOtp(clean) ?? '123456';
                              setModalState(() {
                                activeDynamicOtp = newOtp;
                              });
                              startResendTimer(setModalState);
                              messenger.clearSnackBars();
                              messenger.showSnackBar(
                                const SnackBar(content: Text('📩 OTP refreshed! Tap Auto-fill to proceed.')),
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 14, color: _copper),
                            label: const Text('Resend Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _copper)),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Main Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isVerifying || isSendingOtp)
                          ? null
                          : () async {
                              if (!otpSent) {
                                final clean = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
                                final isValidIndianNumber = RegExp(r'^[6-9]\d{9}$').hasMatch(clean);

                                if (!isValidIndianNumber) {
                                  setModalState(() {
                                    phoneError = 'Enter a valid 10-digit mobile (starts with 6, 7, 8, or 9)';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isSendingOtp = true;
                                  phoneError = null;
                                });

                                await AppState.instance.sendOtp(clean);
                                if (!sheetCtx.mounted) return;

                                final generated = AppState.instance.backend?.getActiveOtp(clean) ?? '123456';
                                setModalState(() {
                                  isSendingOtp = false;
                                  otpSent = true;
                                  activeDynamicOtp = generated;
                                });
                                startResendTimer(setModalState);
                              } else {
                                final enteredOtp = otpCtrl.text.trim();
                                if (enteredOtp.isEmpty || enteredOtp.length < 4) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter the 6-digit SMS OTP')),
                                  );
                                  return;
                                }

                                setModalState(() => isVerifying = true);
                                final messenger = ScaffoldMessenger.of(context);

                                final profile = await AppState.instance.verifyOtpAndLogin(
                                  phone: phoneCtrl.text.trim(),
                                  otp: enteredOtp,
                                  name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : null,
                                );

                                if (profile == null) {
                                  setModalState(() => isVerifying = false);
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.redAccent,
                                      content: Text('❌ Invalid OTP. Please enter the correct verification code or tap Auto-fill.'),
                                    ),
                                  );
                                  return;
                                }

                                resendTimer?.cancel();

                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }

                                if (mounted) {
                                  final displayName = profile.name;
                                  final passCount = AppState.instance.reservations.length;
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      backgroundColor: _forestGreen,
                                      duration: const Duration(seconds: 4),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '🎉 Welcome, $displayName! ${passCount > 0 ? '$passCount active orders restored' : 'Logged in successfully'}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: (isVerifying || isSendingOtp)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              otpSent ? 'Verify & Sync' : 'Send Verification OTP',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      resendTimer?.cancel();
    });
  }

  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: AppState.instance.userName ?? '');
    final emailCtrl = TextEditingController(text: AppState.instance.userEmail ?? '');
    final cityCtrl = TextEditingController(text: AppState.instance.userLocation.city);
    final pincodeCtrl = TextEditingController(text: AppState.instance.userLocation.pincode);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 26,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: _forestGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: cityCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Preferred City',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.location_city_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: pincodeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Pincode',
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter your full name')),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final messenger = ScaffoldMessenger.of(context);

                              await AppState.instance.updateProfileDetails(
                                name: name,
                                email: emailCtrl.text.trim(),
                                city: cityCtrl.text.trim(),
                                pincode: pincodeCtrl.text.trim(),
                              );

                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                              }

                              if (mounted) {
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    backgroundColor: _forestGreen,
                                    content: Text('✅ Profile updated successfully!'),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Log Out?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? Your bookings will remain safely stored on Google Cloud.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              AppState.instance.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: _copper),
            SizedBox(width: 8),
            Text('EcoFone Helpline'),
          ],
        ),
        content: const Text(
          'Need assistance with your phone order or store visit?\n\n'
          '🏢 Lucknow Flagship (Transport Nagar): +91 99182 40555\n'
          '🏢 Gomti Nagar Store: +91 99182 40555\n'
          '🏢 Gorakhpur Store (Golghar): +91 91518 37103\n\n'
          '🕒 Store Hours: 10:00 AM – 9:00 PM (All 7 Days)',
          style: TextStyle(fontSize: 12.5, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(backgroundColor: _forestGreen),
            child: const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWarrantyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('6-Month Comprehensive Warranty'),
        content: const Text(
          'Every certified phone purchased at EcoFone includes:\n\n'
          '• 180 Days Hardware & Display coverage\n'
          '• Free battery replacement if health drops below 80%\n'
          '• 100% cashless walk-in claims across all retail stores\n'
          '• 7-day no-questions replacement pass',
          style: TextStyle(fontSize: 12.5, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: Text(
          'Are you sure you want to cancel order #$orderId? If already paid online, the refund will be automatically processed back to your original payment method within 2-3 working days.',
          style: const TextStyle(fontSize: 12.5, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppState.instance.cancelOrder(orderId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #$orderId cancelled successfully.'),
                  backgroundColor: _forestGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Custom Perforated Ticket Divider with side circular punchout notches
class TicketDividerPainter extends CustomPainter {
  final Color color;
  final Color cutoutColor;

  TicketDividerPainter({required this.color, required this.cutoutColor});

  @override
  void paint(Canvas canvas, Size size) {
    const notchRadius = 8.0;

    // Draw left cutout circle
    final notchPaint = Paint()..color = cutoutColor;
    canvas.drawCircle(Offset(0, size.height / 2), notchRadius, notchPaint);

    // Draw right cutout circle
    canvas.drawCircle(Offset(size.width, size.height / 2), notchRadius, notchPaint);

    // Draw dashed perforated line
    final dashPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.5;
    double startX = notchRadius + 4;
    final endX = size.width - notchRadius - 4;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth < endX ? startX + dashWidth : endX, size.height / 2),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
