import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../core/network/api_constants.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

class OrderTrackerScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackerScreen({super.key, required this.order});

  @override
  State<OrderTrackerScreen> createState() => _OrderTrackerScreenState();
}

class _OrderTrackerScreenState extends State<OrderTrackerScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;

  // Map Coordinates
  late LatLng _storeLocation;
  late LatLng _deliveryLocation;
  LatLng? _driverLocation;
  LatLng? _previousDriverLocation;
  LatLng? _targetDriverLocation;
  double? _driverHeading;
  bool _isLocationStale = false;
  bool _hasRealDriverLocation = false;
  bool _hasAddressCoordinatesError = false;

  // Real Road Route State
  List<LatLng> _routePolylinePoints = [];
  double? _routeDistanceKm;
  double? _routeDurationMins;
  DateTime? _lastRouteFetchTime;
  LatLng? _lastRouteFetchOrigin;
  bool _isFetchingRoute = false;

  AnimationController? _markerAnimationController;
  Animation<double>? _markerAnimation;
  Timer? _pollingTimer;

  String _storeName = 'CartIT Central Hub';
  final String _driverName = 'Rajesh Kumar';
  final String _driverPhone = '+91 9876543210';

  // Rating State
  int _selectedRating = 5;
  final TextEditingController _ratingCommentController = TextEditingController();
  bool _isSubmittingRating = false;

  /// Calculate minimum geographic distance from point P to line segment AB in meters
  double _distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final double lengthAB = Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
    if (lengthAB == 0) return Geolocator.distanceBetween(p.latitude, p.longitude, a.latitude, a.longitude);

    final double cosLat = math.cos((a.latitude * math.pi) / 180.0);
    final double vx = (b.longitude - a.longitude) * cosLat;
    final double vy = (b.latitude - a.latitude);
    final double ux = (p.longitude - a.longitude) * cosLat;
    final double uy = (p.latitude - a.latitude);

    final double dot = ux * vx + uy * vy;
    final double lenSq = vx * vx + vy * vy;
    double t = lenSq == 0 ? 0 : dot / lenSq;
    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;

    final LatLng closestPoint = LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );

    return Geolocator.distanceBetween(p.latitude, p.longitude, closestPoint.latitude, closestPoint.longitude);
  }

  /// Calculate minimum geographic distance from point P to any segment of a polyline
  double _minDistanceToPolylineMeters(LatLng p, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) {
      return Geolocator.distanceBetween(p.latitude, p.longitude, polyline.first.latitude, polyline.first.longitude);
    }

    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final dist = _distanceToSegmentMeters(p, polyline[i], polyline[i + 1]);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }

  Future<void> _fetchRoadRoute(int orderId, LatLng origin) async {
    if (_isFetchingRoute) return;
    _isFetchingRoute = true;
    try {
      final response = await ApiService().client.get(
        '${ApiConstants.orders}/$orderId/route',
        queryParameters: {
          'originLat': origin.latitude,
          'originLng': origin.longitude,
        },
      );

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['status'] == 'SUCCESS') {
          final List rawPoints = data['points'] ?? [];
          final List<LatLng> parsedPoints = [];
          for (var p in rawPoints) {
            if (p is List && p.length >= 2) {
              final lat = (p[0] as num).toDouble();
              final lng = (p[1] as num).toDouble();
              parsedPoints.add(LatLng(lat, lng));
            }
          }

          if (parsedPoints.isNotEmpty) {
            _routePolylinePoints = parsedPoints;
            _routeDistanceKm = (data['distanceKm'] as num?)?.toDouble();
            _routeDurationMins = (data['durationMins'] as num?)?.toDouble();
            _lastRouteFetchTime = DateTime.now();
            _lastRouteFetchOrigin = origin;
            if (mounted) setState(() {});
          }
        } else {
          // Route engine failed or unavailable - NEVER render straight line
          _routePolylinePoints = [];
          _routeDistanceKm = null;
          _routeDurationMins = null;
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      debugPrint('[OrderTrackerScreen] Route fetch error: $e');
    } finally {
      _isFetchingRoute = false;
    }
  }

  void _checkAndRefreshRoute(int orderId, LatLng origin, bool isDeliveryActive) {
    if (isDeliveryActive && !_hasRealDriverLocation) {
      return; // Await driver location fix
    }

    if (_routePolylinePoints.isEmpty || _lastRouteFetchTime == null || _lastRouteFetchOrigin == null) {
      _fetchRoadRoute(orderId, origin);
      return;
    }

    final secondsSinceLastFetch = DateTime.now().difference(_lastRouteFetchTime!).inSeconds;
    final originMovementMeters = Geolocator.distanceBetween(
      origin.latitude, origin.longitude,
      _lastRouteFetchOrigin!.latitude, _lastRouteFetchOrigin!.longitude
    );

    // Refresh if >90s AND driver moved > 20 meters
    if (secondsSinceLastFetch > 90 && originMovementMeters > 20.0) {
      _fetchRoadRoute(orderId, origin);
      return;
    }

    // Point-to-segment deviation threshold (> 150m from line segments)
    final minSegDistanceMeters = _minDistanceToPolylineMeters(origin, _routePolylinePoints);
    if (minSegDistanceMeters > 150.0) {
      debugPrint('[OrderTrackerScreen] Point-to-segment off-route deviation detected (${minSegDistanceMeters.toStringAsFixed(0)}m > 150m). Recalculating route...');
      _fetchRoadRoute(orderId, origin);
    }
  }

  @override
  void initState() {
    super.initState();

    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _markerAnimation = CurvedAnimation(
      parent: _markerAnimationController!,
      curve: Curves.easeInOut,
    );

    final addr = widget.order.shippingAddress;
    if (addr?.latitude != null && addr!.latitude! != 0.0 && addr.longitude != null && addr.longitude! != 0.0) {
      _deliveryLocation = LatLng(addr.latitude!, addr.longitude!);
      _hasAddressCoordinatesError = false;
    } else {
      // Default placeholder when coordinates missing - flag address-location error
      _deliveryLocation = const LatLng(12.9716, 77.5946);
      _hasAddressCoordinatesError = true;
    }
    _storeLocation = LatLng(_deliveryLocation.latitude - 0.012, _deliveryLocation.longitude - 0.010);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapBounds();
      _resolveActualLocations();
      _updateDriverState(widget.order);
    });

    // Authoritative periodic backend order polling (every 3s)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await context.read<OrderProvider>().fetchMyOrders();
      if (!mounted) return;
      final provider = context.read<OrderProvider>();
      final current = provider.orders.firstWhere(
        (o) => o.id == widget.order.id,
        orElse: () => widget.order,
      );
      final status = current.status.toUpperCase();
      if (status == 'DELIVERED' || status == 'CANCELLED') {
        timer.cancel();
      }
      _updateDriverState(current);
      if (mounted) setState(() {});
    });
  }

  void _updateDriverState(OrderModel currentOrder) {
    if (currentOrder.storeLat != null && currentOrder.storeLng != null) {
      _storeLocation = LatLng(currentOrder.storeLat!, currentOrder.storeLng!);
    }
    if (currentOrder.storeName != null && currentOrder.storeName!.isNotEmpty) {
      _storeName = currentOrder.storeName!;
    }

    final dLat = currentOrder.currentDeliveryLat;
    final dLng = currentOrder.currentDeliveryLng;
    final dHeading = currentOrder.currentDeliveryHeading;
    final dUpdatedAt = currentOrder.currentDeliveryUpdatedAt;

    if (dLat != null && dLng != null && (dLat != 0.0 || dLng != 0.0) && dLat >= -90.0 && dLat <= 90.0 && dLng >= -180.0 && dLng <= 180.0) {
      final newLoc = LatLng(dLat, dLng);

      bool stale = false;
      if (dUpdatedAt != null && dUpdatedAt.isNotEmpty) {
        try {
          final dt = DateTime.parse(dUpdatedAt);
          if (DateTime.now().toUtc().difference(dt.toUtc()).inSeconds.abs() > 120) {
            stale = true;
          }
        } catch (_) {}
      }
      _isLocationStale = stale;

      if (_driverLocation == null) {
        _driverLocation = newLoc;
        _previousDriverLocation = newLoc;
        _targetDriverLocation = newLoc;
        _hasRealDriverLocation = true;
      } else if (_driverLocation != newLoc) {
        _previousDriverLocation = _animatedDriverLocation;
        _targetDriverLocation = newLoc;
        _driverLocation = newLoc;
        _hasRealDriverLocation = true;
        _markerAnimationController?.forward(from: 0.0);
      }
      _driverHeading = dHeading;
    } else {
      _hasRealDriverLocation = false;
    }

    final status = currentOrder.status.toUpperCase();
    final isDeliveryActive = _isOutForDelivery(status);

    if (isDeliveryActive && _hasRealDriverLocation && _driverLocation != null) {
      _checkAndRefreshRoute(widget.order.id, _driverLocation!, true);
    } else if (!isDeliveryActive && _routePolylinePoints.isEmpty) {
      _checkAndRefreshRoute(widget.order.id, _storeLocation, false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _markerAnimationController?.dispose();
    _mapController?.dispose();
    _ratingCommentController.dispose();
    super.dispose();
  }

  LatLng get _animatedDriverLocation {
    if (_previousDriverLocation == null || _targetDriverLocation == null || _markerAnimation == null) {
      return _driverLocation ?? _storeLocation;
    }
    final t = _markerAnimation!.value;
    final lat = _previousDriverLocation!.latitude +
        (_targetDriverLocation!.latitude - _previousDriverLocation!.latitude) * t;
    final lng = _previousDriverLocation!.longitude +
        (_targetDriverLocation!.longitude - _previousDriverLocation!.longitude) * t;
    return LatLng(lat, lng);
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    final points = <LatLng>[_storeLocation, _deliveryLocation];
    if (_hasRealDriverLocation && _driverLocation != null && !_isLocationStale) {
      points.add(_driverLocation!);
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  Set<Marker> _buildGoogleMapMarkers(bool isDeliveryActive, OrderModel currentOrder) {
    final markers = <Marker>{
      // Store Hub Marker
      Marker(
        markerId: const MarkerId('store'),
        position: _storeLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: _storeName,
          snippet: 'Store Hub',
        ),
      ),
      // Customer Destination Marker
      Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Deliver to ${currentOrder.shippingAddress?.fullName.split(' ').first ?? 'Customer'}',
          snippet: currentOrder.shippingAddress?.street ?? 'Delivery Location',
        ),
      ),
    };

    if (isDeliveryActive && _hasRealDriverLocation && !_isLocationStale && _driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _animatedDriverLocation,
          rotation: _driverHeading ?? 0.0,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: 'Delivery Partner ($_driverName)',
            snippet: 'Real-time GPS Location',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildGoogleMapPolylines() {
    final polylines = <Polyline>{};
    if (_routePolylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('road_route'),
          points: _routePolylinePoints,
          color: AppColors.primary,
          width: 5,
        ),
      );
    }
    return polylines;
  }

  Future<void> _resolveActualLocations() async {
    // FETCH REAL STORE LOCATION DETAILS FROM BACKEND (GET /api/store)
    try {
      final response = await ApiService().client.get(ApiConstants.store);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          final sLat = (data['latitude'] as num?)?.toDouble();
          final sLng = (data['longitude'] as num?)?.toDouble();
          final name = data['name']?.toString();
          if (name != null && name.isNotEmpty) {
            _storeName = name;
          }
          if (sLat != null && sLat != 0.0 && sLng != null && sLng != 0.0) {
            _storeLocation = LatLng(sLat, sLng);
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;

    // FETCH REAL CUSTOMER DELIVERY ADDRESS LOCATION
    final orderProvider = context.read<OrderProvider>();
    final currentOrder = orderProvider.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    final addr = currentOrder.shippingAddress ?? widget.order.shippingAddress;
    if (addr != null) {
      if (addr.latitude != null && addr.latitude! != 0.0 && addr.longitude != null && addr.longitude! != 0.0) {
        _deliveryLocation = LatLng(addr.latitude!, addr.longitude!);
      } else {
        try {
          final queryParts = [addr.street, addr.city, addr.state, addr.zipCode, addr.country]
              .where((s) => s.trim().isNotEmpty)
              .join(', ');

          if (queryParts.isNotEmpty) {
            final encoded = Uri.encodeComponent(queryParts);
            final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$encoded&limit=1';

            final response = await Dio().get(
              url,
              options: Options(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                headers: {'User-Agent': 'CartITApp/1.0 (contact@cartit.com)'},
              ),
            );

            if (response.statusCode == 200 && response.data != null) {
              final list = response.data as List;
              if (list.isNotEmpty) {
                final lat = double.parse(list[0]['lat'].toString());
                final lon = double.parse(list[0]['lon'].toString());
                _deliveryLocation = LatLng(lat, lon);
              }
            }
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      _fitMapBounds();
    }
  }

  bool _isOutForDelivery(String status) {
    final s = status.toUpperCase();
    return s == 'SHIPPED' || s == 'OUT_FOR_DELIVERY' || s == 'ARRIVED_AT_CUSTOMER';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch live order from provider matching widget.order.id
    final orderProvider = context.watch<OrderProvider>();
    final currentOrder = orderProvider.orders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );

    final status = currentOrder.status.toUpperCase();
    final isDeliveryActive = _isOutForDelivery(status);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkTitle : AppColors.title,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order #${currentOrder.orderNumber}',
              style: TextStyle(
                color: isDark ? AppColors.darkTitle : AppColors.title,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              isDeliveryActive ? 'Live Delivery Map Tracking' : 'Live Order Tracking',
              style: TextStyle(
                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
            onPressed: _fitMapBounds,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_hasAddressCoordinatesError)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: Colors.red.shade700,
                child: const Row(
                  children: [
                    Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address location coordinates missing. Please update delivery address location.',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // -----------------------------------------------------------------
            // 1. EMBEDDED MAP VIEW AT THE TOP OF THE TRACKER SCREEN
            // -----------------------------------------------------------------
            Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: (isDeliveryActive && _hasRealDriverLocation && _driverLocation != null)
                            ? _driverLocation!
                            : _deliveryLocation,
                        zoom: 14.2,
                      ),
                      markers: _buildGoogleMapMarkers(isDeliveryActive, currentOrder),
                      polylines: _buildGoogleMapPolylines(),
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _fitMapBounds();
                      },
                    ),

                    // Top ETA / GPS Status Badge overlay on map when delivery active
                    if (isDeliveryActive)
                      Positioned(
                        top: 12,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_hasRealDriverLocation && !_isLocationStale) ? Colors.white : Colors.amber.shade900,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (_hasRealDriverLocation && !_isLocationStale) ? Icons.navigation_rounded : Icons.gps_off_rounded,
                                color: (_hasRealDriverLocation && !_isLocationStale) ? AppColors.primary : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (_hasRealDriverLocation && !_isLocationStale)
                                    ? (_routePolylinePoints.isNotEmpty && _routeDurationMins != null && _routeDistanceKm != null
                                        ? 'Arriving in ${_routeDurationMins!.toStringAsFixed(0)} mins (${_routeDistanceKm!.toStringAsFixed(1)} km)'
                                        : (_routePolylinePoints.isEmpty ? 'Road Route Unavailable' : 'Live Driver GPS Active'))
                                    : (_isLocationStale ? 'Driver GPS Signal Stale' : 'Awaiting Driver GPS Update...'),
                                style: TextStyle(
                                  color: (_hasRealDriverLocation && !_isLocationStale) ? AppColors.title : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 2. LIVE HERO STATUS BANNER BELOW MAP
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusHeaderColor(status),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusHeaderColor(status).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getStatusHeaderIcon(status), color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusHeaderTitle(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusHeaderSubtitle(status),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Delivery Partner Info Box (Visible when Out for Delivery)
            if (isDeliveryActive) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentOrder.deliveryBoyName ?? _driverName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTitle : AppColors.title,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Delivery Partner • CartIT Express (${currentOrder.deliveryBoyPhone ?? _driverPhone})',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 18),
                          onPressed: () {
                            final name = currentOrder.deliveryBoyName ?? _driverName;
                            final phone = currentOrder.deliveryBoyPhone ?? _driverPhone;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Calling $name ($phone)...'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 3. 5-STEP ORDER PROGRESS TIMELINE STEPPER
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Progress',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkTitle : AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _build5StepTimelineStepper(status, isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 4. EMBEDDED RATING CARD IF DELIVERED
            // -----------------------------------------------------------------
            if (status == 'DELIVERED') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildEmbeddedRatingCard(context, currentOrder, isDark),
              ),
              const SizedBox(height: 16),
            ],

            // -----------------------------------------------------------------
            // 5. ITEMS IN THIS ORDER LIST CARD
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Text(
                        'Items in this Order (${currentOrder.items.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkCardBorder : AppColors.border),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentOrder.items.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? AppColors.darkCardBorder : AppColors.border),
                      itemBuilder: (context, index) {
                        final item = currentOrder.items[index];
                        return ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            item.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                            ),
                          ),
                          subtitle: Text(
                            'Qty: ${item.quantity} × ${Formatters.currency(item.price)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                            ),
                          ),
                          trailing: Text(
                            Formatters.currency(item.totalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontSize: 13.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // 6. DELIVERY ADDRESS CARD
            // -----------------------------------------------------------------
            if (currentOrder.shippingAddress != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentOrder.shippingAddress!.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${currentOrder.shippingAddress!.street}, ${currentOrder.shippingAddress!.city}, ${currentOrder.shippingAddress!.state} - ${currentOrder.shippingAddress!.zipCode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Phone: ${currentOrder.shippingAddress!.phone}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // -----------------------------------------------------------------
            // 7. BILL & PAYMENT DETAILS
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkTitle : AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Item Total',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                          ),
                        ),
                        Text(
                          Formatters.currency(currentOrder.totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                        ),
                      ],
                    ),
                    if (currentOrder.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Discount Savings',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '-${Formatters.currency(currentOrder.discountAmount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Fee',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                          ),
                        ),
                        Text(
                          currentOrder.deliveryCharge > 0
                              ? Formatters.currency(currentOrder.deliveryCharge)
                              : 'FREE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: currentOrder.deliveryCharge > 0
                                ? (isDark ? AppColors.darkTitle : AppColors.title)
                                : AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20, color: isDark ? AppColors.darkCardBorder : AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Paid (${currentOrder.paymentMethod})',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                        ),
                        Text(
                          Formatters.currency(currentOrder.finalAmount > 0 ? currentOrder.finalAmount : currentOrder.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CANCEL ORDER OPTION
            if (status == 'PENDING' || status == 'CONFIRMED') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Order?'),
                          content: const Text('Are you sure you want to cancel this order?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        final success = await context.read<OrderProvider>().cancelOrder(currentOrder.id);
                        if (!context.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order cancelled successfully'),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    label: const Text(
                      'Cancel Order',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 5-STEP TIMELINE STEPPER WITH ORDER PACKED STATUS
  /// -------------------------------------------------------------------------
  Widget _build5StepTimelineStepper(String status, bool isDark) {
    int currentStepIndex = 1;
    if (status == 'CONFIRMED') {
      currentStepIndex = 2; // Getting Packed
    } else if (status == 'PACKED' || status == 'ARRIVED_AT_STORE') {
      currentStepIndex = 3; // Order Packed
    } else if (status == 'SHIPPED' || status == 'OUT_FOR_DELIVERY' || status == 'ARRIVED_AT_CUSTOMER') {
      currentStepIndex = 4; // Out for Delivery
    } else if (status == 'DELIVERED') {
      currentStepIndex = 5; // Delivered
    } else if (status == 'CANCELLED') {
      currentStepIndex = 0;
    }

    final steps = [
      {'title': 'Order Placed', 'sub': 'Order confirmed'},
      {'title': 'Getting Packed', 'sub': 'Items selected at store'},
      {'title': 'Order Packed', 'sub': 'Items packed & ready for pickup'},
      {'title': 'Out for Delivery', 'sub': 'Partner on the way (Map live)'},
      {'title': 'Delivered', 'sub': 'Successfully arrived at doorstep'},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final stepNum = index + 1;
        final isPassed = currentStepIndex >= stepNum && currentStepIndex > 0;
        final isCurrent = currentStepIndex == stepNum;
        final isLast = index == steps.length - 1;

        Color dotColor = Colors.grey.shade400;
        if (isPassed) dotColor = const Color(0xFF00B259);
        if (isCurrent) dotColor = AppColors.primary;
        if (status == 'CANCELLED') dotColor = Colors.grey.shade500;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: Center(
                    child: isPassed
                        ? Icon(Icons.check_rounded, color: dotColor, size: 15)
                        : Text(
                            '$stepNum',
                            style: TextStyle(
                              color: dotColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 34,
                    color: isPassed ? const Color(0xFF00B259) : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index]['title']!,
                      style: TextStyle(
                        fontWeight: isPassed ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 13.5,
                        color: isPassed
                            ? (isDark ? AppColors.darkTitle : AppColors.title)
                            : (isDark ? AppColors.darkSubtitle : Colors.grey.shade500),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      steps[index]['sub']!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// -------------------------------------------------------------------------
  /// EMBEDDED RATING CARD IF DELIVERED
  /// -------------------------------------------------------------------------
  Widget _buildEmbeddedRatingCard(BuildContext context, OrderModel order, bool isDark) {
    final alreadyRated = order.rating != null && order.rating! > 0;

    if (alreadyRated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Icon(
                  i < order.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFFFB800),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thank you for rating your delivery!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFB45309),
                fontSize: 13,
              ),
            ),
            if (order.reviewComment != null && order.reviewComment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"${order.reviewComment}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: isDark ? AppColors.darkSubtitle : Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            'How was your 10-minute delivery?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTitle : AppColors.title,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap stars to rate',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starVal = index + 1;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedRating = starVal;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starVal <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 34,
                    color: starVal <= _selectedRating ? const Color(0xFFFFB800) : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Optional comment field
          TextField(
            controller: _ratingCommentController,
            maxLines: 2,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkTitle : AppColors.title,
            ),
            decoration: InputDecoration(
              hintText: 'Add a comment (optional)...',
              hintStyle: TextStyle(
                fontSize: 11.5,
                color: isDark ? AppColors.darkSubtitle : Colors.grey.shade500,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _isSubmittingRating
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final orderProvider = context.read<OrderProvider>();
                      setState(() => _isSubmittingRating = true);
                      final success = await orderProvider.rateOrder(
                            order.id,
                            _selectedRating,
                            reviewComment: _ratingCommentController.text,
                          );
                      if (!mounted) return;
                      setState(() => _isSubmittingRating = false);

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Thank you for your rating!' : 'Rating submitted!',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmittingRating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Submit Rating',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Status Theme Helpers
  Color _getStatusHeaderColor(String status) {
    switch (status) {
      case 'PLACED':
      case 'PENDING':
      case 'CONFIRMED':
        return const Color(0xFF2563EB); // Blue
      case 'PACKED':
      case 'ARRIVED_AT_STORE':
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
      case 'ARRIVED_AT_CUSTOMER':
        return const Color(0xFF00B259); // Zepto Green
      case 'DELIVERED':
        return const Color(0xFF10B981); // Emerald
      case 'CANCELLED':
        return const Color(0xFFEF4444); // Red
      default:
        return AppColors.primary;
    }
  }

  String _getStatusHeaderTitle(String status) {
    switch (status) {
      case 'PLACED':
      case 'PENDING':
        return 'Order Placed & Confirmed';
      case 'CONFIRMED':
        return 'Store Preparing Your Order';
      case 'PACKED':
      case 'ARRIVED_AT_STORE':
        return 'Order Packed & Ready for Pickup';
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
      case 'ARRIVED_AT_CUSTOMER':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Order Successfully Delivered! 🎉';
      case 'CANCELLED':
        return 'Order Cancelled';
      default:
        return 'Order Processing';
    }
  }

  String _getStatusHeaderSubtitle(String status) {
    switch (status) {
      case 'PLACED':
      case 'PENDING':
        return 'We have received your order. Dark store team is selecting items.';
      case 'CONFIRMED':
        return 'Items are being packed at the nearest dark store hub.';
      case 'PACKED':
      case 'ARRIVED_AT_STORE':
        return 'Order is packed and ready for delivery partner pickup.';
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
      case 'ARRIVED_AT_CUSTOMER':
        return 'Delivery partner is on the way to your location.';
      case 'DELIVERED':
        return 'Your items were delivered in 10 minutes.';
      case 'CANCELLED':
        return 'This order has been cancelled.';
      default:
        return 'Order status updated live.';
    }
  }

  IconData _getStatusHeaderIcon(String status) {
    switch (status) {
      case 'PLACED':
      case 'PENDING':
        return Icons.receipt_long_rounded;
      case 'CONFIRMED':
      case 'PACKED':
      case 'ARRIVED_AT_STORE':
        return Icons.inventory_2_rounded;
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
      case 'ARRIVED_AT_CUSTOMER':
        return Icons.local_shipping_rounded;
      case 'DELIVERED':
        return Icons.check_circle_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.local_mall_rounded;
    }
  }
}
