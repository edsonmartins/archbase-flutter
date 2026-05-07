import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:geolocator/geolocator.dart';

import '../../core/state/archbase_service.dart';

/// Posição com endereço opcional resolvido por geocoding reverso.
class ArchbasePlace {
  ArchbasePlace({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
    this.address,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? timestamp;
  final String? address;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp?.toIso8601String(),
        if (address != null) 'address': address,
      };

  factory ArchbasePlace.fromPosition(Position p, {String? address}) {
    return ArchbasePlace(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracy: p.accuracy,
      timestamp: p.timestamp,
      address: address,
    );
  }
}

/// Serviço de geolocalização. Encapsula:
/// - permissões
/// - posição atual (single-shot)
/// - stream contínuo
/// - geocoding reverso
/// - distância entre pontos
class ArchbaseGeolocationService extends ArchbaseService {
  ArchbaseGeolocationService({
    this.desiredAccuracy = LocationAccuracy.high,
    this.distanceFilterMeters = 10,
  });

  final LocationAccuracy desiredAccuracy;
  final int distanceFilterMeters;

  StreamSubscription<Position>? _stream;

  final ValueNotifier<ArchbasePlace?> currentPlace =
      ValueNotifier<ArchbasePlace?>(null);
  final ValueNotifier<bool> hasPermission = ValueNotifier<bool>(false);
  final ValueNotifier<bool> serviceEnabled = ValueNotifier<bool>(false);

  @override
  Future<void> onInit() async {
    serviceEnabled.value = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    hasPermission.value = perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<bool> ensurePermission() async {
    serviceEnabled.value = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled.value) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    final ok = perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
    hasPermission.value = ok;
    return ok;
  }

  Future<ArchbasePlace?> getCurrentPlace({
    bool resolveAddress = false,
  }) async {
    if (!await ensurePermission()) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: desiredAccuracy),
    );
    String? address;
    if (resolveAddress) {
      address = await reverseGeocode(pos.latitude, pos.longitude);
    }
    final place = ArchbasePlace.fromPosition(pos, address: address);
    currentPlace.value = place;
    return place;
  }

  Future<void> startListening({
    void Function(ArchbasePlace place)? onUpdate,
    bool resolveAddress = false,
  }) async {
    if (!await ensurePermission()) return;
    await _stream?.cancel();
    _stream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: desiredAccuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).listen((pos) async {
      String? address;
      if (resolveAddress) {
        address = await reverseGeocode(pos.latitude, pos.longitude);
      }
      final place = ArchbasePlace.fromPosition(pos, address: address);
      currentPlace.value = place;
      onUpdate?.call(place);
    });
  }

  Future<void> stopListening() async {
    await _stream?.cancel();
    _stream = null;
  }

  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final results = await gc.placemarkFromCoordinates(latitude, longitude);
      if (results.isEmpty) return null;
      final p = results.first;
      final parts = <String>[
        if ((p.thoroughfare ?? '').isNotEmpty) p.thoroughfare!,
        if ((p.subThoroughfare ?? '').isNotEmpty) p.subThoroughfare!,
        if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
        if ((p.locality ?? '').isNotEmpty) p.locality!,
        if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
      ];
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Distância em metros entre dois pontos (Haversine via Geolocator).
  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Helper de geofence simples — útil para auto check-in.
  bool isInsideRadius({
    required double centerLat,
    required double centerLng,
    required double pointLat,
    required double pointLng,
    required double radiusMeters,
  }) {
    return distanceBetween(
          startLat: centerLat,
          startLng: centerLng,
          endLat: pointLat,
          endLng: pointLng,
        ) <=
        radiusMeters;
  }

  @override
  Future<void> onDispose() async {
    await _stream?.cancel();
    currentPlace.dispose();
    hasPermission.dispose();
    serviceEnabled.dispose();
  }
}
