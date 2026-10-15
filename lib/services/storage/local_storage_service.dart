import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecofone/models/user_profile.dart';
import 'package:ecofone/models/order_model.dart';

class LocalStorageService {
  static const String _keyUserProfile = 'ecofone_user_profile';
  static const String _keyIsLoggedIn = 'ecofone_is_logged_in';
  static const String _keyOrders = 'ecofone_orders';
  static const String _keyReservations = 'ecofone_reservations';
  static const String _keyWishlist = 'ecofone_wishlist';
  static const String _keySelectedStoreId = 'ecofone_selected_store_id';
  static const String _keyInitialLocationPrompted = 'ecofone_loc_prompted';

  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // --- User Profile & Authentication ---
  bool get isLoggedIn => _prefs?.getBool(_keyIsLoggedIn) ?? false;

  UserProfile? getUserProfile() {
    try {
      final raw = _prefs?.getString(_keyUserProfile);
      if (raw == null || raw.isEmpty) return null;
      final Map<String, dynamic> jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } catch (e) {
      debugPrint('[LocalStorage] Error loading user profile: $e');
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _prefs?.setBool(_keyIsLoggedIn, true);
      await _prefs?.setString(_keyUserProfile, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('[LocalStorage] Error saving user profile: $e');
    }
  }

  Future<void> clearAuthSession() async {
    try {
      await _prefs?.remove(_keyUserProfile);
      await _prefs?.setBool(_keyIsLoggedIn, false);
    } catch (e) {
      debugPrint('[LocalStorage] Error clearing auth session: $e');
    }
  }

  // --- Customer Orders & Purchases Persistence ---
  List<PhoneOrder> getSavedOrders() {
    try {
      final rawList = _prefs?.getStringList(_keyOrders) ?? _prefs?.getStringList(_keyReservations);
      if (rawList == null || rawList.isEmpty) return [];
      return rawList.map((item) {
        final Map<String, dynamic> jsonMap = jsonDecode(item) as Map<String, dynamic>;
        return PhoneOrder.fromJson(jsonMap);
      }).toList();
    } catch (e) {
      debugPrint('[LocalStorage] Error loading saved orders: $e');
      return [];
    }
  }

  Future<void> saveOrders(List<PhoneOrder> list) async {
    try {
      final strList = list.map((res) => jsonEncode(res.toJson())).toList();
      await _prefs?.setStringList(_keyOrders, strList);
      await _prefs?.setStringList(_keyReservations, strList);
    } catch (e) {
      debugPrint('[LocalStorage] Error saving orders: $e');
    }
  }

  // Aliases for backward compatibility
  List<PhoneOrder> getSavedReservations() => getSavedOrders();
  Future<void> saveReservations(List<PhoneOrder> list) => saveOrders(list);

  // --- Wishlist Persistence ---
  Set<String> getWishlist() {
    try {
      final raw = _prefs?.getStringList(_keyWishlist);
      return raw?.toSet() ?? {'EF-101', 'EF-103', 'EF-105'};
    } catch (e) {
      debugPrint('[LocalStorage] Error loading wishlist: $e');
      return {'EF-101', 'EF-103', 'EF-105'};
    }
  }

  Future<void> saveWishlist(Set<String> wishlist) async {
    try {
      await _prefs?.setStringList(_keyWishlist, wishlist.toList());
    } catch (e) {
      debugPrint('[LocalStorage] Error saving wishlist: $e');
    }
  }

  // --- Store & App Settings ---
  String? getSelectedStoreId() => _prefs?.getString(_keySelectedStoreId);

  Future<void> saveSelectedStoreId(String storeId) async {
    await _prefs?.setString(_keySelectedStoreId, storeId);
  }

  bool get hasPromptedInitialLocation => _prefs?.getBool(_keyInitialLocationPrompted) ?? false;

  Future<void> setPromptedInitialLocation(bool value) async {
    await _prefs?.setBool(_keyInitialLocationPrompted, value);
  }

  // --- Onboarding Persistence ---
  static const String _keyHasSeenOnboarding = 'ecofone_has_seen_onboarding';

  bool get hasSeenOnboarding => _prefs?.getBool(_keyHasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs?.setBool(_keyHasSeenOnboarding, value);
  }
}
