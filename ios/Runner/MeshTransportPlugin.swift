import Flutter
import UIKit

public class MeshTransportPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var multipeerTransport: MultipeerTransport?
    private var bluetoothTransport: BluetoothTransport?
    private var permissionManager: PermissionManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "com.meshconnect/transport", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.meshconnect/events", binaryMessenger: registrar.messenger())
        
        let instance = MeshTransportPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
        
        instance.setupTransports()
    }
    
    private func setupTransports() {
        permissionManager = PermissionManager()
        bluetoothTransport = BluetoothTransport()
        
        multipeerTransport = MultipeerTransport(
            onPeerDiscovered: { [weak self] peerData in
                self?.eventSink?(["type": "peerDiscovered", "data": peerData])
            },
            onPayloadReceived: { [weak self] peerId, data in
                self?.eventSink?([
                    "type": "payloadReceived",
                    "data": ["peerId": peerId, "payload": FlutterStandardTypedData(bytes: data)]
                ])
            },
            onConnectionChanged: { [weak self] peerId, connected in
                self?.eventSink?([
                    "type": connected ? "peerConnected" : "peerDisconnected",
                    "data": ["peerId": peerId]
                ])
            }
        )
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            let args = call.arguments as? [String: Any]
            let peerId = args?["peerId"] as? String ?? "ios-node"
            multipeerTransport?.initialize(peerIdString: peerId)
            result(true)
            
        case "startDiscovery":
            let success = multipeerTransport?.startDiscovery() ?? false
            result(success)
            
        case "stopDiscovery":
            multipeerTransport?.stopDiscovery()
            result(true)
            
        case "send":
            guard let args = call.arguments as? [String: Any],
                  let peerId = args["peerId"] as? String,
                  let typedData = args["payload"] as? FlutterStandardTypedData else {
                result(false)
                return
            }
            let success = multipeerTransport?.send(peerId: peerId, payload: typedData.data) ?? false
            result(success)
            
        case "broadcast":
            guard let args = call.arguments as? [String: Any],
                  let typedData = args["payload"] as? FlutterStandardTypedData else {
                result(false)
                return
            }
            let success = multipeerTransport?.broadcast(payload: typedData.data) ?? false
            result(success)
            
        case "getCapabilities":
            var caps = bluetoothTransport?.getCapabilities() ?? [:]
            caps["multipeerSupported"] = true
            caps["platform"] = "ios"
            if let perms = permissionManager?.getPermissionStatus() {
                for (k, v) in perms {
                    caps[k] = v
                }
            }
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = Int(UIDevice.current.batteryLevel * 100)
            caps["batteryLevel"] = level >= 0 ? level : 100
            caps["powerSaveMode"] = ProcessInfo.processInfo.isLowPowerModeEnabled
            result(caps)
            
        case "getBatteryInfo":
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = Int(UIDevice.current.batteryLevel * 100)
            result([
                "batteryLevel": level >= 0 ? level : 100,
                "powerSaveMode": ProcessInfo.processInfo.isLowPowerModeEnabled
            ])
            
        case "getPermissions":
            result(permissionManager?.getPermissionStatus() ?? [:])
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
