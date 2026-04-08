// lib/widgets/job_route_map.dart  [TECHNICIAN APP]
//
// Open-source map widget showing:
//   • Technician's live position (blue dot)
//   • Customer's location (red pin, geocoded from address)
//   • Driving route polyline between them (OSRM)
//
// Zero API keys required. All services are free/open-source:
//   • Tiles:     OpenStreetMap (openstreetmap.org)
//   • Geocoding: Nominatim    (nominatim.openstreetmap.org)
//   • Routing:   OSRM public  (router.project-osrm.org)
//
// pubspec.yaml — add these:
//   flutter_map: ^7.0.2
//   latlong2:    ^0.9.1
//   http:        ^1.2.1      (likely already present)

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/support_job_service.dart';
import '../theme/app_theme.dart';

class JobRouteMap extends StatefulWidget {
  final JobAddress? customerAddress;

  const JobRouteMap({super.key, required this.customerAddress});

  @override
  State<JobRouteMap> createState() => _JobRouteMapState();
}

class _JobRouteMapState extends State<JobRouteMap> {
  final _mapCtrl = MapController();

  // State
  LatLng?       _techLocation;
  LatLng?       _customerLocation;
  List<LatLng>  _routePoints = [];
  String?       _distance;
  String?       _duration;
  bool          _loadingGeo   = true;
  bool          _loadingRoute = false;
  String?       _geoError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _fetchTechLocation(),
      _geocodeCustomer(),
    ]);
    if (_techLocation != null && _customerLocation != null) {
      await _fetchRoute();
    }
    if (mounted) setState(() => _loadingGeo = false);
  }

  // ── Technician location ───────────────────────────────────────────────────

  Future<void> _fetchTechLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _techLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  // ── Nominatim geocoding ───────────────────────────────────────────────────

  Future<void> _geocodeCustomer() async {
    final addr = widget.customerAddress;
    if (addr == null || !addr.hasData) {
      _geoError = 'No address on file for this customer.';
      return;
    }

    try {
      final query = Uri.encodeComponent(addr.geocodeQuery);
      final uri   = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );

      final res = await http.get(uri, headers: {
        'User-Agent': 'SpeedonetTechApp/1.0',  // Nominatim requires User-Agent
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lng = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lng != null) {
            _customerLocation = LatLng(lat, lng);
            return;
          }
        }
      }
      _geoError = 'Could not locate customer address on map.';
    } catch (_) {
      _geoError = 'Could not locate customer address on map.';
    }
  }

  // ── OSRM routing ──────────────────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    final from = _techLocation!;
    final to   = _customerLocation!;

    setState(() => _loadingRoute = true);

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
            '?overview=full&geometries=geojson',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>;

        if (routes.isNotEmpty) {
          final route    = routes[0] as Map<String, dynamic>;
          final coords   = (route['geometry']['coordinates'] as List<dynamic>);
          final dist     = (route['distance'] as num).toDouble(); // metres
          final dur      = (route['duration'] as num).toDouble(); // seconds

          _routePoints = coords
              .map((c) => LatLng(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          ))
              .toList();

          // Format distance / duration
          _distance = dist < 1000
              ? '${dist.toStringAsFixed(0)} m'
              : '${(dist / 1000).toStringAsFixed(1)} km';

          final mins = (dur / 60).ceil();
          _duration = mins < 60 ? '$mins min' : '${(mins / 60).floor()}h ${mins % 60}m';

          // Fit map bounds to route
          if (mounted && _routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapCtrl.fitCamera(
                  CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
                );
              }
            });
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingRoute = false);
  }

  // ── Open in external maps app ─────────────────────────────────────────────

  Future<void> _openExternalMaps() async {
    final dest = _customerLocation;
    if (dest == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingGeo) {
      return _placeholder(
        icon: Icons.map_outlined,
        message: 'Locating customer…',
        loading: true,
      );
    }

    if (_customerLocation == null) {
      return _placeholder(
        icon: Icons.location_off_rounded,
        message: _geoError ?? 'Customer location unavailable.',
      );
    }

    final center = _techLocation != null
        ? LatLng(
      (_techLocation!.latitude  + _customerLocation!.latitude)  / 2,
      (_techLocation!.longitude + _customerLocation!.longitude) / 2,
    )
        : _customerLocation!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          SizedBox(
            height: 260,
            child: FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: center,
                initialZoom:   13,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.speedonet.tech',
                  maxZoom: 19,
                ),

                // Route polyline
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points:       _routePoints,
                        color:        AppColors.primary,
                        strokeWidth:  5,
                        borderColor:  Colors.white,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Customer pin
                    Marker(
                      point:  _customerLocation!,
                      width:  48,
                      height: 56,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color:  AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(
                                color:     AppColors.primary.withOpacity(0.4),
                                blurRadius: 8,
                              )],
                            ),
                            child: const Icon(Icons.home_rounded,
                                color: Colors.white, size: 16),
                          ),
                          CustomPaint(
                            size: const Size(12, 8),
                            painter: _TrianglePainter(AppColors.primary),
                          ),
                        ],
                      ),
                    ),

                    // Technician dot
                    if (_techLocation != null)
                      Marker(
                        point:  _techLocation!,
                        width:  20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color:  const Color(0xFF007AFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [BoxShadow(
                              color:     const Color(0xFF007AFF).withOpacity(0.4),
                              blurRadius: 8,
                            )],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Info strip (distance / duration) ──────────────────────────
          if (_distance != null)
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color:      Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  )],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.route_rounded, size: 15,
                      color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text('$_distance  ·  $_duration',
                      style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color:      AppColors.textDark,
                      )),
                ]),
              ),
            ),

          // ── Route loading indicator ────────────────────────────────────
          if (_loadingRoute)
            Positioned(
              top: 12, right: 12,
              child: Container(
                width: 32, height: 32,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            ),

          // ── External maps button ───────────────────────────────────────
          Positioned(
            bottom: 12, right: 12,
            child: GestureDetector(
              onTap: _openExternalMaps,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color:      Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  )],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.open_in_new_rounded, size: 14,
                      color: AppColors.primary),
                  SizedBox(width: 5),
                  Text('Navigate',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w700,
                        color:      AppColors.primary,
                      )),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder({
    required IconData icon,
    required String   message,
    bool loading = false,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color:        AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.borderColor),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (loading)
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            )
          else
            Icon(icon, size: 36, color: AppColors.textLight),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
        ]),
      ),
    );
  }
}

// ── Marker pin triangle ───────────────────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path  = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}