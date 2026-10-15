import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/flip_phone_stock_card.dart';
import 'package:ecofone/screens/location_sheet.dart';
import 'package:ecofone/state/app_state.dart';

class StockScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onCartTap;

  const StockScreen({
    super.key,
    this.onProfileTap,
    this.onCartTap,
  });

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _OfferBanner {
  final String badge;
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final List<Color> gradient;
  final Color badgeBg;
  final Color badgeText;

  const _OfferBanner({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.gradient,
    required this.badgeBg,
    required this.badgeText,
  });
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  // Brand colors matched to official EcoFone logo
  static const _bgColor = EcoColors.background;
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;

  final TextEditingController _searchController = TextEditingController();
  String _selectedBrand = 'All';
  String _selectedGrade = 'All';
  String _selectedStorage = 'All';
  String _selectedBudget = 'All';
  bool _isLoading = false;

  Set<String> get _wishlistedIds => AppState.instance.wishlistedIds;

  final List<String> _brands = const ['All', 'Apple', 'Samsung', 'OnePlus', 'Google', 'Xiaomi'];
  final List<String> _grades = const ['All', 'Superb (Pristine)', 'Very Good', 'Good'];
  final List<String> _storages = const ['All', '128 GB', '256 GB', '512 GB'];
  final List<String> _budgets = const ['All', 'Under ₹20K', '₹20K - ₹40K', '₹40K - ₹60K', '₹60K+'];

  // Real-Time Live Refurbished Phone Inventory connected directly to POS / Billing API
  List<PhoneStockItem> get _inventory => AppState.instance.liveInventory;

  List<PhoneStockItem> get _filteredInventory {
    return _inventory.where((item) {
      final matchesBrand = _selectedBrand == 'All' || item.brand == _selectedBrand;
      final matchesGrade = _selectedGrade == 'All' || item.conditionGrade == _selectedGrade;
      final matchesStorage = _selectedStorage == 'All' || item.storage == _selectedStorage;
      final matchesBudget = switch (_selectedBudget) {
        'Under ₹20K' => item.refurbishedPrice < 20000,
        '₹20K - ₹40K' => item.refurbishedPrice >= 20000 && item.refurbishedPrice < 40000,
        '₹40K - ₹60K' => item.refurbishedPrice >= 40000 && item.refurbishedPrice < 60000,
        '₹60K+' => item.refurbishedPrice >= 60000,
        _ => true,
      };
      final query = _searchController.text.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.brand.toLowerCase().contains(query) ||
          item.color.toLowerCase().contains(query);

      return matchesBrand && matchesGrade && matchesStorage && matchesBudget && matchesQuery;
    }).toList();
  }



  static const List<_OfferBanner> _offerBanners = [
    _OfferBanner(
      badge: 'MEGA SALE',
      title: 'Upgrade to iPhone 14 Pro',
      subtitle: 'Flat ₹5,000 extra exchange bonus on your old smartphone',
      cta: 'Claim Offer',
      icon: Icons.local_fire_department_rounded,
      gradient: [Color(0xFF13583C), Color(0xFF0D3B28)],
      badgeBg: Color(0xFFEA580C),
      badgeText: Colors.white,
    ),
    _OfferBanner(
      badge: 'EXPRESS DELIVERY',
      title: 'Free Doorstep Delivery & 2-Hr Pickup',
      subtitle: 'Fast dispatch, verified 32-point diagnostics & 7-day return guarantee!',
      cta: 'Shop Now',
      icon: Icons.local_shipping_rounded,
      gradient: [Color(0xFFEA580C), Color(0xFFC2410C)],
      badgeBg: Colors.white,
      badgeText: Color(0xFFC2410C),
    ),
    _OfferBanner(
      badge: 'BANK OFFER',
      title: 'Flat ₹2,500 Instant Cashback',
      subtitle: 'On orders above ₹30,000 via HDFC, ICICI, SBI & UPI',
      cta: 'View Cards',
      icon: Icons.credit_card_rounded,
      gradient: [Color(0xFF78350F), Color(0xFF451A03)],
      badgeBg: Color(0xFFFEF3C7),
      badgeText: Color(0xFF92400E),
    ),
    _OfferBanner(
      badge: '6-MONTH WARRANTY',
      title: 'Pan-India Certified Guarantee',
      subtitle: '100% genuine components with free doorstep pickup & repair',
      cta: 'Learn More',
      icon: Icons.shield_rounded,
      gradient: [Color(0xFF065F46), Color(0xFF064E3B)],
      badgeBg: Color(0xFFD1FAE5),
      badgeText: Color(0xFF065F46),
    ),
  ];

  late final PageController _bannerPageController;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_bannerPageController.hasClients) return;
      final nextIndex = (_currentBannerIndex + 1) % _offerBanners.length;
      _bannerPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(viewportFraction: 0.92);
    _startBannerTimer();
    AppState.instance.addListener(_onAppStateChanged);
    if (AppState.instance.wishlistedIds.isEmpty) {
      AppState.instance.wishlistedIds.addAll({'EF-101', 'EF-103', 'EF-105'});
    }
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredInventory;

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
            await AppState.instance.refreshInventory();
            if (mounted) setState(() => _isLoading = false);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildTopBar(),
              _buildGreetingAndHeadline(),
              _buildSearchBarWithFilter(),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              _buildOffersCarousel(),
              _buildSellOldPhoneBanner(),
              _buildBrandSelector(),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              _buildStockList(items),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Sell Old Phone Interactive Promo Banner ---
  Widget _buildSellOldPhoneBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: BouncingWidget(
          scaleFactor: 0.97,
          onTap: () => Navigator.of(context).pushNamed('/trade_in'),
          child: LuxuryShimmerSweep(
            interval: const Duration(seconds: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EcoColors.mintBorder),
                boxShadow: [
                  BoxShadow(
                    color: _forestGreen.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_forestGreen, EcoColors.darkEmerald],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _forestGreen.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.currency_rupee_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Sell Your Old Phone',
                              style: TextStyle(
                                color: _forestGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: EcoColors.vibrantOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'INSTANT CASH',
                              style: TextStyle(
                                color: EcoColors.vibrantOrange,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Instant valuation in 30 sec • 15-min UPI payout',
                        style: TextStyle(
                          color: _forestGreen.withOpacity(0.65),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: _forestGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  // --- Offers Banner Carousel (3-4 High-Converting Banners) ---
  Widget _buildOffersCarousel() {
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 126,
            child: PageView.builder(
              controller: _bannerPageController,
              itemCount: _offerBanners.length,
              onPageChanged: (index) => setState(() => _currentBannerIndex = index),
              itemBuilder: (context, index) {
                final banner = _offerBanners[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: banner.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: banner.gradient.first.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Icon(
                            banner.icon,
                            size: 105,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: banner.badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  banner.badge,
                                  style: TextStyle(
                                    color: banner.badgeText,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    banner.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 11,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      banner.cta,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.white),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Animated dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_offerBanners.length, (i) {
              final isSelected = i == _currentBannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                height: 4.5,
                width: isSelected ? 18 : 5,
                decoration: BoxDecoration(
                  color: isSelected ? EcoColors.vibrantOrange : Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // --- 1. Authentic Luxury EcoFone Brand Top Bar (Matches Official Logo & Theme) ---
  Widget _buildTopBar() {
    final initials = _getUserInitials();
    final cartCount = AppState.instance.reservations.length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Official EcoFone Brand Horizontal Logo (Uploaded by User)
            Image.asset(
              'assets/logo/ecofone_horizontal_logo.png',
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/logo/logo_transparent.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),

            // Right Action Controls: Shopping Bag & User Avatar Circle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shopping Bag Button
                BouncingWidget(
                  scaleFactor: 0.92,
                  onTap: () {
                    if (widget.onCartTap != null) {
                      widget.onCartTap!();
                    } else {
                      Navigator.of(context).pushNamed('/trade_in');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 23,
                          color: Color(0xFF0F172A),
                        ),
                        if (cartCount > 0)
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: EcoColors.vibrantOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // User Avatar Circle with Initials
                BouncingWidget(
                  scaleFactor: 0.92,
                  onTap: () {
                    if (widget.onProfileTap != null) {
                      widget.onProfileTap!();
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9), // Pale mint green
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.plusJakartaSans(
                        color: EcoColors.forestGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Location Sub-line, Greeting & Display Headline ---
  Widget _buildGreetingAndHeadline() {
    final greeting = _getTimeGreeting();
    final userName = _getUserFirstName();
    final loc = AppState.instance.userLocation;
    final locationText = loc.area.isNotEmpty
        ? 'Delivering to ${loc.area}, ${loc.city}'
        : 'Delivering to ${loc.city.isNotEmpty ? loc.city : 'Indiranagar, Bengaluru'}';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location / Delivery Line
            GestureDetector(
              onTap: () => LocationSelectorSheet.show(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: EcoColors.forestGreen,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      locationText,
                      style: GoogleFonts.plusJakartaSans(
                        color: EcoColors.forestGreen,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: EcoColors.forestGreen,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Personalized Greeting
            Text(
              '$greeting, $userName',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 6),

            // Big Bold Display Headline in Modern Font Style (Single Line)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                maxLines: 1,
                softWrap: false,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Find your next ',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF0F172A),
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: 'great phone.',
                      style: GoogleFonts.plusJakartaSans(
                        color: EcoColors.forestGreen,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
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

  // --- 3. Modern Pill Search Bar with Integrated Filter Button ---
  Widget _buildSearchBarWithFilter() {
    final hasActiveFilter = _selectedBudget != 'All' ||
        _selectedGrade != 'All' ||
        _selectedStorage != 'All';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search Icon
              const Padding(
                padding: EdgeInsets.only(left: 15, right: 10),
                child: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 21,
                ),
              ),

              // Search Text Field in Modern Font Style
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search iPhone, Samsung, Pixel...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),

              // Integrated Filter Button on the Right
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: BouncingWidget(
                  scaleFactor: 0.92,
                  onTap: _showComprehensiveFilterSheet,
                  child: Container(
                    width: 44,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasActiveFilter
                          ? EcoColors.forestGreen
                          : const Color(0xFFE8F5E9), // Pale mint green
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 19,
                          color: hasActiveFilter
                              ? Colors.white
                              : EcoColors.forestGreen,
                        ),
                        if (hasActiveFilter)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: EcoColors.vibrantOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
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

  String _getUserInitials() {
    final name = AppState.instance.userName?.trim();
    if (name == null || name.isEmpty || name == 'Valued Customer') {
      return 'AM';
    }
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getUserFirstName() {
    final name = AppState.instance.userName?.trim();
    if (name == null || name.isEmpty || name == 'Valued Customer') {
      return 'Aarav';
    }
    return name.split(RegExp(r'\s+')).first;
  }

  // --- 3. Single Prominent Brand Strip ---
  Widget _buildBrandSelector() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _brands.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final brand = _brands[index];
            final isSelected = brand == _selectedBrand;
            return BouncingWidget(
              scaleFactor: 0.94,
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedBrand = brand);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? EcoColors.forestGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? EcoColors.forestGreen : Colors.black.withOpacity(0.08),
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: EcoColors.forestGreen.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  brand,
                  style: TextStyle(
                    color: isSelected ? Colors.white : EcoColors.forestGreen,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Comprehensive Filter Modal (Senior/Executive Clean UX) ---
  void _showComprehensiveFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Inventory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: EcoColors.forestGreen,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBudget = 'All';
                          _selectedGrade = 'All';
                          _selectedStorage = 'All';
                        });
                        setModalState(() {});
                      },
                      child: const Text('Reset All', style: TextStyle(color: EcoColors.vibrantOrange, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Budget Section
                const Text('Price Budget', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: EcoColors.forestGreen)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _budgets.map((b) {
                    final selected = b == _selectedBudget;
                    return ChoiceChip(
                      label: Text(b),
                      selected: selected,
                      selectedColor: EcoColors.forestGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : EcoColors.forestGreen,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (val) {
                        setState(() => _selectedBudget = val ? b : 'All');
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Condition Grade Section with Grade Guide trigger
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Condition Grade', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: EcoColors.forestGreen)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _showGradeGuideBottomSheet();
                      },
                      child: const Text('Grade Guide ℹ️', style: TextStyle(fontSize: 11.5, color: EcoColors.vibrantOrange, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _grades.map((g) {
                    final selected = g == _selectedGrade;
                    return ChoiceChip(
                      label: Text(g),
                      selected: selected,
                      selectedColor: EcoColors.vibrantOrange,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : EcoColors.forestGreen,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (val) {
                        setState(() => _selectedGrade = val ? g : 'All');
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Storage Section
                const Text('Storage Capacity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: EcoColors.forestGreen)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _storages.map((s) {
                    final selected = s == _selectedStorage;
                    return ChoiceChip(
                      label: Text(s),
                      selected: selected,
                      selectedColor: EcoColors.forestGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : EcoColors.forestGreen,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (val) {
                        setState(() => _selectedStorage = val ? s : 'All');
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoColors.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Apply Filters (${_filteredInventory.length} Phones)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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

  void _showGradeGuideBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EcoFone Condition Guide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: EcoColors.forestGreen,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Transparent, Cashify-standard quality grading',
                        style: TextStyle(fontSize: 12, color: EcoColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildGradeGuideCard(
                title: 'Superb (Pristine)',
                subtitle: 'Flawless like-new condition',
                icon: Icons.star_rounded,
                badgeColor: EcoColors.mintGreen,
                badgeBg: EcoColors.mintLight,
                points: const [
                  'Zero scratches or dents on screen & body frame',
                  'Original battery health certified at 90% - 100%',
                  '100% factory original display, cameras & chassis',
                  'Includes 6-Month Full Comprehensive Warranty',
                ],
              ),
              const SizedBox(height: 10),
              _buildGradeGuideCard(
                title: 'Very Good',
                subtitle: 'Minor micro-scuffs only visible close up',
                icon: Icons.thumb_up_alt_rounded,
                badgeColor: EcoColors.vibrantOrange,
                badgeBg: EcoColors.softOrange,
                points: const [
                  '1-2 faint micro-abrasions invisible from normal viewing',
                  'Display glass is 100% flawless with zero cracks',
                  'Original battery health certified at 85% - 92%',
                  'Best balance of premium quality & huge savings',
                ],
              ),
              const SizedBox(height: 10),
              _buildGradeGuideCard(
                title: 'Good',
                subtitle: 'Budget champion with maximum discount',
                icon: Icons.discount_rounded,
                badgeColor: EcoColors.luxuryBronze,
                badgeBg: const Color(0xFFFBF5F0),
                points: const [
                  'Visible pocket scuffs/marks on body frame only',
                  'Screen 100% intact, no lines or dead pixels',
                  'Fully tested on 32-point diagnostics with 6-Month warranty',
                  'Deepest discount (save up to 60% off MSRP)',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeGuideCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required Color badgeBg,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: EcoColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: badgeColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: EcoColors.forestGreen,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // --- Stock Item List ---
  Widget _buildStockList(List<PhoneStockItem> items) {
    if (_isLoading || AppState.instance.isInventoryLoading) {
      return const StockGridSkeletonView(itemCount: 6);
    }
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 54, color: _forestGreen.withOpacity(0.3)),
              const SizedBox(height: 14),
              const Text(
                'No matching stock found',
                style: TextStyle(
                  color: _forestGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try clearing filters or search for another phone model',
                style: TextStyle(
                  color: _forestGreen.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedBrand = 'All';
                    _selectedGrade = 'All';
                    _selectedStorage = 'All';
                  });
                },
                child: const Text('Reset All Filters', style: TextStyle(color: _copper)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.57,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return FadeSlideEntry(
              delayMs: (index * 40).clamp(0, 320),
              child: _buildStockGridCard(item),
            );
          },
          childCount: items.length,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: true,
        ),
      ),
    );
  }

  // --- Stock Grid Card (3D Interactive Flip Card) ---
  Widget _buildStockGridCard(PhoneStockItem item) {
    final bool isWishlisted = _wishlistedIds.contains(item.id);

    return FlipPhoneStockCard(
      item: item,
      allPhones: _inventory,
      isWishlisted: isWishlisted,
      onWishlistToggle: () {
        AppState.instance.toggleWishlist(item.id);
      },
    );
  }
}

