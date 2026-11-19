import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/brand_logo.dart';
import 'package:ecofone/screens/location_sheet.dart';
import 'package:ecofone/screens/orders_screen.dart';
import 'package:ecofone/state/app_state.dart';
import 'package:ecofone/services/location_service.dart';

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

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AppState.instance.isLoggedIn;

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

            // 3. Clean Grouped Menu & Actions (Orders are now housed inside dedicated Orders section)
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
                  if (AppState.instance.userAlternatePhone != null && AppState.instance.userAlternatePhone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Alt Contact: +91 ${AppState.instance.userAlternatePhone}',
                      style: const TextStyle(
                        color: EcoColors.mintLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📍 ${AppState.instance.userLocation.fullDisplay}',
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
  // 4. CLEAN GROUPED MENU SECTION
  // =========================================================================
  Widget _buildGroupedMenuSection(bool isLoggedIn) {
    final orders = AppState.instance.orders;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group 0: Orders Section (Tapping opens dedicated Orders Screen)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildMenuItem(
              icon: Icons.local_mall_outlined,
              iconColor: _forestGreen,
              title: 'My Orders & Purchases',
              subtitle: isLoggedIn && orders.isNotEmpty
                  ? '${orders.length} ${orders.length == 1 ? 'order' : 'orders'} placed • View status & invoices'
                  : 'Track active deliveries & digital invoices',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoggedIn && orders.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _forestGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${orders.length} ${orders.length == 1 ? 'Order' : 'Orders'}',
                        style: const TextStyle(
                          color: _forestGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

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
    Widget? trailing,
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
      trailing: trailing ??
          Icon(
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
  // OTHER MODALS (LOGIN, EDIT, LOGOUT, SUPPORT, WARRANTY)
  // =========================================================================
  void _showLoginModal() {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Lucknow');
    final areaCtrl = TextEditingController(text: 'Gomti Nagar');
    final pincodeCtrl = TextEditingController(text: '226010');

    bool otpSent = false;
    bool isNewUserRegistration = false;
    bool isSendingOtp = false;
    bool isVerifying = false;
    bool isSavingRegistration = false;
    bool isDetectingLocation = false;
    String? nameError;
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

                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _forestGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isNewUserRegistration
                              ? Icons.assignment_ind_rounded
                              : (otpSent ? Icons.shield_outlined : Icons.lock_person_rounded),
                          color: _forestGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNewUserRegistration
                                  ? 'Set Delivery Address'
                                  : (otpSent ? 'Enter Verification Code' : 'Mobile Login / Sign Up'),
                              style: const TextStyle(
                                color: _forestGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              isNewUserRegistration
                                  ? 'Welcome, ${nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Customer'}! Enter doorstep address'
                                  : (otpSent
                                      ? 'Enter 6-digit OTP sent to +91 ${phoneCtrl.text.trim()}'
                                      : 'Enter your name and 10-digit mobile number'),
                              style: TextStyle(color: _forestGreen.withOpacity(0.6), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // STEP 3: NEW USER REGISTRATION FORM (DELIVERY ADDRESS ONLY)
                  if (isNewUserRegistration) ...[
                    // Delivery Location Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 16, color: _forestGreen),
                                  SizedBox(width: 6),
                                  Text(
                                    'Delivery Location',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _forestGreen),
                                  ),
                                ],
                              ),
                              BouncingWidget(
                                scaleFactor: 0.95,
                                onTap: isDetectingLocation
                                    ? null
                                    : () async {
                                        setModalState(() => isDetectingLocation = true);
                                        try {
                                          final loc = await LocationService.fetchRealDeviceLocation();
                                          if (loc != null) {
                                            setModalState(() {
                                              cityCtrl.text = loc.city;
                                              areaCtrl.text = loc.area;
                                              pincodeCtrl.text = loc.pincode;
                                            });
                                          }
                                        } finally {
                                          setModalState(() => isDetectingLocation = false);
                                        }
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _forestGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isDetectingLocation)
                                        const SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(strokeWidth: 1.5, color: _forestGreen),
                                        )
                                      else
                                        const Icon(Icons.my_location_rounded, size: 12, color: _forestGreen),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Detect GPS',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _forestGreen),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Quick City Selection Chips
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: ['Lucknow', 'Gorakhpur', 'Delhi NCR', 'Pune', 'Kanpur'].map((c) {
                              final isSelected = cityCtrl.text.toLowerCase() == c.toLowerCase();
                              return ChoiceChip(
                                label: Text(c, style: TextStyle(fontSize: 10.5, color: isSelected ? Colors.white : Colors.black87)),
                                selected: isSelected,
                                selectedColor: _forestGreen,
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                onSelected: (val) {
                                  if (val) setModalState(() => cityCtrl.text = c);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: cityCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    labelText: 'City *',
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: pincodeCtrl,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    labelText: 'Pincode *',
                                    counterText: '',
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: areaCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Area / Street / Colony / Landmark *',
                              hintText: 'e.g. Gomti Nagar, Viram Khand 1',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.home_work_outlined, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: _forestGreen),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can add your alternate contact number and email anytime in Edit Profile.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                  // STEP 1: NAME AND PHONE NUMBER ENTRY
                  else if (!otpSent) ...[
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (val) {
                        if (nameError != null) {
                          setModalState(() => nameError = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Rahul Sharma',
                        errorText: nameError,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
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
                        labelText: '10-digit Mobile Number *',
                        hintText: '98765 43210',
                        counterText: '',
                        errorText: phoneError,
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: _forestGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone_iphone_rounded),
                      ),
                    ),
                  ]
                  // STEP 2: OTP VERIFICATION
                  else ...[
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
                      controller: otpCtrl,
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
                              otpCtrl.clear();
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
                      onPressed: (isVerifying || isSendingOtp || isSavingRegistration)
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);

                              // A. SAVE NEW USER REGISTRATION
                              if (isNewUserRegistration) {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) {
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(const SnackBar(content: Text('Please enter your full name')));
                                  return;
                                }

                                final city = cityCtrl.text.trim();
                                if (city.isEmpty) {
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(const SnackBar(content: Text('Please select or enter your city')));
                                  return;
                                }

                                final area = areaCtrl.text.trim();
                                if (area.isEmpty) {
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(const SnackBar(content: Text('Please enter your area / locality')));
                                  return;
                                }

                                final pincode = pincodeCtrl.text.trim();
                                if (pincode.length != 6) {
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(const SnackBar(content: Text('Please enter a valid 6-digit pincode')));
                                  return;
                                }

                                setModalState(() => isSavingRegistration = true);

                                final profile = await AppState.instance.completeRegistration(
                                  name: name,
                                  phone: phoneCtrl.text.trim(),
                                  alternatePhone: null,
                                  city: city,
                                  area: area,
                                  pincode: pincode,
                                );

                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }

                                if (mounted) {
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      backgroundColor: _forestGreen,
                                      duration: const Duration(seconds: 4),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '🎉 Profile saved! Welcome to EcoFone, ${profile.name}!',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              // B. SEND OTP (STEP 1)
                              if (!otpSent) {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) {
                                  setModalState(() {
                                    nameError = 'Please enter your full name';
                                  });
                                  return;
                                }

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
                                  nameError = null;
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
                              }
                              // C. VERIFY OTP
                              else {
                                final enteredOtp = otpCtrl.text.trim();
                                if (enteredOtp.isEmpty || enteredOtp.length < 4) {
                                  messenger.clearSnackBars();
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Please enter the 6-digit SMS OTP')),
                                  );
                                  return;
                                }

                                setModalState(() => isVerifying = true);

                                final profile = await AppState.instance.verifyOtpAndLogin(
                                  phone: phoneCtrl.text.trim(),
                                  otp: enteredOtp,
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

                                // If this is a first-time new user, prompt for details!
                                if (profile.isNewUser) {
                                  setModalState(() {
                                    isVerifying = false;
                                    isNewUserRegistration = true;
                                  });
                                  return;
                                }

                                // Otherwise, this is an existing user: Auto-saved data already loaded!
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }

                                if (mounted) {
                                  final displayName = profile.name;
                                  final loc = AppState.instance.userLocation;
                                  final locDisplay = loc.area.isNotEmpty ? '${loc.area}, ${loc.city}' : loc.city;
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
                                              '🎉 Welcome back, $displayName! Location ($locDisplay) restored.',
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
                      child: (isVerifying || isSendingOtp || isSavingRegistration)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isNewUserRegistration
                                  ? 'Confirm Address & Finish'
                                  : (otpSent ? 'Verify & Continue' : 'Send Verification OTP'),
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
    final altPhoneCtrl = TextEditingController(text: AppState.instance.userAlternatePhone ?? '');
    final emailCtrl = TextEditingController(text: AppState.instance.userEmail ?? '');
    final cityCtrl = TextEditingController(text: AppState.instance.userLocation.city);
    final areaCtrl = TextEditingController(text: AppState.instance.userLocation.area);
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
                    'Edit Profile & Delivery Address',
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
                    controller: altPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Alternate Mobile Contact',
                      counterText: '',
                      prefixText: '+91 ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.phone_iphone_rounded),
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
                            labelText: 'City',
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
                  const SizedBox(height: 12),

                  TextField(
                    controller: areaCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Delivery Area / Locality / Street',
                      hintText: 'e.g. Gomti Nagar, Viram Khand',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.home_work_outlined),
                    ),
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty || name.length < 2) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter your full name (minimum 2 characters)')),
                                );
                                return;
                              }

                              final altPhone = altPhoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                              if (altPhone.isNotEmpty && (altPhone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(altPhone))) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Alternate mobile must be a valid 10-digit number (starts with 6-9)')),
                                );
                                return;
                              }

                              final email = emailCtrl.text.trim();
                              if (email.isNotEmpty && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email)) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid email address (e.g. name@domain.com)')),
                                );
                                return;
                              }

                              final pin = pincodeCtrl.text.trim();
                              if (pin.isNotEmpty && (pin.length != 6 || !RegExp(r'^[1-9]\d{5}$').hasMatch(pin))) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid 6-digit postal pincode')),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final messenger = ScaffoldMessenger.of(context);

                              await AppState.instance.updateProfileDetails(
                                name: name,
                                alternatePhone: altPhone.isNotEmpty ? '+91 $altPhone' : null,
                                email: email.isNotEmpty ? email : null,
                                city: cityCtrl.text.trim(),
                                area: areaCtrl.text.trim(),
                                pincode: pin.isNotEmpty ? pin : null,
                              );

                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                              }

                              if (mounted) {
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    backgroundColor: _forestGreen,
                                    content: Text('✅ Profile and location updated successfully!'),
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

}
