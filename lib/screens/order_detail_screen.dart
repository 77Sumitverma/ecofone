import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/pos_invoice_sheet.dart';
import 'package:ecofone/screens/directions_sheet.dart';
import 'package:ecofone/state/app_state.dart';

/// Comprehensive Order Detail & Tracking Screen
/// Displays:
/// 1. Interactive Device Photos Gallery (Front, Camera Bar, Display, Diagnostic Seal)
/// 2. Live 5-Stage Order Delivery Tracker
/// 3. Complete Order Specifications, Pricing, Delivery, and POS Tax Invoice
class OrderDetailScreen extends StatefulWidget {
  final PhoneOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const _bgColor = EcoColors.background;
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;

  late PageController _photoPageController;
  int _selectedPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    AppState.instance.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    AppState.instance.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  String _formatPrice(int price) {
    final str = price.toString();
    if (str.length <= 3) return '₹$str';
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$formattedRest,$lastThree';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    // Look up live order from AppState
    final liveOrder = AppState.instance.orders.where((o) => o.orderId == widget.order.orderId).firstOrNull ?? widget.order;
    final isDelivery = liveOrder.deliveryOption.toLowerCase().contains('delivery') ||
        liveOrder.deliveryOption.toLowerCase().contains('doorstep');

    final statusUpper = liveOrder.orderStatus.toUpperCase();
    final isCancelled = statusUpper.contains('CANCELLED');
    final isDelivered = statusUpper.contains('DELIVERED');
    final isOutForDelivery = statusUpper.contains('OUT_FOR_DELIVERY') || statusUpper.contains('OUT FOR DELIVERY') || isDelivered;
    final isDispatched = statusUpper.contains('DISPATCHED') || isOutForDelivery;

    final Color statusBg;
    final Color statusTextColor;
    final String statusDisplay;
    final IconData statusIcon;

    if (isDelivered) {
      statusBg = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF15803D);
      statusDisplay = 'DELIVERED';
      statusIcon = Icons.check_circle_rounded;
    } else if (isOutForDelivery) {
      statusBg = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
      statusDisplay = 'OUT FOR DELIVERY';
      statusIcon = Icons.delivery_dining_rounded;
    } else if (isDispatched) {
      statusBg = const Color(0xFFF3E8FF);
      statusTextColor = const Color(0xFF7E22CE);
      statusDisplay = 'DISPATCHED';
      statusIcon = Icons.local_shipping_rounded;
    } else if (isCancelled) {
      statusBg = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFB91C1C);
      statusDisplay = 'CANCELLED';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusBg = const Color(0xFFE6F4EA);
      statusTextColor = const Color(0xFF137333);
      statusDisplay = 'ORDER CONFIRMED';
      statusIcon = Icons.inventory_2_outlined;
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _forestGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                color: _forestGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16.5,
              ),
            ),
            Text(
              '#${liveOrder.orderId}',
              style: const TextStyle(
                color: _copper,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: _forestGreen),
            tooltip: 'View Official Tax Invoice',
            onPressed: () => PosInvoiceSheet.show(
              context,
              invoiceNumber: liveOrder.invoiceNumber ?? 'ECO-2026-000452',
              order: liveOrder,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: _copper),
            tooltip: 'View Digital Pass',
            onPressed: () => _showDigitalReceiptModal(liveOrder),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATUS & HIGHLIGHT CARD
            _buildStatusHeaderCard(liveOrder, statusBg, statusTextColor, statusDisplay, statusIcon),
            const SizedBox(height: 16),

            // 2. DEVICE PHOTOS GALLERY (PHOTOS OF PHONE)
            _buildPhonePhotosGallery(liveOrder),
            const SizedBox(height: 16),

            // 3. LIVE ORDER TRACKER
            _buildLiveOrderTracker(liveOrder, isDispatched, isOutForDelivery, isDelivered, isCancelled),
            const SizedBox(height: 16),

            // 4. DEVICE SPECIFICATIONS & HARDWARE DIAGNOSTICS
            _buildDeviceSpecsCard(liveOrder),
            const SizedBox(height: 16),

            // 5. DELIVERY / STORE PICKUP INFORMATION
            _buildDeliveryInfoCard(liveOrder, isDelivery),
            const SizedBox(height: 16),

            // 6. PAYMENT & PRICE BREAKDOWN
            _buildPriceBreakdownCard(liveOrder),
            const SizedBox(height: 16),

            // 7. OFFICIAL POS TAX INVOICE & PASS CARD
            _buildInvoicePassCard(liveOrder),
            const SizedBox(height: 20),

            // 8. ACTION BUTTONS (SUPPORT & CANCEL)
            _buildFooterActions(liveOrder, isCancelled, isDelivered),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. STATUS HEADER CARD
  // ---------------------------------------------------------------------------
  Widget _buildStatusHeaderCard(
    PhoneOrder order,
    Color statusBg,
    Color statusTextColor,
    String statusDisplay,
    IconData statusIcon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusTextColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusTextColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      statusDisplay,
                      style: TextStyle(
                        color: statusTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatPrice(order.price),
                style: const TextStyle(
                  color: _copper,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.phoneName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${order.storage} • ${order.color} • Grade ${order.conditionGrade}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: Colors.black.withOpacity(0.4)),
              const SizedBox(width: 5),
              Text(
                'Placed on ${_formatDate(order.createdAt)}',
                style: TextStyle(fontSize: 11.5, color: Colors.black.withOpacity(0.45)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PHONE PHOTOS GALLERY (HIGH RES PHOTOS OF PHONE)
  // ---------------------------------------------------------------------------
  Widget _buildPhonePhotosGallery(PhoneOrder order) {
    final imagePath = order.effectiveImageUrl;
    final displayImagePath = imagePath.startsWith('assets/')
        ? imagePath.replaceAll('.jpg', '.png')
        : imagePath;
    final isAssetImage = displayImagePath.startsWith('assets/');

    final photoItems = [
      {
        'title': 'Studio Front & Back Finish',
        'subtitle': 'Verified ${order.color} exterior with pristine OEM body',
        'badge': 'Verified Unit',
        'image': displayImagePath,
        'icon': Icons.phone_android_rounded,
      },
      {
        'title': 'Precision Camera Optics',
        'subtitle': 'Front & rear optical lenses calibrated and dust-free',
        'badge': 'Optics 100% OK',
        'image': displayImagePath,
        'icon': Icons.camera_enhance_rounded,
      },
      {
        'title': 'Certified OLED / Retina Display',
        'subtitle': 'Original display panel with zero burn-in and flawless digitizer',
        'badge': 'Original OEM Panel',
        'image': displayImagePath,
        'icon': Icons.screenshot_monitor_rounded,
      },
      {
        'title': '32-Point Diagnostic Passed',
        'subtitle': 'Hardware, Battery, Camera, Biometrics & 5G verified by certified technicians',
        'badge': 'EcoFone Certified',
        'image': displayImagePath,
        'icon': Icons.verified_user_rounded,
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 18, color: _forestGreen),
                    SizedBox(width: 8),
                    Text(
                      'Device Inspection Photos',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: _forestGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _forestGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedPhotoIndex + 1} of ${photoItems.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Main Interactive Photo Display
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _photoPageController,
              itemCount: photoItems.length,
              onPageChanged: (idx) => setState(() => _selectedPhotoIndex = idx),
              itemBuilder: (context, index) {
                final item = photoItems[index];
                return Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: displayImagePath.isNotEmpty
                            ? Hero(
                                tag: 'order_photo_${order.orderId}_$index',
                                child: isAssetImage
                                    ? Image.asset(
                                        displayImagePath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            Icon(item['icon'] as IconData, size: 90, color: _forestGreen.withOpacity(0.4)),
                                      )
                                    : Image.network(
                                        displayImagePath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            Icon(item['icon'] as IconData, size: 90, color: _forestGreen.withOpacity(0.4)),
                                      ),
                              )
                            : Icon(item['icon'] as IconData, size: 90, color: _forestGreen.withOpacity(0.4)),
                      ),
                    ),

                    // Top Left Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _forestGreen.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              item['badge'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom info gradient banner
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Thumbnail bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(photoItems.length, (idx) {
                final isSelected = _selectedPhotoIndex == idx;
                return GestureDetector(
                  onTap: () {
                    _photoPageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _forestGreen : Colors.black.withOpacity(0.08),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(4),
                    child: imagePath.isNotEmpty && imagePath.startsWith('assets/')
                        ? Image.asset(imagePath, fit: BoxFit.contain)
                        : Icon(photoItems[idx]['icon'] as IconData, size: 24, color: _forestGreen),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. LIVE ORDER TRACKER
  // ---------------------------------------------------------------------------
  Widget _buildLiveOrderTracker(
    PhoneOrder order,
    bool isDispatched,
    bool isOutForDelivery,
    bool isDelivered,
    bool isCancelled,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 18, color: _forestGreen),
                  SizedBox(width: 8),
                  Text(
                    'Delivery Tracking',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: _forestGreen,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCancelled ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCancelled ? 'Cancelled' : (isDelivered ? 'Completed' : 'In Progress'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isCancelled ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel_rounded, color: Color(0xFFB91C1C), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This order was cancelled. Any online payment will be refunded to your source account within 2-3 working days.',
                      style: TextStyle(color: Color(0xFFB91C1C), fontSize: 11.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildTrackerStep(
              title: 'Order Placed & Confirmed',
              subtitle: 'Central store verified inventory and reserved serial IMEI for ${order.customerName}',
              date: _formatDate(order.createdAt),
              isCompleted: true,
              isCurrent: !isDispatched,
              icon: Icons.check_circle_rounded,
            ),
            _buildTrackerStep(
              title: '48-Point Diagnostic & Packaging',
              subtitle: 'Device battery, display and cameras verified. Sealed in tamper-proof EcoBox',
              date: isDispatched ? 'Verified by Technicians' : 'In Progress',
              isCompleted: isDispatched,
              isCurrent: isDispatched && !isOutForDelivery,
              icon: Icons.verified_rounded,
            ),
            _buildTrackerStep(
              title: 'Dispatched from Store Hub',
              subtitle: 'Handed over to EcoExpress Courier • AWB #ECO-EXP-${order.orderId.replaceAll(RegExp(r'[^0-9]'), '')}',
              date: isDispatched ? 'Dispatched' : 'Pending Handover',
              isCompleted: isDispatched,
              isCurrent: isDispatched && !isOutForDelivery,
              icon: Icons.local_shipping_rounded,
            ),
            _buildTrackerStep(
              title: 'Out for Doorstep Delivery',
              subtitle: 'Delivery executive is en route to ${order.deliveryAddress}',
              date: isOutForDelivery ? 'Today by 6:00 PM' : 'Expected Tomorrow',
              isCompleted: isOutForDelivery,
              isCurrent: isOutForDelivery && !isDelivered,
              icon: Icons.delivery_dining_rounded,
            ),
            _buildTrackerStep(
              title: 'Delivered & 6-Month Warranty Activated',
              subtitle: 'Customer inspection completed with 6-month comprehensive cashless warranty pass',
              date: isDelivered ? 'Handover Completed' : 'Pending Delivery',
              isCompleted: isDelivered,
              isCurrent: isDelivered,
              icon: Icons.home_work_rounded,
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackerStep({
    required String title,
    required String subtitle,
    required String date,
    required bool isCompleted,
    required bool isCurrent,
    required IconData icon,
    bool isLast = false,
  }) {
    final activeColor = isCompleted ? _forestGreen : (isCurrent ? _copper : Colors.grey.shade400);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? _forestGreen : (isCurrent ? _copper : Colors.grey.shade200),
                border: Border.all(
                  color: isCurrent ? _copper.withOpacity(0.4) : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check_rounded : icon,
                  size: 14,
                  color: isCompleted || isCurrent ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isCompleted ? _forestGreen : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: activeColor,
                          fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. DEVICE SPECIFICATIONS CARD
  // ---------------------------------------------------------------------------
  Widget _buildDeviceSpecsCard(PhoneOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_iphone_rounded, size: 18, color: _forestGreen),
              SizedBox(width: 8),
              Text(
                'Device Specifications & Grade',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: _forestGreen),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSpecRow('Model Name', order.phoneName),
          _buildSpecRow('Brand', order.brand),
          _buildSpecRow('Storage Capacity', order.storage),
          _buildSpecRow('Color Finish', order.color),
          _buildSpecRow('Condition Grade', 'Grade ${order.conditionGrade}'),
          _buildSpecRow('Battery Health', '95% Certified Original Battery'),
          _buildSpecRow('IMEI / Serial Number', order.imei1 ?? '358941098273641', isMonospace: true),
          _buildSpecRow('Warranty Pass', '6-Month Comprehensive Cashless Warranty', isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, {bool isMonospace = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted ? _forestGreen : const Color(0xFF0F172A),
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. DELIVERY / STORE PICKUP INFORMATION CARD
  // ---------------------------------------------------------------------------
  Widget _buildDeliveryInfoCard(PhoneOrder order, bool isDelivery) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDelivery ? Icons.home_rounded : Icons.storefront_rounded,
                size: 18,
                color: _forestGreen,
              ),
              const SizedBox(width: 8),
              Text(
                isDelivery ? 'Delivery Address' : 'Store Pickup Hub',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: _forestGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            isDelivery ? order.customerName : order.storeName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            isDelivery ? order.deliveryAddress : order.storeAddress,
            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.65), height: 1.3),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 13, color: _forestGreen),
              const SizedBox(width: 5),
              Text(
                isDelivery ? order.customerPhone : order.storePhone,
                style: const TextStyle(fontSize: 11.5, color: _forestGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          if (!isDelivery) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => StoreDirectionsSheet.show(context, order.store),
                    icon: const Icon(Icons.directions_rounded, size: 14, color: _forestGreen),
                    label: const Text('Store Route', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _forestGreen,
                      side: BorderSide(color: _forestGreen.withOpacity(0.3)),
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
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone_rounded, size: 14, color: Colors.white),
                    label: const Text('Call Store', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. PAYMENT & PRICE BREAKDOWN CARD
  // ---------------------------------------------------------------------------
  Widget _buildPriceBreakdownCard(PhoneOrder order) {
    final originalPrice = (order.price * 1.45).round();
    final savings = originalPrice - order.price;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: _forestGreen),
              SizedBox(width: 8),
              Text(
                'Price & Payment Summary',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: _forestGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildPriceRow('Market MRP', _formatPrice(originalPrice)),
          _buildPriceRow('Refurbished Superb Price', _formatPrice(order.price)),
          _buildPriceRow('EcoFone Savings', '-${_formatPrice(savings)}', isDiscount: true),
          _buildPriceRow('Doorstep Delivery Fee', 'FREE', isDiscount: true),
          _buildPriceRow('Diagnostic & 6-Mo Warranty', 'INCLUDED', isDiscount: true),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Total Amount Payable',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatPrice(order.price),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5, color: _copper),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Payment Mode: ${order.paymentMethod}',
                  style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.55)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.paymentStatus,
                    style: const TextStyle(color: Color(0xFF15803D), fontSize: 9.5, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.55))),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDiscount ? const Color(0xFF15803D) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. OFFICIAL POS TAX INVOICE & PASS CARD
  // ---------------------------------------------------------------------------
  Widget _buildInvoicePassCard(PhoneOrder order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _forestGreen.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _forestGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 20, color: _forestGreen),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official POS Tax Invoice & QR Pass',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: _forestGreen),
                    ),
                    Text(
                      'GST Compliant with sequential B2C invoice number',
                      style: TextStyle(fontSize: 10.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => PosInvoiceSheet.show(
                context,
                invoiceNumber: order.invoiceNumber ?? 'ECO-2026-000452',
                order: order,
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
              label: const Text('View Full Tax Invoice & QR Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. FOOTER ACTIONS (SUPPORT & CANCEL)
  // ---------------------------------------------------------------------------
  Widget _buildFooterActions(PhoneOrder order, bool isCancelled, bool isDelivered) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: '+91 99182 40555'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📞 EcoFone 24x7 Support: +91 99182 40555 copied to clipboard'),
                  backgroundColor: _forestGreen,
                ),
              );
            },
            icon: const Icon(Icons.support_agent_rounded, size: 16, color: _forestGreen),
            label: const Text('Need Help? Contact EcoFone Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: _forestGreen)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: _forestGreen.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        if (!isCancelled && !isDelivered) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showCancelOrderDialog(order.orderId),
              icon: const Icon(Icons.cancel_outlined, size: 15, color: Colors.redAccent),
              label: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent)),
            ),
          ),
        ],
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
                  Text('CERTIFIED ORDER PASS', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // High-Res QR Code Card
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
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
