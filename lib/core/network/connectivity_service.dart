import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../main.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionChangeController = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Stream<bool> get connectionChange => _connectionChangeController.stream;

  bool _hasInitialized = false;

  void initialize() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool isNowOnline = _checkConnectivity(results);
      if (isNowOnline != _isOnline) {
        _isOnline = isNowOnline;
        _connectionChangeController.add(_isOnline);
        if (_hasInitialized) {
          _showNetworkSnackbar();
        }
      }
    });
    checkStatus().then((_) => _hasInitialized = true);
  }

  Future<bool> checkStatus() async {
    final results = await _connectivity.checkConnectivity();
    bool isNowOnline = _checkConnectivity(results);
    if (isNowOnline != _isOnline) {
      _isOnline = isNowOnline;
      _connectionChangeController.add(_isOnline);
      if (_hasInitialized) {
        _showNetworkSnackbar();
      }
    }
    return _isOnline;
  }

  void _showNetworkSnackbar() {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(_isOnline ? 'Đã khôi phục kết nối mạng' : 'Mất kết nối mạng! Ứng dụng đang dùng dữ liệu cũ.'),
          ],
        ),
        backgroundColor: _isOnline ? Colors.green : Colors.red,
        duration: Duration(seconds: _isOnline ? 3 : 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _checkConnectivity(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) return false;
    if (results.contains(ConnectivityResult.mobile) || 
        results.contains(ConnectivityResult.wifi) || 
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn)) {
      return true;
    }
    return false;
  }

  void dispose() {
    _connectionChangeController.close();
  }
}
