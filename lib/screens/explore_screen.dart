import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/core/widgets/brand_logo.dart';
import 'package:ecofone/screens/directions_sheet.dart';
import 'package:ecofone/state/app_state.dart';

class ExploreScreen extends StatefulWidget {
  final VoidCallback? onTradeInTap;

  const ExploreScreen({super.key, this.onTradeInTap});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  static const _bgColor = EcoColors.background;
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;
  static const _softGreen = EcoColors.mintGreen;

  String _selectedCityFilter = 'Nearest';
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isLoadingStores = false;

  final List<String> _cityFilters = const [
    'Nearest',
    'Lucknow',
    'Gorakhpur',
    'Delhi NCR',
    'Mumbai',
    'Bengaluru',
    'Hyderabad',
    'Pune',
    'Prayagraj',
    'Bareilly',
    'Saharanpur',
    'Shravasti',
  ];

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onAppStateChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final nearest = AppState.instance.nearestStore;
    final List<EcoStore> displayedStores = _getFilteredStores();

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildTopHeader(),
            _buildGpsLocationBanner(),
            _buildCityFilterStrip(),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (_selectedCityFilter == 'Nearest' || _selectedCityFilter == AppState.instance.selectedCity)
              _buildNearestStoreHero(nearest),
            _buildStoresDirectoryHeader(displayedStores.length),
            _buildStoresList(displayedStores),
            _buildWhyVisitSection(),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  List<EcoStore> _getFilteredStores() {
    List<EcoStore> stores;
    if (_selectedCityFilter == 'Nearest') {
      stores = AppState.allStores;
    } else {
      stores = AppState.instance.getStoresForCity(_selectedCityFilter);
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      stores = stores.where((s) =>
          s.name.toLowerCase().contains(query) ||
          s.area.toLowerCase().contains(query) ||
          s.city.toLowerCase().contains(query) ||
          s.pincode.contains(query) ||
          s.address.toLowerCase().contains(query)).toList();
    }
    return stores;
  }

