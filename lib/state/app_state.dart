import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ecofone/services/location_service.dart';
import 'package:ecofone/models/user_profile.dart';
import 'package:ecofone/models/reservation_model.dart';
import 'package:ecofone/models/inventory_model.dart';
import 'package:ecofone/models/trade_in_model.dart';
import 'package:ecofone/services/storage/local_storage_service.dart';
import 'package:ecofone/services/backend/realtime_backend_service.dart';
import 'package:ecofone/services/backend/billing_api_service.dart';

export 'package:ecofone/models/reservation_model.dart';
export 'package:ecofone/models/user_profile.dart';
export 'package:ecofone/models/inventory_model.dart';
export 'package:ecofone/models/trade_in_model.dart';
export 'package:ecofone/services/backend/billing_api_service.dart';

/// User's real or selected geographic location
class UserLocation {
  final String city;
  final String area;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isGpsDetected;

  const UserLocation({
    required this.city,
    required this.area,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.isGpsDetected = false,
  });

  String get shortDisplay => area.isNotEmpty ? '$area, $city' : '$city ($pincode)';
  String get fullDisplay => area.isNotEmpty ? '$area, $city - $pincode' : '$city - $pincode';
}

/// EcoFone Physical Retail Store & Test Bench Hub
class EcoStore {
  final String id;
  final String name;
  final String city;
  final String pincode;
  final String area;
  final String address;
  final String phone;
  final String timings;
  final bool isOpen;
  final bool isUpcoming;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final List<String> services;
  final String landmark;
  final String metroStation;
  final double latitude;
  final double longitude;
  final String googleMapsUrl;

  const EcoStore({
    required this.id,
    required this.name,
    required this.city,
    required this.pincode,
    required this.area,
    required this.address,
    required this.phone,
    required this.timings,
    this.isOpen = true,
    this.isUpcoming = false,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.services,
    required this.landmark,
    required this.metroStation,
    required this.latitude,
    required this.longitude,
    required this.googleMapsUrl,
  });
}

/// VIP In-Store Visit Appointment
class InStoreAppointment {
  final String appointmentId;
  final String storeId;
  final String storeName;
  final String serviceType;
  final String date;
  final String timeSlot;
  final String customerName;
  final String customerPhone;
  final DateTime createdAt;

  const InStoreAppointment({
    required this.appointmentId,
    required this.storeId,
    required this.storeName,
    required this.serviceType,
    required this.date,
    required this.timeSlot,
    required this.customerName,
    required this.customerPhone,
    required this.createdAt,
  });
}

class AppState extends ChangeNotifier {
  // Singleton pattern
  static final AppState instance = AppState._internal();
  AppState._internal();

  // --- Real-Time GPS Location State ---
  bool hasPromptedInitialLocation = false;
  bool isGpsLocating = false;

  UserLocation userLocation = const UserLocation(
    city: 'Lucknow',
    area: 'Gomti Nagar & Transport Nagar',
    pincode: '226010',
    latitude: 26.8528,
    longitude: 80.9984,
    isGpsDetected: false,
  );

  EcoStore? _activeSelectedStore;

  String get selectedCity => userLocation.city;
  String get selectedPincode => userLocation.pincode;

  // Active Store: Explicitly selected or automatically closest
  EcoStore get selectedStore => _activeSelectedStore ?? nearestStore;

  void selectStore(EcoStore store) {
    _activeSelectedStore = store;
    userLocation = UserLocation(
      city: store.city,
      area: store.area,
      pincode: store.pincode,
      latitude: store.latitude,
      longitude: store.longitude,
      isGpsDetected: false,
    );
    notifyListeners();
  }

