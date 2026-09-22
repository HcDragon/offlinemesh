import 'dart:async';
import 'package:flutter/foundation.dart';
import 'demo_mesh_transport.dart';
import 'mesh_transport.dart';
import 'native_mesh_transport.dart';

class TransportManager extends ChangeNotifier {
  static final TransportManager _instance = TransportManager._internal();
  factory TransportManager() => _instance;
  TransportManager._internal();

  MeshTransport? _activeTransport;
  bool _useDemoMode = false;
  String _localPeerId = 'node-init';

  bool get isDemoMode => _useDemoMode;
  MeshTransport get activeTransport => _activeTransport ?? NativeMeshTransport();
  DemoMeshTransport? get demoTransport => _activeTransport is DemoMeshTransport ? _activeTransport as DemoMeshTransport : null;

  Future<void> initialize(String localPeerId, {bool startInDemoMode = false}) async {
    _localPeerId = localPeerId;
    _useDemoMode = startInDemoMode;
    await _setupTransport();
  }

  Future<void> setDemoMode(bool enableDemo) async {
    if (_useDemoMode == enableDemo) return;
    _useDemoMode = enableDemo;
    _activeTransport?.dispose();
    await _setupTransport();
    notifyListeners();
  }

  Future<void> _setupTransport() async {
    if (_useDemoMode) {
      _activeTransport = DemoMeshTransport();
    } else {
      _activeTransport = NativeMeshTransport();
    }
    await _activeTransport!.initialize(_localPeerId);
  }
}
