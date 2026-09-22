import 'package:flutter/foundation.dart';
import '../mesh/mesh_engine.dart';

class DiscoveryService extends ChangeNotifier {
  final MeshEngine _meshEngine;
  bool _isDiscovering = false;

  DiscoveryService(this._meshEngine);

  bool get isDiscovering => _isDiscovering;

  Future<void> startDiscovery() async {
    _isDiscovering = true;
    await _meshEngine.transportManager.activeTransport.startDiscovery();
    notifyListeners();
  }

  Future<void> stopDiscovery() async {
    _isDiscovering = false;
    await _meshEngine.transportManager.activeTransport.stopDiscovery();
    notifyListeners();
  }
}