  /// Resolve city, area and GPS coordinates from query string or pincode
  static ({String city, String area, String pincode, double lat, double lng}) resolvePincodeOrCity(String query) {
    final q = query.trim().toLowerCase();
    
    // 1. Lucknow Region
    if (q.contains('lucknow') || q.contains('gomti') || q.contains('transport nagar') || q.contains('aliganj') || q.startsWith('226')) {
      return (city: 'Lucknow', area: 'Gomti Nagar & Transport Nagar', pincode: '226010', lat: 26.8528, lng: 80.9984);
    }
    // 2. Gorakhpur Region
    if (q.contains('gorakhpur') || q.contains('golghar') || q.contains('keshav') || q.startsWith('273')) {
      return (city: 'Gorakhpur', area: 'Golghar & Keshav Market', pincode: '273001', lat: 26.7606, lng: 83.3732);
    }
    // 3. Delhi NCR Region
    if (q.contains('delhi') || q.contains('noida') || q.contains('gurgaon') || q.contains('connaught') || q.startsWith('110') || q.startsWith('201') || q.startsWith('122')) {
      return (city: 'Delhi NCR', area: 'Connaught Place & Cyber City', pincode: '110001', lat: 28.6139, lng: 77.2090);
    }
    // 4. Mumbai Region
    if (q.contains('mumbai') || q.contains('bombay') || q.contains('bandra') || q.startsWith('400')) {
      return (city: 'Mumbai', area: 'Bandra West & BKC', pincode: '400050', lat: 19.0596, lng: 72.8295);
    }
    // 5. Bengaluru Region
    if (q.contains('bengaluru') || q.contains('bangalore') || q.contains('indiranagar') || q.contains('koramangala') || q.startsWith('560')) {
      return (city: 'Bengaluru', area: 'Indiranagar 100ft Road', pincode: '560038', lat: 12.9784, lng: 77.6408);
    }
    // 6. Prayagraj / Allahabad Region
    if (q.contains('prayagraj') || q.contains('allahabad') || q.contains('civil lines') || q.startsWith('211')) {
      return (city: 'Prayagraj', area: 'Civil Lines MG Marg', pincode: '211001', lat: 25.4358, lng: 81.8463);
    }
    // 7. Bareilly Region
    if (q.contains('bareilly') || q.startsWith('243')) {
      return (city: 'Bareilly', area: 'Civil Lines', pincode: '243001', lat: 28.3670, lng: 79.4304);
    }
    // 8. Saharanpur Region
    if (q.contains('saharanpur') || q.startsWith('247')) {
      return (city: 'Saharanpur', area: 'Court Road', pincode: '247001', lat: 29.9679, lng: 77.5452);
    }
    // 9. Shravasti Region
    if (q.contains('shravasti') || q.startsWith('271')) {
      return (city: 'Shravasti', area: 'Main Market', pincode: '271831', lat: 27.5000, lng: 82.0000);
    }
    // 10. Kanpur Region
    if (q.contains('kanpur') || q.startsWith('208')) {
      return (city: 'Kanpur', area: 'Mall Road', pincode: '208001', lat: 26.4499, lng: 80.3319);
    }
    // 11. Varanasi Region
    if (q.contains('varanasi') || q.contains('banaras') || q.contains('kashi') || q.startsWith('221')) {
      return (city: 'Varanasi', area: 'Sigra & Cantt', pincode: '221001', lat: 25.3176, lng: 82.9739);
    }
    // 12. Hyderabad Region
    if (q.contains('hyderabad') || q.startsWith('500')) {
      return (city: 'Hyderabad', area: 'Banjara Hills', pincode: '500034', lat: 17.4319, lng: 78.4073);
    }
    // 13. Pune Region
    if (q.contains('pune') || q.startsWith('411')) {
      return (city: 'Pune', area: 'FC Road, Shivaji Nagar', pincode: '411005', lat: 18.5204, lng: 73.8427);
    }

    // Default fallback with query formatted as City or Pincode
    final isNumeric = RegExp(r'^[0-9]+$').hasMatch(query.trim());
    if (isNumeric) {
      return (city: 'Custom Area', area: 'PIN: ${query.trim()}', pincode: query.trim(), lat: 26.8528, lng: 80.9984);
    }
    final formattedCity = query.trim().isNotEmpty
        ? query.trim().split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ')
        : 'Lucknow';
    return (city: formattedCity, area: '$formattedCity City', pincode: '226010', lat: 26.8528, lng: 80.9984);
  }

  void setManualLocation(String city, String pincode, {String? area, double? lat, double? lng}) {
    final resolved = resolvePincodeOrCity('$city $pincode');
    final finalCity = city.trim().isNotEmpty ? city.trim() : resolved.city;
    final finalPincode = pincode.trim().isNotEmpty ? pincode.trim() : resolved.pincode;
    final finalArea = area?.trim().isNotEmpty == true ? area!.trim() : resolved.area;
    final finalLat = lat ?? resolved.lat;
    final finalLng = lng ?? resolved.lng;

    userLocation = UserLocation(
      city: finalCity,
      area: finalArea,
      pincode: finalPincode,
      latitude: finalLat,
      longitude: finalLng,
      isGpsDetected: false,
    );

    // Auto update nearest store for the new city
    final matchingStores = allStores.where((s) => s.city.toLowerCase() == finalCity.toLowerCase() && !s.isUpcoming).toList();
    if (matchingStores.isNotEmpty) {
      if (finalLat != 0.0 || finalLng != 0.0) {
        matchingStores.sort((a, b) => getLiveDistanceFrom(a).compareTo(getLiveDistanceFrom(b)));
      }
      _activeSelectedStore = matchingStores.first;
    } else {
      _activeSelectedStore = nearestStore;
    }

    notifyListeners();
  }

  Future<void> triggerGpsLocation(VoidCallback onComplete) async {
    isGpsLocating = true;
    notifyListeners();

    try {
      final loc = await LocationService.fetchRealDeviceLocation();
      if (loc != null) {
        userLocation = loc;
        // Recalculate nearest active store
        _activeSelectedStore = nearestStore;
      }
    } catch (e) {
      debugPrint('[AppState] Error during GPS fetch: $e');
    } finally {
      isGpsLocating = false;
      hasPromptedInitialLocation = true;
      notifyListeners();
      onComplete();
    }
  }

