import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../core/state/archbase_service.dart';

enum ArchbaseConnectionType { none, wifi, mobile, ethernet, vpn, bluetooth, other }

extension on ConnectivityResult {
  ArchbaseConnectionType toArchbase() {
    switch (this) {
      case ConnectivityResult.wifi:
        return ArchbaseConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ArchbaseConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return ArchbaseConnectionType.ethernet;
      case ConnectivityResult.vpn:
        return ArchbaseConnectionType.vpn;
      case ConnectivityResult.bluetooth:
        return ArchbaseConnectionType.bluetooth;
      case ConnectivityResult.none:
        return ArchbaseConnectionType.none;
      default:
        return ArchbaseConnectionType.other;
    }
  }
}

/// Monitora o estado da conexão e expõe:
/// - [isConnected] (`ValueNotifier<bool>`)
/// - [connectionType] (`ValueNotifier<ArchbaseConnectionType>`)
/// - [onConnected] e [onDisconnected] (`Stream<void>`)
class ArchbaseConnectivityService extends ArchbaseService {
  ArchbaseConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);
  final ValueNotifier<ArchbaseConnectionType> connectionType =
      ValueNotifier<ArchbaseConnectionType>(ArchbaseConnectionType.wifi);

  final _connectedController = StreamController<void>.broadcast();
  final _disconnectedController = StreamController<void>.broadcast();

  Stream<void> get onConnected => _connectedController.stream;
  Stream<void> get onDisconnected => _disconnectedController.stream;

  @override
  Future<void> onInit() async {
    final initial = await _connectivity.checkConnectivity();
    _apply(initial);
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final type = _pickPrimary(results);
    final connected = type != ArchbaseConnectionType.none;
    final wasConnected = isConnected.value;

    connectionType.value = type;
    isConnected.value = connected;

    if (connected && !wasConnected) {
      _connectedController.add(null);
    } else if (!connected && wasConnected) {
      _disconnectedController.add(null);
    }
    notifyListeners();
  }

  ArchbaseConnectionType _pickPrimary(List<ConnectivityResult> results) {
    if (results.isEmpty) return ArchbaseConnectionType.none;
    // Preferência: wifi > ethernet > mobile > vpn > bluetooth > other > none
    const order = [
      ConnectivityResult.wifi,
      ConnectivityResult.ethernet,
      ConnectivityResult.mobile,
      ConnectivityResult.vpn,
      ConnectivityResult.bluetooth,
    ];
    for (final type in order) {
      if (results.contains(type)) return type.toArchbase();
    }
    if (results.contains(ConnectivityResult.none)) {
      return ArchbaseConnectionType.none;
    }
    return ArchbaseConnectionType.other;
  }

  @override
  Future<void> onDispose() async {
    await _sub?.cancel();
    await _connectedController.close();
    await _disconnectedController.close();
    isConnected.dispose();
    connectionType.dispose();
  }
}
