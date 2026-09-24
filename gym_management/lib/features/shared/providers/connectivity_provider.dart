import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/core/services/api_service.dart';

enum ConnectionStatus { online, offline, serverDown }

class ConnectionNotifier extends Notifier<ConnectionStatus> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription? _apiErrorSubscription;
  Timer? _timer;

  @override
  ConnectionStatus build() {
    _init();
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _apiErrorSubscription?.cancel();
      _timer?.cancel();
    });
    return ConnectionStatus.online;
  }

  void _init() {
    // 1. Listen to physical network connectivity status changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _checkStatus(results);
    });

    // 2. Listen to API Service errors stream to trigger "serverDown" immediately when requests fail
    _apiErrorSubscription = ApiService.errorStream.listen((_) {
      setServerUnreachable();
    });

    // 3. Set up a periodic check to auto-recover when backend is back online
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (state != ConnectionStatus.online) {
        checkServerRealtime();
      }
    });

    // Perform an initial check
    checkServerRealtime();
  }

  Future<void> _checkStatus(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = ConnectionStatus.offline;
    } else {
      await checkServerRealtime();
    }
  }

  Future<void> checkServerRealtime() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = ConnectionStatus.offline;
      return;
    }

    final isReachable = await ApiService.pingServer();
    if (isReachable) {
      state = ConnectionStatus.online;
    } else {
      state = ConnectionStatus.serverDown;
    }
  }

  void setServerUnreachable() {
    if (state == ConnectionStatus.online) {
      state = ConnectionStatus.serverDown;
    }
  }
}

final connectionStatusProvider = NotifierProvider<ConnectionNotifier, ConnectionStatus>(() {
  return ConnectionNotifier();
});