  // --- Official EcoFone Retail Stores Directory ---
  static const List<EcoStore> allStores = [
    // 1. Lucknow Flagship Hub - Transport Nagar (From Google Maps Shortlink)
    EcoStore(
      id: 'EF-STORE-LKO-01',
      name: 'EcoFone Flagship Hub - Lucknow (Transport Nagar)',
      city: 'Lucknow',
      pincode: '226012',
      area: 'Transport Nagar, Kanpur Road',
      address: 'Plot A-4, Kanpur - Lucknow Road, Near Transport Nagar Metro Station, Lucknow, UP 226012',
      phone: '+91 99182 40555',
      timings: '10:00 AM - 9:30 PM (Open All 7 Days)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 0.8,
      rating: 4.9,
      reviewCount: 412,
      services: [
        '32-Point Live Diagnostics Bench',
        'Instant Cash / UPI Trade-in Desk',
        '6-Month Cashless Warranty Desk',
        'VIP Demo Lounge',
      ],
      landmark: 'Near Transport Nagar Metro & Shaheed Path Terminal',
      metroStation: 'Transport Nagar Metro Station (150m)',
      latitude: 26.7824167,
      longitude: 80.8956389,
      googleMapsUrl: 'https://maps.app.goo.gl/XFo3U32FSh1iwu1SA',
    ),

    // 2. Lucknow Store - Gomti Nagar
    EcoStore(
      id: 'EF-STORE-LKO-02',
      name: 'EcoFone Store - Gomti Nagar, Lucknow',
      city: 'Lucknow',
      pincode: '226010',
      area: 'Viram Khand, Gomti Nagar',
      address: '1/336, Shaheed Chandrashekhar Azad Chowk, Viram Khand Chouraha, Gomti Nagar, Lucknow, UP 226010',
      phone: '+91 99182 40555',
      timings: '10:00 AM - 9:30 PM (Open All 7 Days)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 2.1,
      rating: 4.9,
      reviewCount: 365,
      services: [
        '32-Point Hardware Test Bench',
        'Instant Cash & UPI Payouts',
        '6-Month Warranty Claim Desk',
        'Certified Refurbished Demos',
      ],
      landmark: 'Near Shaheed Chandrashekhar Azad Chowk & Husadiya Chauraha',
      metroStation: 'Lekhraj Market / Polytechnic Metro (2.2 km)',
      latitude: 26.8528,
      longitude: 80.9984,
      googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=1/336+Shaheed+Chandrashekhar+Azad+Chowk+Viram+Khand+Gomti+Nagar+Lucknow+226010',
    ),

    // 3. Gorakhpur Store - Golghar
    EcoStore(
      id: 'EF-STORE-GKP-01',
      name: 'EcoFone Store - Gorakhpur',
      city: 'Gorakhpur',
      pincode: '273001',
      area: 'Golghar, Gorakhpur',
      address: 'In Front of Near Liberty Showroom, Royal Residency, Keshav Market, Golghar, Gorakhpur, UP 273001',
      phone: '+91 91518 37103',
      timings: '10:00 AM - 9:00 PM (Open All 7 Days)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 1.2,
      rating: 4.8,
      reviewCount: 290,
      services: [
        'Live Device Diagnostics Rig',
        'Instant Phone Trade-In Cash',
        '6-Month Free Repair Warranty Desk',
        'Original Accessories Bar',
      ],
      landmark: 'In front of Liberty Showroom, Keshav Market, Royal Residency',
      metroStation: 'Gorakhpur Junction Railway Station (1.1 km)',
      latitude: 26.7570,
      longitude: 83.3732,
      googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=Liberty+Showroom+Keshav+Market+Golghar+Gorakhpur+273001',
    ),

    // 4. Shravasti Store - UPCOMING
    EcoStore(
      id: 'EF-STORE-SHR-01',
      name: 'EcoFone Store - Shravasti (Upcoming)',
      city: 'Shravasti',
      pincode: '271831',
      area: 'Main Commercial Market, Shravasti',
      address: 'Main Market Arcade, Near Bhinga - Ikauna Road, Shravasti, Uttar Pradesh 271831',
      phone: '+91 99182 40555',
      timings: 'Opening Soon • Grand Launch Ahead',
      isOpen: false,
      isUpcoming: true,
      distanceKm: 120.0,
      rating: 5.0,
      reviewCount: 45,
      services: [
        'Pre-Booking Exclusive Launch Discounts',
        'Full Diagnostics Rig',
        '6-Month Cashless Warranty',
      ],
      landmark: 'Main Market Commercial Complex, Shravasti',
      metroStation: 'Bahraich Railway Station (38 km)',
      latitude: 27.7025,
      longitude: 81.9360,
      googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=Shravasti+Uttar+Pradesh+India',
    ),

    // 5. Saharanpur Store - UPCOMING
    EcoStore(
      id: 'EF-STORE-SAH-01',
      name: 'EcoFone Store - Saharanpur (Upcoming)',
      city: 'Saharanpur',
      pincode: '247001',
      area: 'Court Road / Clock Tower',
      address: 'Court Road, Near Clock Tower Commercial Complex, Saharanpur, UP 247001',
      phone: '+91 99182 40555',
      timings: 'Opening Soon • Grand Launch Ahead',
      isOpen: false,
      isUpcoming: true,
      distanceKm: 380.0,
      rating: 5.0,
      reviewCount: 60,
      services: [
        'Pre-Booking Bonus Discounts',
        'Live Device Test Bench',
        'Instant Phone Trade-In',
        '6-Month Warranty Support',
      ],
      landmark: 'Near Clock Tower & Court Road Market',
      metroStation: 'Saharanpur Junction (1.5 km)',
      latitude: 29.9679,
      longitude: 77.5510,
      googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=Court+Road+Saharanpur+Uttar+Pradesh+247001',
    ),

    // 6. Bareilly Store - UPCOMING
    EcoStore(
      id: 'EF-STORE-BLY-01',
      name: 'EcoFone Store - Bareilly (Upcoming)',
      city: 'Bareilly',
      pincode: '243001',
      area: 'Civil Lines, Bareilly',
      address: 'Selection Point Commercial Arcade, Civil Lines, Bareilly, UP 243001',
      phone: '+91 99182 40555',
      timings: 'Opening Soon • Grand Launch Ahead',
      isOpen: false,
      isUpcoming: true,
      distanceKm: 240.0,
      rating: 5.0,
      reviewCount: 52,
      services: [
        'Pre-Launch Exchange Perks',
        'Certified Phone Showroom',
        'Instant UPI Payouts',
        '6-Month Warranty Desk',
      ],
      landmark: 'Near Selection Point & Ayub Khan Chauraha',
      metroStation: 'Bareilly City Station (2.0 km)',
      latitude: 28.3670,
      longitude: 79.4304,
      googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=Civil+Lines+Bareilly+Uttar+Pradesh+243001',
    ),

    // 7. Prayagraj Store - UPCOMING
    EcoStore(
      id: 'EF-STORE-PRY-01',
      name: 'EcoFone Store - Prayagraj (Upcoming)',
      city: 'Prayagraj',
      pincode: '211001',
      area: 'Civil Lines, MG Marg',
      address: 'Mahatma Gandhi Marg, Civil Lines, Prayagraj (Allahabad), UP 211001',
      phone: '+91 99182 40555',
      timings: 'Opening Soon • Grand Launch Ahead',
      isOpen: false,
      isUpcoming: true,
      distanceKm: 195.0,
      rating: 5.0,
      reviewCount: 78,
      services: [
        'Pre-Booking Special Vouchers',
        '32-Point Diagnostic Rig',
        'Instant Buyout Desk',
        'VIP Demo Center',
      ],
      landmark: 'Near Subhash Chauraha & MG Marg, Civil Lines',
      metroStation: 'Prayagraj Junction (1.8 km)',
      latitude: 25.4525,
      longitude: 81.8349,
      googleMapsUrl: 'https://www.google.com/maps/search/?api=1&query=Civil+Lines+MG+Marg+Prayagraj+Uttar+Pradesh+211001',
    ),

    // 8. Delhi NCR - Connaught Place
    EcoStore(
      id: 'EF-STORE-DEL-01',
      name: 'EcoFone Flagship Hub - Connaught Place',
      city: 'Delhi NCR',
      pincode: '110001',
      area: 'Connaught Place',
      address: 'Shop 14, Inner Circle, Block C, Connaught Place, New Delhi',
      phone: '+91 98765 43210',
      timings: '10:00 AM - 9:30 PM (Open All 7 Days)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 1.8,
      rating: 4.9,
      reviewCount: 428,
      services: ['32-Point Live Diagnostics', 'Instant Cash Trade-in', '6-Month Cashless Warranty Desk', 'VIP Demo Lounge'],
      landmark: 'Opposite Odeon Cinema',
      metroStation: 'Rajiv Chowk Metro Gate 3 (200m)',
      latitude: 28.6328,
      longitude: 77.2197,
      googleMapsUrl: 'https://maps.google.com/?q=28.6328,77.2197',
    ),

    // 9. Delhi NCR - DLF CyberHub Gurugram
    EcoStore(
      id: 'EF-STORE-GUR-02',
      name: 'EcoFone Experience Hub - DLF CyberHub',
      city: 'Delhi NCR',
      pincode: '122002',
      area: 'CyberHub, Gurugram',
      address: 'Unit 22, Ground Floor, DLF CyberHub Phase 2, Gurugram',
      phone: '+91 98765 43212',
      timings: '10:30 AM - 10:00 PM (Open Today)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 14.5,
      rating: 4.8,
      reviewCount: 310,
      services: ['Live Device Testing', 'Same-Day Battery/Screen Replacement', 'Instant Buyout Desk'],
      landmark: 'Near Starbucks CyberHub',
      metroStation: 'Cyber City Rapid Metro (150m)',
      latitude: 28.4950,
      longitude: 77.0895,
      googleMapsUrl: 'https://maps.google.com/?q=28.4950,77.0895',
    ),

    // 10. Mumbai - Bandra West
    EcoStore(
      id: 'EF-STORE-MUM-01',
      name: 'EcoFone Flagship Hub - Bandra West',
      city: 'Mumbai',
      pincode: '400050',
      area: 'Bandra West',
      address: 'Plot 312, Linking Road, Near National College, Bandra West, Mumbai',
      phone: '+91 98765 43220',
      timings: '10:30 AM - 9:30 PM (Open Today)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 2.3,
      rating: 4.9,
      reviewCount: 512,
      services: ['32-Point Live Diagnostics', 'Instant Cash on Desk', '6-Month Warranty Claims', 'Apple & Pixel Specialist'],
      landmark: 'Opposite Regal Shoes, Linking Rd',
      metroStation: 'Bandra Station (1.2 km)',
      latitude: 19.0607,
      longitude: 72.8362,
      googleMapsUrl: 'https://maps.google.com/?q=19.0607,72.8362',
    ),

    // 11. Bengaluru - Indiranagar
    EcoStore(
      id: 'EF-STORE-BLR-01',
      name: 'EcoFone Experience Hub - Indiranagar',
      city: 'Bengaluru',
      pincode: '560038',
      area: 'Indiranagar',
      address: '742, 100 Feet Road, Near 12th Main Junction, HAL 2nd Stage, Indiranagar, Bengaluru',
      phone: '+91 98765 43230',
      timings: '10:00 AM - 9:30 PM (Open Today)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 1.9,
      rating: 4.9,
      reviewCount: 460,
      services: ['Live Diagnostic Test Bench', 'Instant UPI Buyout', '6-Month Warranty Support', 'Coffee & Tech Lounge'],
      landmark: 'Next to FabIndia, 100 Feet Rd',
      metroStation: 'Indiranagar Metro Station (350m)',
      latitude: 12.9784,
      longitude: 77.6408,
      googleMapsUrl: 'https://maps.google.com/?q=12.9784,77.6408',
    ),

    // 12. Hyderabad - Jubilee Hills
    EcoStore(
      id: 'EF-STORE-HYD-01',
      name: 'EcoFone Experience Center - Jubilee Hills',
      city: 'Hyderabad',
      pincode: '500033',
      area: 'Jubilee Hills',
      address: 'Road No. 36, Near Peddamma Gudi Metro Pillar 1680, Jubilee Hills, Hyderabad',
      phone: '+91 98765 43240',
      timings: '10:30 AM - 9:30 PM (Open Today)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 2.8,
      rating: 4.9,
      reviewCount: 340,
      services: ['32-Point Diagnostics Rig', 'Immediate Bank Transfer Payout', '6-Month Pan-India Repair Desk'],
      landmark: 'Adjacent to Croma, Rd 36',
      metroStation: 'Peddamma Gudi Metro (100m)',
      latitude: 17.4319,
      longitude: 78.4073,
      googleMapsUrl: 'https://maps.google.com/?q=17.4319,78.4073',
    ),

    // 13. Pune - FC Road
    EcoStore(
      id: 'EF-STORE-PUN-01',
      name: 'EcoFone Experience Hub - FC Road',
      city: 'Pune',
      pincode: '411005',
      area: 'FC Road, Shivajinagar',
      address: 'Shop 10, Shreenath Plaza, FC Road, Shivajinagar, Pune',
      phone: '+91 98765 43250',
      timings: '10:00 AM - 9:00 PM (Open Today)',
      isOpen: true,
      isUpcoming: false,
      distanceKm: 2.4,
      rating: 4.8,
      reviewCount: 280,
      services: ['Live Refurbished Phone Demos', 'Student & Pro Exchange Bonus', 'Instant Cash on Desk'],
      landmark: 'Near Goodluck Cafe',
      metroStation: 'Shivajinagar Metro (900m)',
      latitude: 18.5204,
      longitude: 73.8427,
      googleMapsUrl: 'https://maps.google.com/?q=18.5204,73.8427',
    ),
  ];

