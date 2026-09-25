import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class LocationService {
  LocationService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {'User-Agent': 'CartITApp/1.0 (contact@cartit.com)'},
    ),
  );

  /// Get current GPS location fast with progressive accuracy
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // 1. First try last known position for instant cache response
    Position? lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      // If position is less than 5 minutes old, return immediately
      final age = DateTime.now().difference(lastKnown.timestamp);
      if (age.inMinutes < 5) {
        return lastKnown;
      }
    }

    // 2. Fetch fresh position with high accuracy
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      // Fallback to medium accuracy if high times out
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        return lastKnown;
      }
    }
  }

  /// High performance parallel Reverse Geocoding with fallback layers
  static Future<Map<String, String>?> reverseGeocode(double lat, double lon) async {
    // Priority 1: Fast Photon API
    var result = await _reverseGeocodePhoton(lat, lon);
    if (result != null) return result;

    // Priority 2: OpenStreetMap Nominatim
    result = await _reverseGeocodeNominatim(lat, lon);
    if (result != null) return result;

    // Priority 3: BigDataCloud fallback
    result = await _reverseGeocodeBigDataCloud(lat, lon);
    if (result != null) return result;

    return null;
  }

  static Future<Map<String, String>?> _reverseGeocodePhoton(double lat, double lon) async {
    try {
      final url = 'https://photon.komoot.io/reverse?lat=$lat&lon=$lon';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final features = (response.data['features'] as List?) ?? [];
        if (features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>? ?? {};

          final name = props['name']?.toString() ?? '';
          final housenumber = props['housenumber']?.toString() ?? '';
          final streetName = props['street']?.toString() ?? '';
          final district = props['district']?.toString() ?? props['suburb']?.toString() ?? '';
          final city = props['city']?.toString() ?? props['county']?.toString() ?? props['state']?.toString() ?? '';
          final state = props['state']?.toString() ?? '';
          final pcRaw = props['postcode']?.toString() ?? '';

          List<String> streetParts = [];
          if (name.isNotEmpty) streetParts.add(name);
          if (housenumber.isNotEmpty && housenumber != name) streetParts.add(housenumber);
          if (streetName.isNotEmpty && streetName != name) streetParts.add(streetName);
          if (district.isNotEmpty && district != streetName && district != name) streetParts.add(district);

          final fullStreet = streetParts.isNotEmpty ? streetParts.join(', ') : (district.isNotEmpty ? district : city);
          final areaTitle = name.isNotEmpty
              ? name
              : (streetName.isNotEmpty
                  ? (district.isNotEmpty ? '$streetName, $district' : streetName)
                  : (district.isNotEmpty ? district : (city.isNotEmpty ? city : 'Selected Location')));

          final pincode = extractPincode(pcRaw, [fullStreet, city, state].join(' '));
          final displayAddress = cleanDeduplicatedAddress([fullStreet, city, state, pincode]);

          return {
            'areaTitle': areaTitle,
            'street': fullStreet,
            'city': city,
            'state': state,
            'zipCode': pincode,
            'displayAddress': displayAddress,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, String>?> _reverseGeocodeNominatim(double lat, double lon) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final map = response.data['address'] as Map<String, dynamic>? ?? {};
        final name = response.data['name']?.toString() ?? '';

        final amenity = map['amenity'] ?? map['building'] ?? map['shop'] ?? map['office'] ?? '';
        final houseNumber = map['house_number'] ?? map['building'] ?? '';
        final road = map['road'] ?? map['pedestrian'] ?? map['path'] ?? map['footway'] ?? '';
        final suburb = map['suburb'] ?? map['neighbourhood'] ?? map['residential'] ?? map['quarter'] ?? '';
        final city = map['city'] ?? map['town'] ?? map['village'] ?? map['county'] ?? map['state_district'] ?? '';
        final state = map['state'] ?? '';
        final pcRaw = map['postcode'] ?? '';
        final rawDisplayName = response.data['display_name']?.toString() ?? '';

        List<String> streetParts = [];
        if (name.isNotEmpty) {
          streetParts.add(name);
        } else if (amenity.toString().isNotEmpty) {
          streetParts.add(amenity.toString());
        }
        if (houseNumber.toString().isNotEmpty && houseNumber.toString() != name) {
          streetParts.add(houseNumber.toString());
        }
        if (road.toString().isNotEmpty && road.toString() != name) {
          streetParts.add(road.toString());
        }
        if (suburb.toString().isNotEmpty && suburb.toString() != road.toString() && suburb.toString() != name) {
          streetParts.add(suburb.toString());
        }

        String streetLine = streetParts.join(', ');
        if (streetLine.isEmpty && rawDisplayName.isNotEmpty) {
          final split = rawDisplayName.split(',');
          if (split.length >= 3) {
            streetLine = '${split[0].trim()}, ${split[1].trim()}, ${split[2].trim()}';
          } else {
            streetLine = split[0].trim();
          }
        }

        final areaTitle = name.isNotEmpty
            ? name
            : (road.toString().isNotEmpty
                ? (suburb.toString().isNotEmpty ? '${road.toString()}, ${suburb.toString()}' : road.toString())
                : (suburb.toString().isNotEmpty ? suburb.toString() : (city.toString().isNotEmpty ? city.toString() : 'Selected Location')));

        final pincode = extractPincode(pcRaw.toString(), rawDisplayName);
        final displayAddress = cleanDeduplicatedAddress([streetLine, city.toString(), state.toString(), pincode]);

        return {
          'areaTitle': areaTitle,
          'street': streetLine,
          'city': city.toString(),
          'state': state.toString(),
          'zipCode': pincode,
          'displayAddress': displayAddress,
        };
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, String>?> _reverseGeocodeBigDataCloud(double lat, double lon) async {
    try {
      final url =
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final localityInfo = data['localityInfo'] as Map<String, dynamic>? ?? {};
        final informative = (localityInfo['informative'] as List?) ?? [];

        final streetName = informative.isNotEmpty
            ? (informative[0]['name'] ?? '')
            : (data['locality'] ?? data['city'] ?? '');
        final cityText = data['locality'] ?? data['city'] ?? '';
        final stateText = data['principalSubdivision'] ?? '';
        final postcodeText = data['postcode'] ?? '';

        final displayAddress = cleanDeduplicatedAddress([
          streetName.toString(),
          cityText.toString(),
          stateText.toString(),
          postcodeText.toString()
        ]);
        final pincode = extractPincode(postcodeText.toString(), displayAddress);

        return {
          'areaTitle': streetName.toString().isNotEmpty ? streetName.toString() : (cityText.toString().isNotEmpty ? cityText.toString() : 'Selected Location'),
          'street': streetName.toString(),
          'city': cityText.toString(),
          'state': stateText.toString(),
          'zipCode': pincode,
          'displayAddress': displayAddress,
        };
      }
    } catch (_) {}
    return null;
  }

  static String extractPincode(String pc, String fullText) {
    if (pc.trim().isNotEmpty && RegExp(r'^\d{6}$').hasMatch(pc.trim())) {
      return pc.trim();
    }
    final match = RegExp(r'\b\d{6}\b').firstMatch(fullText);
    if (match != null) {
      return match.group(0)!;
    }
    return pc.trim();
  }

  static String cleanDeduplicatedAddress(List<String> components) {
    List<String> filtered = [];
    for (var comp in components) {
      final trimmed = comp.trim();
      if (trimmed.isNotEmpty) {
        bool duplicate = filtered.any((existing) =>
            existing.toLowerCase().contains(trimmed.toLowerCase()) ||
            trimmed.toLowerCase().contains(existing.toLowerCase()));
        if (!duplicate) {
          filtered.add(trimmed);
        }
      }
    }
    return filtered.join(', ');
  }
}
