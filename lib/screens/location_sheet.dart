import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecofone/core/theme/anim_utils.dart';
import 'package:ecofone/core/theme/app_theme.dart';
import 'package:ecofone/screens/directions_sheet.dart';
import 'package:ecofone/state/app_state.dart';

/// Interactive EcoFone Retail Store & Visiting Hub Selector
class LocationSelectorSheet extends StatefulWidget {
  const LocationSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationSelectorSheet(),
    );
  }

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  static const _forestGreen = EcoColors.forestGreen;
  static const _copper = EcoColors.vibrantOrange;
  static const _softGreen = EcoColors.mintGreen;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pincodeInputController = TextEditingController();
  String _searchQuery = '';

  final List<String> _popularCities = const [
    'Lucknow',
    'Gorakhpur',
    'Delhi NCR',
    'Mumbai',
    'Bengaluru',
    'Prayagraj',
    'Bareilly',
    'Saharanpur',
    'Shravasti',
    'Kanpur',
    'Varanasi',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _pincodeInputController.dispose();
    super.dispose();
  }

  List<EcoStore> get _filteredStores {
    List<EcoStore> list = List.from(AppState.allStores);

    // Apply search query
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          s.area.toLowerCase().contains(q) ||
          s.city.toLowerCase().contains(q) ||
          s.pincode.contains(q) ||
          s.address.toLowerCase().contains(q)).toList();
    }

    // Sort by distance if GPS coordinates available
    if (AppState.instance.userLocation.latitude != null) {
      list.sort((a, b) => AppState.instance.getLiveDistanceFrom(a).compareTo(AppState.instance.getLiveDistanceFrom(b)));
    }

    return list;
  }

  void _onGpsTap() {
    AppState.instance.triggerGpsLocation(() {
      if (mounted) {
        final nearest = AppState.instance.selectedStore;
        final loc = AppState.instance.userLocation;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _forestGreen,
            content: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: EcoColors.brightAmber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '📍 GPS: ${loc.shortDisplay} • Nearest: ${nearest.name} (${AppState.instance.getLiveDistanceFrom(nearest)} km)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  void _applyManualLocation(String query) {
    if (query.trim().isEmpty) return;
    
    final resolved = AppState.resolvePincodeOrCity(query);
    AppState.instance.setManualLocation(
      resolved.city,
      resolved.pincode,
      area: resolved.area,
      lat: resolved.lat,
      lng: resolved.lng,
    );

    Navigator.of(context).pop();

    final activeStore = AppState.instance.selectedStore;
    final dist = AppState.instance.getLiveDistanceFrom(activeStore);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _forestGreen,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: EcoColors.brightAmber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '📍 Location set to: ${resolved.area}, ${resolved.city} • Nearest Hub: ${activeStore.name} ($dist km)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStore = AppState.instance.selectedStore;
    final userLoc = AppState.instance.userLocation;
    final stores = _filteredStores;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _forestGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: _copper, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Location & Select Store',
                          style: TextStyle(
                            color: _forestGreen,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enter your pincode, city, or choose an EcoFone store hub',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                children: [
                  // 1. Current Location Banner with GPS Detection
                  _buildGpsDetectorCard(userLoc),
                  const SizedBox(height: 14),

                  // 2. Direct Manual Pincode / City Input Bar
                  _buildManualPincodeInputBox(),
                  const SizedBox(height: 14),

                  // 3. Search Bar for Store Directory & Cities
                  _buildSearchBar(),
                  
                  // If user has typed a query, show instant "Set Location to Query" tile
                  if (_searchQuery.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInstantSetLocationTile(_searchQuery.trim()),
                  ],
                  const SizedBox(height: 14),

                  // 4. Quick Popular Cities
                  _buildQuickCitySection(),
                  const SizedBox(height: 16),

                  // 5. Currently Selected Active Store Hero Card
                  _buildActiveStoreBanner(activeStore),
                  const SizedBox(height: 18),

                  // 6. Store Directory Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Store Hubs (${stores.length})',
                        style: const TextStyle(
                          color: _forestGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Tap any store to select',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 7. Stores List
                  ...stores.map((store) => _buildStoreTile(store, store.id == activeStore.id)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. GPS Detector Banner ---
  Widget _buildGpsDetectorCard(UserLocation userLoc) {
    final isLocating = AppState.instance.isGpsLocating;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_forestGreen.withOpacity(0.06), _softGreen.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _forestGreen.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _forestGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isLocating
                ? const EcoCircularProgressLoader(
                    size: 18,
                    color: EcoColors.brightAmber,
                    strokeWidth: 2.2,
                  )
                : const Icon(Icons.my_location_rounded, color: EcoColors.brightAmber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userLoc.isGpsDetected ? 'GPS Auto-Detected' : 'Current Active Location',
                      style: const TextStyle(
                        color: _forestGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (userLoc.isGpsDetected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _softGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('LIVE GPS', style: TextStyle(color: _softGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  userLoc.fullDisplay,
                  style: TextStyle(
                    color: _forestGreen.withOpacity(0.75),
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isLocating ? null : _onGpsTap,
            icon: const Icon(Icons.gps_fixed_rounded, size: 13),
            label: const Text('Detect GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _forestGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Direct Manual Pincode / City Input Box ---
  Widget _buildManualPincodeInputBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EcoColors.mintLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.mintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_location_alt_rounded, size: 16, color: _forestGreen),
              SizedBox(width: 6),
              Text(
                'Enter Pincode or City Manually',
                style: TextStyle(
                  color: _forestGreen,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: TextField(
                    controller: _pincodeInputController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(fontSize: 13, color: _forestGreen, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g. 226010, Gorakhpur, Delhi...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.35)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _applyManualLocation,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _applyManualLocation(_pincodeInputController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _copper,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. Instant Set Location Action Tile ---
  Widget _buildInstantSetLocationTile(String query) {
    final resolved = AppState.resolvePincodeOrCity(query);

    return InkWell(
      onTap: () => _applyManualLocation(query),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _copper.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _copper.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_location_alt_rounded, size: 18, color: _copper),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Location to: "${resolved.area}, ${resolved.city}"',
                    style: const TextStyle(
                      color: _forestGreen,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Pincode: ${resolved.pincode} • Tap to apply this manual location',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _copper,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Set Location', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Search Bar ---
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: EcoColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontSize: 13.5, color: _forestGreen),
        decoration: InputDecoration(
          hintText: 'Search stores, areas, or cities...',
          hintStyle: TextStyle(fontSize: 12.5, color: Colors.black.withOpacity(0.4)),
          prefixIcon: const Icon(Icons.search_rounded, color: _forestGreen, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // --- 5. Quick Popular Cities Chips ---
  Widget _buildQuickCitySection() {
    final activeCity = AppState.instance.userLocation.city;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Popular Cities',
          style: TextStyle(
            color: _forestGreen,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _popularCities.map((city) {
              final isCurrent = activeCity.toLowerCase().contains(city.toLowerCase());
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(
                    isCurrent ? Icons.check_circle_rounded : Icons.location_city_rounded,
                    size: 14,
                    color: isCurrent ? Colors.white : _forestGreen,
                  ),
                  label: Text(
                    city,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? Colors.white : _forestGreen,
                    ),
                  ),
                  backgroundColor: isCurrent ? _forestGreen : EcoColors.background,
                  side: BorderSide(color: isCurrent ? _forestGreen : Colors.black.withOpacity(0.08)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onPressed: () => _applyManualLocation(city),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- 6. Active Selected Store Hero Card ---
  Widget _buildActiveStoreBanner(EcoStore store) {
    final distance = AppState.instance.getLiveDistanceFrom(store);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _forestGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _forestGreen.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EcoColors.brightAmber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: _forestGreen, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE VISITING HUB',
                      style: TextStyle(
                        color: _forestGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📍 $distance km away',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            store.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            store.address,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => StoreDirectionsSheet.show(context, store),
                  icon: const Icon(Icons.directions_rounded, size: 16, color: Colors.white),
                  label: const Text('Get Directions', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: store.phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phone number copied: ${store.phone}'),
                        backgroundColor: _copper,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_rounded, size: 16, color: _forestGreen),
                  label: Text(store.phone, style: const TextStyle(color: _forestGreen, fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoColors.brightAmber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. Store Tile Card ---
  Widget _buildStoreTile(EcoStore store, bool isSelected) {
    final distance = AppState.instance.getLiveDistanceFrom(store);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? _forestGreen.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? _forestGreen : Colors.black.withOpacity(0.08),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () => _onStoreSelect(store),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: store.isUpcoming
                ? _copper.withOpacity(0.12)
                : (isSelected ? _forestGreen : _softGreen.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            store.isUpcoming ? Icons.upcoming_rounded : Icons.storefront_rounded,
            color: store.isUpcoming ? _copper : (isSelected ? Colors.white : _forestGreen),
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                store.name,
                style: const TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (store.isUpcoming)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _copper.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'UPCOMING',
                  style: TextStyle(
                    color: _copper,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              store.address,
              style: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 12, color: _copper),
                const SizedBox(width: 3),
                Text(
                  '$distance km away',
                  style: const TextStyle(
                    color: _copper,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '• ${store.timings}',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: _forestGreen, size: 22)
            : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
      ),
    );
  }

  void _onStoreSelect(EcoStore store) {
    AppState.instance.selectStore(store);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _forestGreen,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Visiting Store set to: ${store.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