  double getLiveDistanceFrom(EcoStore store) {
    if (userLocation.latitude != null && userLocation.longitude != null) {
      final meters = Geolocator.distanceBetween(
        userLocation.latitude!,
        userLocation.longitude!,
        store.latitude,
        store.longitude,
      );
      final km = meters / 1000.0;
      return double.parse(km.toStringAsFixed(1));
    }
    return store.distanceKm;
  }

  EcoStore get nearestStore {
    final activeStores = allStores.where((s) => !s.isUpcoming).toList();
    if (activeStores.isEmpty) return allStores.first;

    final matchingCityStores = activeStores.where((s) => s.city.toLowerCase() == selectedCity.toLowerCase()).toList();
    if (matchingCityStores.isNotEmpty) {
      if (userLocation.latitude != null && userLocation.longitude != null) {
        final sorted = List<EcoStore>.from(matchingCityStores);
        sorted.sort((a, b) => getLiveDistanceFrom(a).compareTo(getLiveDistanceFrom(b)));
        return sorted.first;
      }
      return matchingCityStores.first;
    }
    if (userLocation.latitude != null && userLocation.longitude != null) {
      final sortedByDistance = List<EcoStore>.from(activeStores);
      sortedByDistance.sort((a, b) => getLiveDistanceFrom(a).compareTo(getLiveDistanceFrom(b)));
      return sortedByDistance.first;
    }
    return activeStores.first;
  }

