import 'package:flutter/foundation.dart';
import '../mesh/mesh_engine.dart';
import '../models/mesh_message.dart';
import '../models/sos_event.dart';

class SosService extends ChangeNotifier {
  final MeshEngine _meshEngine;
  SosEvent? _currentActiveSos;

  SosService(this._meshEngine);

  SosEvent? get currentActiveSos => _currentActiveSos;
  bool get hasActiveEmergency => _currentActiveSos != null && _currentActiveSos!.status != SosStatus.resolved;

  Future<void> loadActiveEmergency() async {
    _currentActiveSos = await _meshEngine.sosRepository.getLatestActiveSos();
    notifyListeners();
  }

  Future<MeshMessage> triggerSos({
    double? latitude,
    double? longitude,
    String emergencyNote = 'EMERGENCY: Immediate assistance required!',
  }) async {
    final msg = await _meshEngine.broadcastSos(
      latitude: latitude,
      longitude: longitude,
      emergencyNote: emergencyNote,
    );

    _currentActiveSos = SosEvent(
      sosId: msg.messageId,
      originPeerId: _meshEngine.localPeerId,
      originDisplayName: _meshEngine.localDisplayName,
      timestamp: DateTime.now(),
      status: SosStatus.active,
      latitude: latitude,
      longitude: longitude,
      emergencyNote: emergencyNote,
      relayHistory: [_meshEngine.localPeerId],
    );

    notifyListeners();
    return msg;
  }

  Future<void> resolveEmergency(String sosId) async {
    if (_currentActiveSos != null && _currentActiveSos!.sosId == sosId) {
      final updated = _currentActiveSos!.copyWith(status: SosStatus.resolved);
      await _meshEngine.sosRepository.upsertSosEvent(updated);
      _currentActiveSos = null;
      notifyListeners();
    }
  }
}
