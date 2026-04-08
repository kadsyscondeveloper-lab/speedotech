// lib/services/technician_tracking_service.dart  [TECHNICIAN APP]
//
// Connects to ws://<host>/tracking/technician and streams the technician's
// GPS location to the backend every 5 seconds while a job is active.
//
// pubspec.yaml additions:
//   socket_io_client: ^2.0.3+1
//   geolocator: ^12.0.0
//
// AndroidManifest.xml  (inside <manifest>):
//   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
//   <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
//
// Info.plist (iOS):
//   NSLocationWhenInUseUsageDescription  → "To share your location with customers"
//   NSLocationAlwaysUsageDescription     → "To track your location while on a job"

import 'dart:async';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/app_config.dart';
import '../core/storage_service.dart';

typedef TrackingError = void Function(String message);

class TechnicianTrackingService {
  static final TechnicianTrackingService _i = TechnicianTrackingService._();
  factory TechnicianTrackingService() => _i;
  TechnicianTrackingService._();

  final _storage = StorageService();

  IO.Socket? _socket;
  Timer?     _timer;
  int?       _activeTicketId;
  bool       _running = false;

  bool get isTracking => _running;

  // ── Start ─────────────────────────────────────────────────────────────────

  Future<bool> startTracking({
    required int          ticketId,
    required TrackingError onError,
    VoidCallback?         onConnected,
  }) async {
    if (_running) return true;

    // 1. Check & request location permission
    final ok = await _ensurePermission();
    if (!ok) {
      onError('Location permission denied. Please enable it in Settings.');
      return false;
    }

    _activeTicketId = ticketId;

    // 2. Connect socket
    final wsHost = AppConfig.baseUrl.replaceFirst(RegExp(r'/api/v1.*'), '');
    final token  = _storage.accessToken ?? '';

    _socket = IO.io(
      '$wsHost/tracking/technician',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _running = true;
        onConnected?.call();
        // Start sending location immediately, then every 5 s
        _sendLocation();
        _timer = Timer.periodic(const Duration(seconds: 5), (_) => _sendLocation());
      })
      ..on('error', (data) {
        final msg = (data is Map ? data['message'] : data?.toString())
            ?? 'Tracking error';
        onError(msg as String);
      })
      ..onDisconnect((_) {
        _running = false;
        _timer?.cancel();
      })
      ..connect();

    return true;
  }

  // ── Stop ──────────────────────────────────────────────────────────────────

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _running = false;
    _activeTicketId = null;
  }

  // ── Send one location ping ─────────────────────────────────────────────────

  Future<void> _sendLocation() async {
    if (_socket == null || _activeTicketId == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      _socket!.emit('location:update', {
        'ticket_id': _activeTicketId,
        'lat':       pos.latitude,
        'lng':       pos.longitude,
      });
    } catch (_) {
      // GPS unavailable — silently skip this tick
    }
  }

  // ── Permission helper ─────────────────────────────────────────────────────

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }
}