  /// Checks if EcoFone has active retail store hubs in the user's selected/detected city
  bool get isCurrentCityServed {
    final userCity = userLocation.city.toLowerCase().trim();
    return allStores.any((s) => s.city.toLowerCase().trim() == userCity && !s.isUpcoming);
  }

  /// Returns stores serving the user's city or fallback to all active hubs
  List<EcoStore> get servingStoresInCity {
    final userCity = userLocation.city.toLowerCase().trim();
    final stores = allStores.where((s) => s.city.toLowerCase().trim() == userCity && !s.isUpcoming).toList();
    if (stores.isNotEmpty) return stores;
    return allStores.where((s) => !s.isUpcoming).toList();
  }

  /// Checks if nearest store is within driving/commute distance (<= 45 km)
  bool get hasNearbyStore => getLiveDistanceFrom(nearestStore) <= 45.0;

  List<EcoStore> getStoresForCity(String city) {
    if (city == 'All' || city == 'Nearest') {
      if (userLocation.latitude != null && userLocation.longitude != null) {
        final sorted = List<EcoStore>.from(allStores);
        sorted.sort((a, b) => getLiveDistanceFrom(a).compareTo(getLiveDistanceFrom(b)));
        return sorted;
      }
      return allStores;
    }
    return allStores.where((s) => s.city.toLowerCase() == city.toLowerCase()).toList();
  }

