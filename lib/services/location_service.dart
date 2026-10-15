import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ecofone/state/app_state.dart';

/// Real Device GPS & Reverse Geocoding Service
class LocationService {
  /// Request device GPS and resolve real location details via reverse geocoding
  static Future<UserLocation?> fetchRealDeviceLocation() async {
    try {
      // 1. Check if location services are enabled on the phone
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled on device.');
      }

      // 2. Check & request permission from user
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions are permanently denied.');
        return null;
      }

      // 3. Fetch high-precision device GPS position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (e) {
        debugPrint('[LocationService] Failed to get high accuracy GPS, trying last known: $e');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        debugPrint('[LocationService] Could not determine position.');
        return null;
      }

      debugPrint('[LocationService] Got GPS: ${position.latitude}, ${position.longitude}');

      // 4. Reverse Geocode Lat/Lng into real street, area, city, pincode
      String area = 'Live Location';
      String city = 'Lucknow';
      String pincode = '226010';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          debugPrint('[LocationService] Placemark: name=${p.name}, street=${p.street}, subLocality=${p.subLocality}, locality=${p.locality}, subAdmin=${p.subAdministrativeArea}, postalCode=${p.postalCode}');

          if (p.subLocality != null && p.subLocality!.isNotEmpty) {
            area = p.subLocality!;
          } else if (p.street != null && p.street!.isNotEmpty) {
            area = p.street!;
          } else if (p.locality != null && p.locality!.isNotEmpty) {
            area = p.locality!;
          }

          if (p.locality != null && p.locality!.isNotEmpty) {
            city = p.locality!;
          } else if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) {
            city = p.subAdministrativeArea!;
          } else if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
            city = p.administrativeArea!;
          }

          if (p.postalCode != null && p.postalCode!.isNotEmpty) {
            pincode = p.postalCode!;
          }
        }
      } catch (geoError) {
        debugPrint('[LocationService] Reverse geocoding error: $geoError');
      }

      return UserLocation(
        city: city,
        area: area,
        pincode: pincode,
        latitude: position.latitude,
        longitude: position.longitude,
        isGpsDetected: true,
      );
    } catch (e) {
      debugPrint('[LocationService] Exception fetching real location: $e');
      return null;
    }
  }
}

