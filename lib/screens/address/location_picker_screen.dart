import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../app/app_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late LatLng _currentCenter;
  Timer? _debounceTimer;

  bool _isGeocoding = false;
  bool _isSearching = false;
  bool _isDragging = false;
  bool _isSatellite = false;
  bool? _overrideMapDark; // null = follow system theme, true = force dark map, false = force light map
  List<Map<String, dynamic>> _searchResults = [];

  String _areaTitle = 'Fetching location...';
  String _street = '';
  String _city = '';
  String _state = '';
  String _pincode = '';
  String _displayAddress = 'Drag map to pin exact delivery location';

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialPosition ?? const LatLng(12.9716, 77.5946); // Default Bengaluru
    _initCurrentLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location services (GPS) are turned off. Please turn on GPS location.'),
              backgroundColor: AppColors.warning,
              action: SnackBarAction(
                label: 'GPS SETTINGS',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        _reverseGeocode(_currentCenter);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission denied. You can drag map pin manually.'),
              backgroundColor: AppColors.warning,
              action: SnackBarAction(
                label: 'PERMISSIONS',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        _reverseGeocode(_currentCenter);
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null && mounted) {
        final newCenter = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentCenter = newCenter;
        });
        _mapController.move(newCenter, 16.5);
        _reverseGeocode(newCenter);
      } else {
        _reverseGeocode(_currentCenter);
      }
    } catch (_) {
      _reverseGeocode(_currentCenter);
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && !_isDragging) {
      setState(() => _isDragging = true);
    }
    _currentCenter = camera.center;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _isDragging = false);
      }
      _reverseGeocode(_currentCenter);
    });
  }

  String _extractPincode(String pc, String fullText) {
    if (pc.trim().isNotEmpty && RegExp(r'^\d{6}$').hasMatch(pc.trim())) {
      return pc.trim();
    }
    final match = RegExp(r'\b\d{6}\b').firstMatch(fullText);
    if (match != null) {
      return match.group(0)!;
    }
    return pc.trim();
  }

  String _cleanDeduplicatedAddress(List<String> components) {
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

  Future<void> _reverseGeocode(LatLng target) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    bool success = await _reverseGeocodePhoton(target);
    if (!success) {
      success = await _reverseGeocodeNominatim(target);
    }
    if (!success) {
      success = await _reverseGeocodeBigDataCloud(target);
    }

    if (!success && mounted) {
      setState(() {
        _isGeocoding = false;
        _areaTitle = 'Pinned Location';
        _displayAddress =
            'Location near (${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)})';
      });
    }
  }

  Future<bool> _reverseGeocodePhoton(LatLng target) async {
    try {
      final dio = Dio();
      final url = 'https://photon.komoot.io/reverse?lat=${target.latitude}&lon=${target.longitude}';
      final response = await dio.get(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode == 200 && response.data != null && mounted) {
        final features = (response.data['features'] as List?) ?? [];
        if (features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>? ?? {};

          final name = props['name']?.toString() ?? '';
          final housenumber = props['housenumber']?.toString() ?? '';
          final streetName = props['street']?.toString() ?? '';
          final district = props['district']?.toString() ?? props['suburb']?.toString() ?? '';
          final ct = props['city']?.toString() ?? props['county']?.toString() ?? props['state']?.toString() ?? '';
          final stt = props['state']?.toString() ?? '';
          final pcRaw = props['postcode']?.toString() ?? '';

          List<String> streetParts = [];
          if (name.isNotEmpty) streetParts.add(name);
          if (housenumber.isNotEmpty && housenumber != name) streetParts.add(housenumber);
          if (streetName.isNotEmpty && streetName != name) streetParts.add(streetName);
          if (district.isNotEmpty && district != streetName && district != name) streetParts.add(district);

          final fullStreet = streetParts.isNotEmpty ? streetParts.join(', ') : (district.isNotEmpty ? district : ct);

          // Priority area header: POI name > Street + Suburb > Street > District > City
          final areaName = name.isNotEmpty
              ? name
              : (streetName.isNotEmpty
                  ? (district.isNotEmpty ? '$streetName, $district' : streetName)
                  : (district.isNotEmpty ? district : (ct.isNotEmpty ? ct : 'Selected Location')));

          final finalPincode = _extractPincode(pcRaw, [fullStreet, ct, stt].join(' '));
          final fullAddr = _cleanDeduplicatedAddress([fullStreet, ct, stt, finalPincode]);

          setState(() {
            _areaTitle = areaName;
            _street = fullStreet;
            _city = ct;
            _state = stt;
            _pincode = finalPincode;
            _displayAddress = fullAddr;
            _isGeocoding = false;
          });
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _reverseGeocodeNominatim(LatLng target) async {
    try {
      final dio = Dio();
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${target.latitude}&lon=${target.longitude}&zoom=18&addressdetails=1';
      final response = await dio.get(
        url,
        options: Options(
          headers: {'User-Agent': 'CartITApp/1.0 (contact@cartit.com)'},
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode == 200 && response.data != null && mounted) {
        final map = response.data['address'] as Map<String, dynamic>? ?? {};
        final name = response.data['name']?.toString() ?? '';

        final amenity = map['amenity'] ?? map['building'] ?? map['shop'] ?? map['office'] ?? '';
        final houseNumber = map['house_number'] ?? map['building'] ?? '';
        final road = map['road'] ?? map['pedestrian'] ?? map['path'] ?? map['footway'] ?? '';
        final suburb = map['suburb'] ?? map['neighbourhood'] ?? map['residential'] ?? map['quarter'] ?? '';
        final ct = map['city'] ?? map['town'] ?? map['village'] ?? map['county'] ?? map['state_district'] ?? '';
        final stt = map['state'] ?? '';
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
          } else if (split.length >= 2) {
            streetLine = '${split[0].trim()}, ${split[1].trim()}';
          } else {
            streetLine = split[0].trim();
          }
        }

        // Priority header title: POI name > Road + Suburb > Road > Suburb > City
        final areaName = name.isNotEmpty
            ? name
            : (road.toString().isNotEmpty
                ? (suburb.toString().isNotEmpty ? '${road.toString()}, ${suburb.toString()}' : road.toString())
                : (suburb.toString().isNotEmpty ? suburb.toString() : (ct.toString().isNotEmpty ? ct.toString() : 'Selected Location')));

        final finalPincode = _extractPincode(pcRaw.toString(), rawDisplayName);
        final fullAddr = _cleanDeduplicatedAddress([streetLine, ct.toString(), stt.toString(), finalPincode]);

        setState(() {
          _areaTitle = areaName;
          _street = streetLine;
          _city = ct.toString();
          _state = stt.toString();
          _pincode = finalPincode;
          _displayAddress = fullAddr;
          _isGeocoding = false;
        });
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _reverseGeocodeBigDataCloud(LatLng target) async {
    try {
      final dio = Dio();
      final url =
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${target.latitude}&longitude=${target.longitude}&localityLanguage=en';
      final response = await dio.get(
        url,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode == 200 && response.data != null && mounted) {
        final data = response.data as Map<String, dynamic>;
        final localityInfo = data['localityInfo'] as Map<String, dynamic>? ?? {};
        final informative = (localityInfo['informative'] as List?) ?? [];

        final streetName = informative.isNotEmpty
            ? (informative[0]['name'] ?? '')
            : (data['locality'] ?? data['city'] ?? '');
        final cityText = data['locality'] ?? data['city'] ?? '';
        final stateText = data['principalSubdivision'] ?? '';
        final postcodeText = data['postcode'] ?? '';

        final fullDisplay = _cleanDeduplicatedAddress([
          streetName.toString(),
          cityText.toString(),
          stateText.toString(),
          postcodeText.toString()
        ]);
        final finalPincode = _extractPincode(postcodeText.toString(), fullDisplay);

        final areaName = streetName.toString().isNotEmpty ? streetName.toString() : (cityText.toString().isNotEmpty ? cityText.toString() : 'Selected Location');

        setState(() {
          _areaTitle = areaName;
          _street = streetName.toString();
          _city = cityText.toString();
          _state = stateText.toString();
          _pincode = finalPincode;
          _displayAddress = fullDisplay;
          _isGeocoding = false;
        });
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final dio = Dio();
      final url =
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&countrycodes=in';
      final response = await dio.get(
        url,
        options: Options(
          headers: {'User-Agent': 'CartITApp/1.0'},
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200 && response.data != null && mounted) {
        final list = List<Map<String, dynamic>>.from(response.data);
        setState(() {
          _searchResults = list;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(result['lon']?.toString() ?? '') ?? 0.0;

    if (lat != 0.0 && lon != 0.0) {
      final target = LatLng(lat, lon);
      _mapController.move(target, 16.5);
      setState(() {
        _currentCenter = target;
        _searchResults = [];
        _searchController.clear();
      });
      FocusScope.of(context).unfocus();
      _reverseGeocode(target);
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(3.0, 20.0));
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(3.0, 20.0));
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'street': _street,
      'city': _city,
      'state': _state,
      'zipCode': _pincode,
      'latitude': _currentCenter.latitude.toString(),
      'longitude': _currentCenter.longitude.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final systemIsDark = Theme.of(context).brightness == Brightness.dark;
    final mapIsDark = _overrideMapDark ?? systemIsDark;
    final isDark = systemIsDark;

    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Official Real-Time Google Maps Tile Engine
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 16.5,
                minZoom: 3.0,
                maxZoom: 20.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onPositionChanged: _onMapPositionChanged,
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatellite
                      ? 'https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                      : 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                  tileBuilder: mapIsDark && !_isSatellite
                      ? (context, tileWidget, tile) {
                          return ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              -0.9, 0.0, 0.0, 0.0, 255,
                              0.0, -0.9, 0.0, 0.0, 255,
                              0.0, 0.0, -0.9, 0.0, 255,
                              0.0, 0.0, 0.0, 1.0, 0,
                            ]),
                            child: tileWidget,
                          );
                        }
                      : null,
                  userAgentPackageName: 'com.example.cartit',
                  maxZoom: 20,
                  tileProvider: NetworkTileProvider(),
                ),
              ],
            ),

            // Center Pin Marker with Exact Google Maps Needle Alignment
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -24), // Offset half of the pin height (48px / 2) so pin tip points to exact map center
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Floating Delivery Tooltip
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0E2319) : Colors.black.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: isDark ? Border.all(color: AppColors.darkCardBorder) : null,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDragging ? Icons.location_searching_rounded : Icons.check_circle_rounded,
                              color: _isDragging ? AppColors.secondary : AppColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isDragging ? 'Locating exact building...' : 'Order will be delivered here',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Animated Google Maps Needle Pin
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: Matrix4.translationValues(0, _isDragging ? -12 : 0, 0),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Ground shadow pulse
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: _isDragging ? 8 : 16,
                              height: _isDragging ? 3 : 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: _isDragging ? 0.15 : 0.35),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const Icon(
                              Icons.location_on_rounded,
                              size: 48,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Search Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                              fontSize: 14,
                            ),
                            onChanged: (val) {
                              _debounceTimer?.cancel();
                              _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                                _searchLocation(val);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search area, street, or landmark...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                      ),
                                    )
                                  : _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            size: 18,
                                            color: isDark ? AppColors.darkTitle : AppColors.title,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchResults = []);
                                          },
                                        )
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: borderColor,
                        ),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                              child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 16),
                            ),
                            title: Text(
                              item['display_name'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTitle : AppColors.title,
                              ),
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Map Style Toggle & Zoom Controls
            Positioned(
              right: 16,
              bottom: 240,
              child: Column(
                children: [
                  // Map Dark / Light Theme Toggle Button
                  FloatingActionButton.small(
                    heroTag: 'map_theme_toggle',
                    onPressed: () {
                      setState(() {
                        if (mapIsDark) {
                          _overrideMapDark = false;
                        } else {
                          _overrideMapDark = true;
                        }
                      });
                    },
                    backgroundColor: cardBgColor,
                    elevation: 3,
                    child: Icon(
                      mapIsDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: mapIsDark ? Colors.amberAccent : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Satellite Layer Toggle
                  FloatingActionButton.small(
                    heroTag: 'map_layer_toggle',
                    onPressed: () => setState(() => _isSatellite = !_isSatellite),
                    backgroundColor: cardBgColor,
                    elevation: 3,
                    child: Icon(
                      _isSatellite ? Icons.map_rounded : Icons.layers_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_gmaps',
                    onPressed: _zoomIn,
                    backgroundColor: cardBgColor,
                    elevation: 3,
                    child: Icon(
                      Icons.add,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_gmaps',
                    onPressed: _zoomOut,
                    backgroundColor: cardBgColor,
                    elevation: 3,
                    child: Icon(
                      Icons.remove,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Delivery Sheet Card
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SELECT DELIVERY LOCATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _initCurrentLocation,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.my_location_rounded, color: AppColors.primary, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'GPS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _areaTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                            ),
                          ),
                        ),
                        if (_isGeocoding)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Text(
                      _displayAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Confirm Location & Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
}