  // --- Services & Real-time Persistence Layer ---
  LocalStorageService? storage;
  RealtimeBackendService? backend;
  final BillingApiService _defaultBillingApi = BillingApiService();
  BillingApiService get billingApi => backend?.billingApi ?? _defaultBillingApi;
  bool isServicesInitialized = false;
  StreamSubscription<List<PhoneReservation>>? _reservationsSubscription;
  StreamSubscription<List<PhoneStockItem>>? _inventorySubscription;

  // --- Real-Time Billing & Inventory Catalog State ---
  List<PhoneStockItem> liveInventory = List.from(PhoneStockItem.sampleInventory);
  bool isInventoryLoading = false;
  // --- Customer Orders & Purchases ---
  final List<PhoneOrder> orders = [];
  List<PhoneOrder> get reservations => orders;
  final List<TradeInQuote> tradeInQuotes = [];

  void _subscribeToOrders(String phone) {
    _reservationsSubscription?.cancel();
    if (backend != null && phone.isNotEmpty) {
      _reservationsSubscription = backend!.streamUserOrders(phone).listen((liveOrders) {
        orders.clear();
        orders.addAll(liveOrders);
        notifyListeners();
      });
    }
  }

  void _subscribeToReservations(String phone) => _subscribeToOrders(phone);

  void _subscribeToInventory({String? storeId}) {
    _inventorySubscription?.cancel();
    if (backend != null) {
      _inventorySubscription = backend!.streamLiveInventory(storeId: storeId).listen((items) {
        if (items.isNotEmpty) {
          liveInventory = List.from(items);
          notifyListeners();
        }
      });
    }
  }

  /// Reloads latest real-time stock catalog directly from enterprise billing API
  Future<void> refreshInventory({String? storeId}) async {
    isInventoryLoading = true;
    notifyListeners();
    try {
      if (backend != null) {
        final items = await backend!.fetchInventory(storeId: storeId ?? selectedStore.id);
        if (items.isNotEmpty) {
          liveInventory = List.from(items);
        }
      }
    } catch (e) {
      debugPrint('[AppState] refreshInventory error: $e');
    } finally {
      isInventoryLoading = false;
      notifyListeners();
    }
  }

  /// Submits customer trade-in / buyback quote to the billing software purchase register
  Future<TradeInQuote> submitTradeInQuote(TradeInQuote quote) async {
    tradeInQuotes.removeWhere((q) => q.quoteId == quote.quoteId);
    tradeInQuotes.insert(0, quote);
    notifyListeners();

    if (backend != null) {
      final synced = await backend!.submitTradeInQuote(quote);
      return synced;
    }
    return quote;
  }