  // --- 1. Top Header ---
  Widget _buildTopHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: EcoFoneHeaderLogo(
                emblemSize: 42,
                titleSize: 22,
                subtitleSize: 10.5,
                customSubtitle: 'Stores • Luxury within reach',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _softGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _softGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, size: 15, color: _softGreen),
                  const SizedBox(width: 4),
                  Text(
                    '${AppState.allStores.length} Hubs',
                    style: const TextStyle(
                      color: _softGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  // --- 2. GPS Location Banner ---
  Widget _buildGpsLocationBanner() {
    final isLocating = AppState.instance.isGpsLocating;
    final currentCity = AppState.instance.selectedCity;
    final currentPincode = AppState.instance.selectedPincode;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                  color: _copper.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isLocating
                    ? const EcoCircularProgressLoader(size: 20, color: _copper, strokeWidth: 2.4)
                    : const Icon(Icons.my_location_rounded, color: _copper, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Your Area: $currentCity',
                            style: const TextStyle(
                              color: _forestGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _softGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentPincode,
                            style: const TextStyle(color: _softGreen, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLocating ? 'Detecting nearest EcoFone hub via GPS...' : 'Showing verified stores closest to your location',
                      style: TextStyle(
                        color: _forestGreen.withOpacity(0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: isLocating
                    ? null
                    : () {
                        AppState.instance.triggerGpsLocation(() {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📍 Location synced to $currentCity! Nearest store highlighted below.'),
                              backgroundColor: _forestGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Detect', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. City Filter Strip ---
  Widget _buildCityFilterStrip() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _cityFilters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final city = _cityFilters[index];
            final isSelected = city == _selectedCityFilter;
            return GestureDetector(
              onTap: () {
                if (_selectedCityFilter != city) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCityFilter = city;
                    _isLoadingStores = true;
                  });
                  Future.delayed(const Duration(milliseconds: 320), () {
                    if (mounted) setState(() => _isLoadingStores = false);
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _forestGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _forestGreen : Colors.black.withOpacity(0.08),
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: _forestGreen.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (city == 'Nearest') ...[
                      Icon(Icons.near_me_rounded, size: 13, color: isSelected ? Colors.white : _copper),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      city,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _forestGreen,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- 4. Nearest Store Hero Card (Prominent Highlight) ---
  Widget _buildNearestStoreHero(EcoStore store) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _copper.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _copper.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner with Distance Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_forestGreen, Color(0xFF13583C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: EcoColors.brightAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'NEAREST STORE TO YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _copper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📍 ${AppState.instance.getLiveDistanceFrom(store)} km away',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (store.id == 'EF-STORE-LKO-01') ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: EcoColors.softOrange,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: EcoColors.orangeBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 13, color: EcoColors.vibrantOrange),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED OFFICIAL FLAGSHIP STORE',
                              style: TextStyle(
                                color: EcoColors.vibrantOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Store Name + Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: const TextStyle(
                                  color: _forestGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                store.address,
                                style: TextStyle(
                                  color: _forestGreen.withOpacity(0.75),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: EcoColors.softOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: EcoColors.vibrantOrange),
                              const SizedBox(width: 2),
                              Text(
                                '${store.rating}',
                                style: const TextStyle(
                                  color: _forestGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Timings & Metro guide
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 14, color: _softGreen),
                        const SizedBox(width: 5),
                        Text(
                          store.timings,
                          style: const TextStyle(
                            color: _softGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.directions_subway_rounded, size: 14, color: _forestGreen.withOpacity(0.6)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            store.metroStation,
                            style: TextStyle(
                              color: _forestGreen.withOpacity(0.65),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Services Badges Wrap
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: store.services.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: _bgColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 12, color: _softGreen),
                              const SizedBox(width: 4),
                              Text(
                                service,
                                style: const TextStyle(
                                  color: _forestGreen,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showDirectionsSheet(store),
                            icon: const Icon(Icons.directions_rounded, size: 16, color: _forestGreen),
                            label: const Text('Directions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _forestGreen,
                              side: const BorderSide(color: _forestGreen),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showCallStoreDialog(store),
                            icon: const Icon(Icons.phone_outlined, size: 16, color: _copper),
                            label: const Text('Call Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _copper,
                              side: const BorderSide(color: _copper),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            onPressed: () => _showInStoreAppointmentModal(store),
                            icon: const Icon(Icons.event_available_rounded, size: 16, color: Colors.white),
                            label: const Text('Book Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _forestGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }

  // --- 5. Stores Directory Header ---
  Widget _buildStoresDirectoryHeader(int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCityFilter == 'Nearest' ? 'All Experience Hubs' : '$_selectedCityFilter Stores',
              style: const TextStyle(
                color: _forestGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$count stores available',
              style: TextStyle(
                color: _forestGreen.withOpacity(0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. Stores Directory Cards ---
  Widget _buildStoresList(List<EcoStore> stores) {
    if (_isLoadingStores) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: StoreCardSkeleton(),
            ),
            childCount: 3,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final store = stores[index];
            return FadeSlideEntry(
              delayMs: (index * 45).clamp(0, 350),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (store.isUpcoming) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: EcoColors.softOrange,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: EcoColors.orangeBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.rocket_launch_rounded, size: 11, color: EcoColors.vibrantOrange),
                            SizedBox(width: 4),
                            Text(
                              'UPCOMING STORE • OPENING SOON',
                              style: TextStyle(
                                color: EcoColors.vibrantOrange,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (store.id == 'EF-STORE-LKO-01') ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: EcoColors.mintLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: EcoColors.mintBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 11, color: EcoColors.mintGreen),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED FLAGSHIP HUB',
                              style: TextStyle(
                                color: EcoColors.mintGreen,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: const TextStyle(
                              color: _forestGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: store.isUpcoming ? EcoColors.softOrange : _softGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            store.isUpcoming ? 'Coming Soon' : '${AppState.instance.getLiveDistanceFrom(store)} km',
                            style: TextStyle(
                              color: store.isUpcoming ? EcoColors.vibrantOrange : _softGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.address,
                      style: TextStyle(
                        color: _forestGreen.withOpacity(0.65),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          store.isUpcoming ? Icons.campaign_rounded : Icons.access_time_rounded,
                          size: 13,
                          color: store.isUpcoming ? EcoColors.vibrantOrange : _forestGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.timings,
                            style: TextStyle(
                              color: store.isUpcoming ? EcoColors.vibrantOrange : _forestGreen.withOpacity(0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          store.isUpcoming ? '🔥 Pre-Register' : '★ ${store.rating} (${store.reviewCount})',
                          style: TextStyle(
                            color: store.isUpcoming ? EcoColors.vibrantOrange : _copper,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: BouncingWidget(
                            scaleFactor: 0.96,
                            onTap: () => _showDirectionsSheet(store),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              alignment: Alignment.center,
                              child: const Text('View Location', style: TextStyle(fontSize: 11.5, color: _forestGreen, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BouncingWidget(
                            scaleFactor: 0.96,
                            onTap: () {
                              if (store.isUpcoming) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 Registered! You will get exclusive launch discounts for ${store.city} store.'),
                                    backgroundColor: _forestGreen,
                                  ),
                                );
                              } else {
                                _showInStoreAppointmentModal(store);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: store.isUpcoming ? EcoColors.vibrantOrange : _forestGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                store.isUpcoming ? 'Notify on Launch' : 'Book Slot',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
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
          },
          childCount: stores.length,
        ),
      ),
    );
  }

  // --- 7. Why Visit Section ---
  Widget _buildWhyVisitSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: _softGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Why Visit an EcoFone Store?',
                    style: TextStyle(
                      color: _forestGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildWhyRow(
                icon: Icons.hardware_rounded,
                title: '32-Point Hardware Test Bench',
                subtitle: 'Test screen response, cameras, battery cycles & speakers on our live diagnostics rig.',
              ),
              const SizedBox(height: 10),
              _buildWhyRow(
                icon: Icons.payments_outlined,
                title: 'Instant Cash on Desk in 15 Mins',
                subtitle: 'Walk in with your old phone and walk out with instant UPI cash or exchange bonus.',
              ),
              const SizedBox(height: 10),
              _buildWhyRow(
                icon: Icons.shield_rounded,
                title: 'Cashless 6-Month Free Repairs',
                subtitle: 'Direct walk-in access for same-day battery & display warranty service.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhyRow({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _softGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _softGreen),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _forestGreen.withOpacity(0.65),
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Modals & Sheets ---
  void _showDirectionsSheet(EcoStore store) {
    StoreDirectionsSheet.show(context, store);
  }

  void _showCallStoreDialog(EcoStore store) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: _copper),
            SizedBox(width: 8),
            Text('Call Store Desk'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, color: _forestGreen)),
            const SizedBox(height: 6),
            Text('📞 ${store.phone}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _copper)),
            const SizedBox(height: 6),
            Text('Operating Hours: ${store.timings}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: store.phone));
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📞 Store phone copied: ${store.phone}'),
                  backgroundColor: _forestGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _forestGreen),
            child: const Text('Copy & Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInStoreAppointmentModal(EcoStore store) {
    String selectedService = 'Inspect Refurbished Phones';
    String selectedDate = 'Today';
    String selectedTime = '4:00 PM - 5:00 PM';
    final nameCtrl = TextEditingController(text: AppState.instance.userName ?? '');
    final phoneCtrl = TextEditingController(text: AppState.instance.userPhone ?? '');

    final services = [
      'Inspect Refurbished Phones',
      'Sell Old Phone for Instant Cash',
      'Claim 6-Month Warranty Repair',
    ];
    final dates = ['Today', 'Tomorrow', 'Day After'];
    final timeSlots = [
      '11:00 AM - 12:00 PM',
      '2:00 PM - 3:00 PM',
      '4:00 PM - 5:00 PM',
      '6:30 PM - 7:30 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 16,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 26,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 14),
                  const Text('Book VIP In-Store Visit', style: TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(store.name, style: TextStyle(color: _forestGreen.withOpacity(0.65), fontSize: 12)),
                  const SizedBox(height: 14),
                  // Service Type Chips
                  const Text('Select Service:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _forestGreen)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: services.map((s) {
                      final isSel = s == selectedService;
                      return ChoiceChip(
                        label: Text(s, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : _forestGreen, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        selected: isSel,
                        selectedColor: _forestGreen,
                        backgroundColor: _bgColor,
                        onSelected: (val) => setModalState(() => selectedService = s),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Date & Time Slot
                  const Text('Select Date & Time:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _forestGreen)),
                  const SizedBox(height: 6),
                  Row(
                    children: dates.map((d) {
                      final isSel = d == selectedDate;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(d, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : _forestGreen, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          selectedColor: _copper,
                          backgroundColor: _bgColor,
                          onSelected: (val) => setModalState(() => selectedDate = d),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: timeSlots.map((t) {
                      final isSel = t == selectedTime;
                      return ChoiceChip(
                        label: Text(t, style: TextStyle(fontSize: 10.5, color: isSel ? Colors.white : _forestGreen)),
                        selected: isSel,
                        selectedColor: _forestGreen,
                        backgroundColor: _bgColor,
                        onSelected: (val) => setModalState(() => selectedTime = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Name & Phone
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Your Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number for SMS Pass',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final aptId = 'ECO-VIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                        final customerName = nameCtrl.text.trim().isEmpty ? (AppState.instance.userName ?? 'Valued Customer') : nameCtrl.text.trim();
                        final customerPhone = phoneCtrl.text.trim().isEmpty ? (AppState.instance.userPhone ?? '+91 98765 43210') : phoneCtrl.text.trim();

                        final appointment = InStoreAppointment(
                          appointmentId: aptId,
                          storeId: store.id,
                          storeName: store.name,
                          serviceType: selectedService,
                          date: selectedDate,
                          timeSlot: selectedTime,
                          customerName: customerName,
                          customerPhone: customerPhone,
                          createdAt: DateTime.now(),
                        );
                        AppState.instance.bookInStoreAppointment(appointment);

                        if (!AppState.instance.isLoggedIn && phoneCtrl.text.trim().isNotEmpty) {
                          AppState.instance.login(name: customerName, phone: customerPhone);
                        }

                        Navigator.pop(sheetCtx);
                        _showAppointmentSuccessDialog(appointment);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm VIP Appointment Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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

  void _showAppointmentSuccessDialog(InStoreAppointment apt) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _softGreen.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: _softGreen, size: 46),
            ),
            const SizedBox(height: 14),
            Text(
              'VIP Pass #${apt.appointmentId}',
              style: const TextStyle(color: _forestGreen, fontWeight: FontWeight.bold, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Your VIP visit is booked at ${apt.storeName} for ${apt.date} (${apt.timeSlot}). Our store manager will keep the diagnostic test bench ready for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _forestGreen.withOpacity(0.7), fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: ElevatedButton.styleFrom(backgroundColor: _copper, foregroundColor: Colors.white),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
