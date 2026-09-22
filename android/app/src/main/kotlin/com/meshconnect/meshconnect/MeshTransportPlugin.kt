package com.meshconnect.meshconnect

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MeshTransportPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null

    private var bleTransport: BleTransport? = null
    private var wifiTransport: WifiPeerTransport? = null
    private var permissionManager: PermissionManager? = null
    private var batteryManager: BatteryManager? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.meshconnect/transport")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.meshconnect/events")
        eventChannel.setStreamHandler(this)

        val ctx = flutterPluginBinding.applicationContext
        permissionManager = PermissionManager(ctx)
        batteryManager = BatteryManager(ctx)
        wifiTransport = WifiPeerTransport(ctx)

        bleTransport = BleTransport(
            context = ctx,
            onPeerDiscovered = { peerData ->
                eventSink?.success(mapOf("type" to "peerDiscovered", "data" to peerData))
            },
            onPayloadReceived = { peerId, bytes ->
                eventSink?.success(mapOf(
                    "type" to "payloadReceived",
                    "data" to mapOf("peerId" to peerId, "payload" to bytes)
                ))
            },
            onConnectionChanged = { peerId, connected ->
                eventSink?.success(mapOf(
                    "type" to if (connected) "peerConnected" else "peerDisconnected",
                    "data" to mapOf("peerId" to peerId)
                ))
            }
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val peerId = call.argument<String>("peerId") ?: "unknown"
                bleTransport?.initialize(peerId)
                result.success(true)
            }
            "startDiscovery" -> {
                val success = bleTransport?.startDiscovery() ?: false
                result.success(success)
            }
            "stopDiscovery" -> {
                bleTransport?.stopDiscovery()
                result.success(true)
            }
            "send" -> {
                val peerId = call.argument<String>("peerId") ?: ""
                val payload = call.argument<ByteArray>("payload") ?: ByteArray(0)
                val success = bleTransport?.sendPayload(peerId, payload) ?: false
                result.success(success)
            }
            "broadcast" -> {
                val payload = call.argument<ByteArray>("payload") ?: ByteArray(0)
                val success = bleTransport?.broadcastPayload(payload) ?: false
                result.success(success)
            }
            "getCapabilities" -> {
                val bleCaps = bleTransport?.getCapabilities() ?: emptyMap<String, Any>()
                val wifiCaps = wifiTransport?.getCapabilities() ?: emptyMap<String, Any>()
                val perms = permissionManager?.getPermissionStatus() ?: emptyMap<String, Boolean>()
                val battery = batteryManager?.getBatteryInfo() ?: emptyMap<String, Any>()

                val combined = HashMap<String, Any>()
                combined.putAll(bleCaps)
                combined.putAll(wifiCaps)
                combined.putAll(perms)
                combined.putAll(battery)
                combined["platform"] = "android"

                result.success(combined)
            }
            "getBatteryInfo" -> {
                val info: Map<String, Any> = batteryManager?.getBatteryInfo() ?: emptyMap<String, Any>()
                result.success(info)
            }
            "getPermissions" -> {
                val perms: Map<String, Boolean> = permissionManager?.getPermissionStatus() ?: emptyMap<String, Boolean>()
                result.success(perms)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        bleTransport?.shutdown()
        bleTransport = null
        context = null
    }
}