  Future<void> initServices() async {
    if (isServicesInitialized) return;
    try {
      storage = await LocalStorageService.getInstance();
      const envBaseUrl = String.fromEnvironment('ECOFONE_API_BASE_URL');
      const envApiKey = String.fromEnvironment('ECOFONE_API_KEY');
      const envFast2SmsKey = String.fromEnvironment('FAST2SMS_API_KEY');

      backend = RealtimeBackendService(
        storage: storage!,
        baseUrl: envBaseUrl.isNotEmpty ? envBaseUrl : null,
        apiKey: envApiKey.isNotEmpty ? envApiKey : null,
        fast2smsApiKey: envFast2SmsKey.isNotEmpty ? envFast2SmsKey : null,
      );

      // 1. Restore persistent user login session
      final profile = storage!.getUserProfile();
      if (profile != null) {
        isLoggedIn = true;
        userName = profile.name;
        userPhone = profile.phone;
        userEmail = profile.email;
        if (profile.city != null && profile.city!.isNotEmpty) {
          setManualLocation(profile.city!, profile.pincode ?? userLocation.pincode);
        }
      }

      // 2. Restore saved orders from local cache
      final savedOrders = storage!.getSavedOrders();
      if (savedOrders.isNotEmpty) {
        orders.clear();
        orders.addAll(savedOrders);
      }

      // 3. Restore wishlist
      wishlistedIds.clear();
      wishlistedIds.addAll(storage!.getWishlist());

      // 4. Listen to real-time cloud orders
      if (userPhone != null && userPhone!.isNotEmpty) {
        _subscribeToOrders(userPhone!);
      }

      // 5. Attach live inventory stream from Billing API
      _subscribeToInventory();
      unawaited(refreshInventory());

      isServicesInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AppState] Error initializing services: $e');
    }
  }

  /// Dynamically configures or switches the enterprise Billing & POS API at runtime
  void configureBackendApi({String? baseUrl, String? apiKey, String? fast2smsApiKey}) {
    if (storage != null) {
      backend = RealtimeBackendService(
        storage: storage!,
        baseUrl: baseUrl,
        apiKey: apiKey,
        fast2smsApiKey: fast2smsApiKey,
      );
      _subscribeToInventory();
      unawaited(refreshInventory());
      if (userPhone != null && userPhone!.isNotEmpty) {
        _subscribeToOrders(userPhone!);
      }
      notifyListeners();
    }
  }

  // --- Place Smartphone Order ---
  void placeOrder(PhoneOrder order) {
    orders.removeWhere((o) => o.orderId == order.orderId);
    orders.insert(0, order);
    storage?.saveOrders(orders);
    backend?.createOrder(order);
    notifyListeners();
  }

  /// Official EcoFone POS Online Checkout Flow:
  /// Passes payment verification details to POS backend, allocates serial IMEI,
  /// attaches sequential invoice & warranty, and saves locally.
  Future<PhoneOrder> placeOnlineOrder({
    required PhoneOrder order,
    required String razorpayPaymentId,
    String? razorpayOrderId,
    double? amount,
  }) async {
    PhoneOrder finalOrder;
    if (backend != null) {
      finalOrder = await backend!.createOnlinePosOrder(
        order: order,
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        amount: amount,
      );
    } else {
      finalOrder = await billingApi.createOnlineOrder(
        order: order,
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        amount: amount,
      );
    }

    orders.removeWhere((o) => o.orderId == finalOrder.orderId);
    orders.insert(0, finalOrder);
    storage?.saveOrders(orders);
    notifyListeners();
    return finalOrder;
  }

  /// Fetches structured tax invoice & warranty details directly from POS API
  Future<Map<String, dynamic>?> fetchOnlineInvoice(String invoiceNumber) async {
    return await billingApi.fetchOnlineInvoice(invoiceNumber);
  }

  /// Dispatches a structured WhatsApp notification for new purchase orders
  Future<bool> sendStoreOwnerOrderWhatsApp(PhoneOrder order) async {
    if (backend != null) {
      return await backend!.notifyStoreOwner(order);
    }
    final rawPhone = order.storePhone.replaceAll(RegExp(r'[^0-9]'), '');
    final targetPhone = rawPhone.length == 10
        ? '91$rawPhone'
        : (rawPhone.startsWith('91') ? rawPhone : '91$rawPhone');

    final message = '''🛍️ *NEW ECOFONE SMARTPHONE ORDER*
----------------------------------------
📦 *Order ID:* #${order.orderId}
📱 *Phone:* ${order.phoneName} (${order.storage}, ${order.color})
🏷️ *Grade:* ${order.conditionGrade}
💰 *Total Amount:* ₹${order.price} (${order.paymentMethod})
🚚 *Delivery Mode:* ${order.deliveryOption}
📍 *Delivery Address:* ${order.deliveryAddress}

👤 *Customer Details:*
• Name: ${order.customerName}
• Mobile: ${order.customerPhone}

🏪 *Fulfillment Hub:* ${order.storeName}
----------------------------------------
_Sent automatically via EcoFone E-Commerce Desk_''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappAppUri = Uri.parse('whatsapp://send?phone=$targetPhone&text=$encodedMessage');
    final whatsappWebUri = Uri.parse('https://wa.me/$targetPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappAppUri)) {
        return await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(whatsappWebUri)) {
        return await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(whatsappWebUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('[AppState] Failed to launch WhatsApp for store owner: $e');
      return false;
    }
  }

  PhoneOrder createAndPlaceOrder({
    required String phoneId,
    required String phoneName,
    String brand = 'Apple / Premium',
    required String storage,
    required String color,
    required String grade,
    required int price,
    required EcoStore store,
    String deliveryOption = 'Express Doorstep Delivery (1-2 Days)',
    String deliveryAddress = 'Doorstep Delivery',
    String paymentMethod = 'Cash on Delivery (COD)',
    String paymentStatus = 'Pay after Doorstep Inspection',
    String? customerName,
    String? customerPhone,
    IconData icon = Icons.smartphone_rounded,
  }) {
    final orderId = 'ECO-ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final rawCustomerPhone = customerPhone ?? userPhone ?? '+91 98765 43210';
    final cleanCustomerDigits = rawCustomerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanCustomerDigits.length >= 10
        ? cleanCustomerDigits.substring(cleanCustomerDigits.length - 10)
        : cleanCustomerDigits;
    final formattedCustomerPhone = '+91 $tenDigits';

    final order = PhoneOrder(
      orderId: orderId,
      phoneId: phoneId,
      phoneName: phoneName,
      brand: brand,
      storage: storage,
      color: color,
      conditionGrade: grade,
      price: price,
      icon: icon,
      deliveryOption: deliveryOption,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      orderStatus: 'Order Confirmed • Dispatching in 24h',
      storeId: store.id,
      storeName: store.name,
      storeAddress: store.address,
      storePhone: store.phone,
      storeMapsUrl: store.googleMapsUrl,
      customerName: (customerName != null && customerName.trim().isNotEmpty)
          ? customerName.trim()
          : (userName ?? 'Valued Customer'),
      customerPhone: formattedCustomerPhone,
      createdAt: DateTime.now(),
    );
    placeOrder(order);
    return order;
  }

  void cancelOrder(String orderId) {
    orders.removeWhere((o) => o.orderId == orderId);
    storage?.saveOrders(orders);
    backend?.cancelOrder(orderId);
    notifyListeners();
  }

  // Backward-compatible aliases
  void bookReservation(PhoneOrder res) => placeOrder(res);
  PhoneOrder createAndBookReservation({
    required String phoneId,
    required String phoneName,
    String brand = 'Apple / Premium',
    required String storage,
    required String color,
    required String grade,
    required int price,
    required EcoStore store,
    required String visitDate,
    required String timeSlot,
    String? customerName,
    String? customerPhone,
    IconData icon = Icons.smartphone_rounded,
  }) => createAndPlaceOrder(
    phoneId: phoneId,
    phoneName: phoneName,
    brand: brand,
    storage: storage,
    color: color,
    grade: grade,
    price: price,
    store: store,
    deliveryOption: '$visitDate • $timeSlot',
    customerName: customerName,
    customerPhone: customerPhone,
    icon: icon,
  );
  void cancelReservation(String reservationId) => cancelOrder(reservationId);
  Future<bool> sendStoreOwnerReservationWhatsApp(PhoneOrder res) => sendStoreOwnerOrderWhatsApp(res);

  // --- In-Store VIP Appointments ---
  final List<InStoreAppointment> inStoreAppointments = [];

  void bookInStoreAppointment(InStoreAppointment apt) {
    inStoreAppointments.insert(0, apt);
    notifyListeners();
  }

  // --- Authentication State ---
  bool isLoggedIn = false;
  String? userName;
  String? userPhone;
  String? userEmail;

  Future<bool> sendOtp(String phone) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10
        ? cleanDigits.substring(cleanDigits.length - 10)
        : cleanDigits;
    final formattedPhone = '+91 $tenDigits';
    if (backend != null) {
      return await backend!.sendOtp(formattedPhone);
    }
    return true;
  }

  Future<UserProfile?> verifyOtpAndLogin({
    required String phone,
    required String otp,
    String? name,
  }) async {
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10
        ? cleanDigits.substring(cleanDigits.length - 10)
        : cleanDigits;
    final formattedPhone = '+91 $tenDigits';

    if (backend != null) {
      final profile = await backend!.verifyOtpAndLogin(
        phoneNumber: formattedPhone,
        otp: otp,
        name: name,
      );

      if (profile != null) {
        isLoggedIn = true;
        userName = profile.name;
        userPhone = profile.phone;
        userEmail = profile.email;
        if (profile.city != null && profile.city!.isNotEmpty) {
          setManualLocation(profile.city!, profile.pincode ?? userLocation.pincode);
        }

        // Sync and stream reservations
        if (userPhone != null && userPhone!.isNotEmpty) {
          _subscribeToReservations(userPhone!);
        }

        notifyListeners();
        return profile;
      }
      return null;
    }

    final isMockValid = otp.trim() == '123456' || otp.trim() == '1234';
    if (!isMockValid) return null;

    login(name: name ?? 'Customer', phone: formattedPhone);
    return storage?.getUserProfile();
  }

  void login({
    required String name,
    required String phone,
    String? email,
    String? city,
    String? pincode,
  }) {
    isLoggedIn = true;
    userName = name.trim().isEmpty ? 'Valued Customer' : name.trim();
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final tenDigits = cleanDigits.length >= 10
        ? cleanDigits.substring(cleanDigits.length - 10)
        : cleanDigits;
    userPhone = '+91 $tenDigits';
    userEmail = email?.trim().isNotEmpty == true ? email!.trim() : '$tenDigits@ecofone.in';
    if (city != null && city.trim().isNotEmpty) {
      setManualLocation(city.trim(), pincode?.trim() ?? userLocation.pincode);
    }

    final profile = UserProfile(
      name: userName!,
      phone: userPhone!,
      email: userEmail,
      city: city?.trim() ?? userLocation.city,
      pincode: pincode?.trim() ?? userLocation.pincode,
      token: 'ECO-JWT-${DateTime.now().millisecondsSinceEpoch}',
      lastLoginAt: DateTime.now(),
    );
    storage?.saveUserProfile(profile);
    backend?.updateUserProfile(profile);

    if (userPhone != null && userPhone!.isNotEmpty) {
      _subscribeToReservations(userPhone!);
    }

    notifyListeners();
  }

  /// Update user profile details and sync immediately with Cloud Firestore
  Future<void> updateProfileDetails({
    required String name,
    String? email,
    String? city,
    String? pincode,
  }) async {
    userName = name.trim().isEmpty ? 'Valued Customer' : name.trim();
    if (email != null && email.trim().isNotEmpty) {
      userEmail = email.trim();
    }
    if (city != null && city.trim().isNotEmpty) {
      setManualLocation(city.trim(), pincode?.trim() ?? userLocation.pincode);
    }

    final updatedProfile = UserProfile(
      name: userName!,
      phone: userPhone ?? '',
      email: userEmail,
      city: city?.trim() ?? userLocation.city,
      pincode: pincode?.trim() ?? userLocation.pincode,
      token: 'ECO-JWT-${DateTime.now().millisecondsSinceEpoch}',
      lastLoginAt: DateTime.now(),
    );

    await storage?.saveUserProfile(updatedProfile);
    if (backend != null) {
      await backend!.updateUserProfile(updatedProfile);
    }
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    userName = null;
    userPhone = null;
    userEmail = null;
    reservations.clear();
    _reservationsSubscription?.cancel();
    _reservationsSubscription = null;
    storage?.clearAuthSession();
    storage?.saveReservations([]);
    notifyListeners();
  }

  // --- Shared Wishlist ---
  final Set<String> wishlistedIds = {'EF-101', 'EF-103', 'EF-105'};

  void toggleWishlist(String id) {
    if (wishlistedIds.contains(id)) {
      wishlistedIds.remove(id);
    } else {
      wishlistedIds.add(id);
    }
    storage?.saveWishlist(wishlistedIds);
    notifyListeners();
  }

  bool isWishlisted(String id) => wishlistedIds.contains(id);
}

