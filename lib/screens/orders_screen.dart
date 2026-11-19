import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/pos_invoice_sheet.dart';
import 'package:ecofone/screens/directions_sheet.dart';
import 'package:ecofone/screens/order_detail_screen.dart';
import 'package:ecofone/state/app_state.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _bgColor = EcoColors.background;
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;

  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppState.instance.refreshOrders();
      }
    });
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

  List<PhoneOrder> _getFilteredOrders(List<PhoneOrder> orders) {
    if (_selectedFilter == 'ACTIVE') {
      return orders.where((o) {
        final st = o.orderStatus.toUpperCase();
        return !st.contains('DELIVERED') && !st.contains('CANCELLED');
      }).toList();
    } else if (_selectedFilter == 'DELIVERED') {
      return orders.where((o) => o.orderStatus.toUpperCase().contains('DELIVERED')).toList();
    } else if (_selectedFilter == 'CANCELLED') {
      return orders.where((o) => o.orderStatus.toUpperCase().contains('CANCELLED')).toList();
    }
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AppState.instance.isLoggedIn;
    final allOrders = AppState.instance.orders;
    final filteredOrders = _getFilteredOrders(allOrders);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _forestGreen, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Orders & Purchases',
              style: TextStyle(
                color: _forestGreen,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Track deliveries, invoices & order history',
              style: TextStyle(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _forestGreen, size: 22),
            onPressed: () {
              HapticFeedback.selectionClick();
              AppState.instance.refreshOrders();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Refreshing orders from central server...'),
                  duration: Duration(seconds: 1),
                  backgroundColor: _forestGreen,
                ),
              );
            },
            tooltip: 'Refresh Orders',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black.withOpacity(0.06), height: 1),
        ),
      ),
      body: !isLoggedIn
          ? _buildGuestView()
          : RefreshIndicator(
              onRefresh: () async {
                await AppState.instance.refreshOrders();
              },
              color: _forestGreen,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // Filter Chips
                  SliverToBoxAdapter(
                    child: _buildFilterChips(allOrders),
                  ),

                  // Orders List or Empty State
                  if (filteredOrders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(allOrders.isEmpty),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                          childCount: filteredOrders.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER CHIPS BAR
  // ---------------------------------------------------------------------------
  Widget _buildFilterChips(List<PhoneOrder> orders) {
    final activeCount = orders.where((o) {
      final st = o.orderStatus.toUpperCase();
      return !st.contains('DELIVERED') && !st.contains('CANCELLED');
    }).length;

    final deliveredCount = orders.where((o) => o.orderStatus.toUpperCase().contains('DELIVERED')).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          _buildChip('ALL', 'All Orders (${orders.length})'),
          const SizedBox(width: 8),
          _buildChip('ACTIVE', 'Active ($activeCount)'),
          const SizedBox(width: 8),
          _buildChip('DELIVERED', 'Delivered ($deliveredCount)'),
          const SizedBox(width: 8),
          _buildChip('CANCELLED', 'Cancelled'),
        ],
      ),
    );
  }

  Widget _buildChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = filterKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _forestGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _forestGreen : Colors.black.withOpacity(0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _forestGreen.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _forestGreen,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ORDER CARD (Uniform, Fixed Height & Structured)
  // ---------------------------------------------------------------------------
  Widget _buildOrderCard(PhoneOrder order) {
    final isDelivery = order.deliveryOption.toLowerCase().contains('delivery') ||
        order.deliveryOption.toLowerCase().contains('doorstep');

    final statusUpper = order.orderStatus.toUpperCase();
    final Color statusBg;
    final Color statusTextColor;
    final String statusDisplay;
    final IconData statusIcon;

    if (statusUpper.contains('DELIVERED')) {
      statusBg = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF15803D);
      statusDisplay = 'DELIVERED';
      statusIcon = Icons.check_circle_rounded;
    } else if (statusUpper.contains('OUT_FOR_DELIVERY') || statusUpper.contains('OUT FOR DELIVERY')) {
      statusBg = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
      statusDisplay = 'OUT FOR DELIVERY';
      statusIcon = Icons.delivery_dining_rounded;
    } else if (statusUpper.contains('DISPATCHED')) {
      statusBg = const Color(0xFFF3E8FF);
      statusTextColor = const Color(0xFF7E22CE);
      statusDisplay = 'DISPATCHED';
      statusIcon = Icons.local_shipping_rounded;
    } else if (statusUpper.contains('CANCELLED')) {
      statusBg = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFB91C1C);
      statusDisplay = 'CANCELLED';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusBg = const Color(0xFFE6F4EA);
      statusTextColor = const Color(0xFF137333);
      statusDisplay = 'ORDER PLACED';
      statusIcon = Icons.inventory_2_outlined;
    }

    final isCancelled = statusUpper.contains('CANCELLED');
    final isDelivered = statusUpper.contains('DELIVERED');
    final canCancel = !isCancelled && !isDelivered;

    final paymentStatusUpper = order.paymentStatus.toUpperCase();
    final paymentMethodUpper = order.paymentMethod.toUpperCase();
    final isPaidOnline = paymentStatusUpper.contains('PAID') ||
        paymentMethodUpper.contains('UPI') ||
        paymentMethodUpper.contains('CARD') ||
        paymentMethodUpper.contains('ONLINE');

    final paymentLabel = isPaidOnline ? 'Paid Online' : 'Pay on Delivery (COD)';
    final paymentBg = isPaidOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final paymentColor = isPaidOnline ? const Color(0xFF15803D) : const Color(0xFFB45309);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header Bar: Order ID + Status Badge (Fixed Height)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: _copper.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 13, color: _copper),
                        const SizedBox(width: 4),
                        Text(
                          '#${order.orderId}',
                          style: const TextStyle(
                            color: _copper,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusTextColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusTextColor, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        statusDisplay,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // 2. Center Info Body: Fixed 56x56 Thumbnail + Strict 1-Line Info + Price
          // Tapping navigates into comprehensive OrderDetailScreen!
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnail container (Fixed 56x56 with Real Phone Photo)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Builder(builder: (_) {
                      final img = order.effectiveImageUrl;
                      if (img.isNotEmpty && img.startsWith('assets/')) {
                        return Image.asset(img, fit: BoxFit.contain);
                      } else if (order.imageUrl != null && order.imageUrl!.isNotEmpty) {
                        return Image.network(
                          order.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.phone_iphone_rounded, color: _forestGreen, size: 28),
                        );
                      }
                      return const Icon(Icons.phone_iphone_rounded, color: _forestGreen, size: 28);
                    }),
                  ),
                  const SizedBox(width: 12),

                  // Device & order info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.phoneName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.storage} • ${order.color} • Grade ${order.conditionGrade}',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              isDelivery ? Icons.local_shipping_outlined : Icons.storefront_rounded,
                              size: 12,
                              color: _forestGreen.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isDelivery
                                    ? 'Delivery: ${order.deliveryAddress}'
                                    : 'Pickup: ${order.storeName}',
                                style: TextStyle(
                                  color: _forestGreen.withOpacity(0.8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ordered on ${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.38),
                            fontSize: 9.5,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Price and payment badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatPrice(order.price),
                        style: const TextStyle(
                          color: _copper,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: paymentBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: paymentColor.withOpacity(0.2)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            paymentLabel,
                            style: TextStyle(
                              color: paymentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // 3. Bottom Action Footer (Uniform Height across ALL Cards)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: const Color(0xFFFCFDFD),
            child: Row(
              children: [
                // Button 1: Track Order or Store Route
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: isDelivery
                          ? () => _showOrderTrackingDialog(order)
                          : () => StoreDirectionsSheet.show(context, order.store),
                      icon: Icon(
                        isDelivery ? Icons.local_shipping_outlined : Icons.directions_rounded,
                        size: 13,
                        color: _forestGreen,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isDelivery ? 'Track Order' : 'Store Route',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _forestGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        side: BorderSide(color: _forestGreen.withOpacity(0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Button 2: Tax Invoice & Pass (for ALL orders!)
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        PosInvoiceSheet.show(
                          context,
                          invoiceNumber: order.invoiceNumber ?? 'ECO-2026-000452',
                          order: order,
                        );
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 13, color: Colors.white),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tax Invoice & Pass',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Button 3: Overflow Menu Button (Consistent 34x34)
                SizedBox(
                  width: 34,
                  height: 34,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.black.withOpacity(0.55)),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'details') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        );
                      } else if (value == 'qr') {
                        _showDigitalReceiptModal(order);
                      } else if (value == 'call') {
                        Clipboard.setData(ClipboardData(text: order.storePhone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📞 Store phone copied: ${order.storePhone}'),
                            backgroundColor: _forestGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else if (value == 'cancel') {
                        _showCancelOrderDialog(order.orderId);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: _forestGreen),
                            SizedBox(width: 8),
                            Text('Order Details & Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'qr',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded, size: 16, color: _copper),
                            SizedBox(width: 8),
                            Text('Digital Pass & QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (!isDelivery)
                        PopupMenuItem(
                          value: 'call',
                          child: Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 16, color: _forestGreen),
                              const SizedBox(width: 8),
                              Text('Call Store (${order.storePhone})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      if (canCancel)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Cancel Order',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LIVE TRACKING DIALOG
  // ---------------------------------------------------------------------------
  void _showOrderTrackingDialog(PhoneOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (trackCtx) => ListenableBuilder(
        listenable: AppState.instance,
        builder: (ctx, _) {
          final liveOrder = AppState.instance.orders.where((o) => o.orderId == order.orderId).firstOrNull ?? order;
          final st = liveOrder.orderStatus.toUpperCase();
          final isDelivered = st.contains('DELIVERED');
          final isOutForDelivery = st.contains('OUT_FOR_DELIVERY') || isDelivered;
          final isDispatched = st.contains('DISPATCHED') || isOutForDelivery;

          return Padding(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Delivery Tracking',
                            style: TextStyle(
                              color: _forestGreen,
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order #${order.orderId} • ${order.phoneName}',
                            style: TextStyle(
                              color: _forestGreen.withOpacity(0.6),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _forestGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        liveOrder.orderStatus,
                        style: const TextStyle(
                          color: _forestGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildTrackingStep(
                  title: 'Order Confirmed & Placed',
                  subtitle: 'Central store verified inventory and reserved serial unit',
                  isCompleted: true,
                  isCurrent: !isDispatched,
                ),
                _buildTrackingStep(
                  title: 'Dispatched from Store Hub',
                  subtitle: 'Tested via 48-Point Diagnostic & handed to EcoExpress Rider',
                  isCompleted: isDispatched,
                  isCurrent: isDispatched && !isOutForDelivery,
                ),
                _buildTrackingStep(
                  title: 'Out for Express Delivery',
                  subtitle: 'Rider is en route to ${order.deliveryAddress}',
                  isCompleted: isOutForDelivery,
                  isCurrent: isOutForDelivery && !isDelivered,
                ),
                _buildTrackingStep(
                  title: 'Delivered & Handover',
                  subtitle: 'Delivered to customer with 6-Month Warranty Pass activated',
                  isCompleted: isDelivered,
                  isCurrent: isDelivered,
                  isLast: true,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(trackCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
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

  // ---------------------------------------------------------------------------
  // DIGITAL RECEIPT MODAL
  // ---------------------------------------------------------------------------
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
                  Text('CERTIFIED ORDER & WARRANTY PASS',
                      style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
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
                label: const Text('View Official POS Tax Invoice',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  // ---------------------------------------------------------------------------
  // CANCEL ORDER DIALOG
  // ---------------------------------------------------------------------------
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
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(bool noOrdersAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _forestGreen.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_mall_outlined,
                size: 38,
                color: _forestGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              noOrdersAtAll ? 'No Orders Placed Yet' : 'No Orders In This Category',
              style: const TextStyle(
                color: _forestGreen,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noOrdersAtAll
                  ? 'All your certified smartphone purchases, live delivery tracking and warranty passes will appear here.'
                  : 'Try selecting "All Orders" to view your full purchase history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
              label: const Text('Browse Smartphone Stock', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GUEST STATE
  // ---------------------------------------------------------------------------
  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _copper.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: _copper,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sign In to View Orders',
              style: TextStyle(
                color: _forestGreen,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in with your mobile number to view active orders, live tracking status, and 6-month warranty passes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withOpacity(0.55),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
              label: const Text('Back to Profile to Login', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom perforated ticket divider
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
      ..strokeWidth = 1.0;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = notchRadius + 4;
    final endX = size.width - notchRadius - 4;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
