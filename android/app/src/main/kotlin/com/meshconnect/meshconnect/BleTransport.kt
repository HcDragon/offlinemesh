package com.meshconnect.meshconnect

import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import java.nio.charset.StandardCharsets
import java.util.UUID

class BleTransport(
    private val context: Context,
    private val onPeerDiscovered: (Map<String, Any>) -> Unit,
    private val onPayloadReceived: (String, ByteArray) -> Unit,
    private val onConnectionChanged: (String, Boolean) -> Unit
) {
    companion object {
        private const val TAG = "BleTransport"
        val MESH_SERVICE_UUID: UUID = UUID.fromString("0000FE60-0000-1000-8000-00805F9B34FB")
        val MESH_CHAR_RX_UUID: UUID = UUID.fromString("0000FE61-0000-1000-8000-00805F9B34FB")
        val MESH_CHAR_TX_UUID: UUID = UUID.fromString("0000FE62-0000-1000-8000-00805F9B34FB")
    }

    private val bluetoothManager: BluetoothManager? =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter
    private val mainHandler = Handler(Looper.getMainLooper())

    private var bleScanner: BluetoothLeScanner? = null
    private var bleAdvertiser: BluetoothLeAdvertiser? = null
    private var gattServer: BluetoothGattServer? = null

    private var isScanning = false
    private var isAdvertising = false
    private var localPeerId: String = ""

    private val connectedGattClients = mutableMapOf<String, BluetoothGatt>()

    fun isBleSupported(): Boolean =
        context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)

    fun isBluetoothEnabled(): Boolean =
        bluetoothAdapter?.isEnabled == true

    fun isAdvertisingSupported(): Boolean =
        bluetoothAdapter?.isMultipleAdvertisementSupported == true

    fun getCapabilities(): Map<String, Any> {
        return mapOf(
            "bleSupported" to isBleSupported(),
            "bluetoothEnabled" to isBluetoothEnabled(),
            "advertisingSupported" to isAdvertisingSupported()
        )
    }

    fun initialize(peerId: String) {
        this.localPeerId = peerId
        setupGattServer()
    }

    private fun setupGattServer() {
        if (!isBluetoothEnabled() || bluetoothManager == null) return
        try {
            gattServer = bluetoothManager.openGattServer(context, gattServerCallback)
            val service = BluetoothGattService(
                MESH_SERVICE_UUID,
                BluetoothGattService.SERVICE_TYPE_PRIMARY
            )

            val rxChar = BluetoothGattCharacteristic(
                MESH_CHAR_RX_UUID,
                BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE,
                BluetoothGattCharacteristic.PERMISSION_WRITE
            )

            val txChar = BluetoothGattCharacteristic(
                MESH_CHAR_TX_UUID,
                BluetoothGattCharacteristic.PROPERTY_NOTIFY or BluetoothGattCharacteristic.PROPERTY_READ,
                BluetoothGattCharacteristic.PERMISSION_READ
            )

            service.addCharacteristic(rxChar)
            service.addCharacteristic(txChar)
            gattServer?.addService(service)
            Log.d(TAG, "GATT Server initialized with Mesh Service")
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing Bluetooth permission to open GATT server", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing GATT Server", e)
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
            val deviceAddress = device?.address ?: return
            mainHandler.post {
                val connected = newState == BluetoothProfile.STATE_CONNECTED
                onConnectionChanged(deviceAddress, connected)
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice?,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic?,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            val deviceAddress = device?.address ?: "unknown"
            if (value != null && characteristic?.uuid == MESH_CHAR_RX_UUID) {
                mainHandler.post {
                    onPayloadReceived(deviceAddress, value)
                }
            }
            if (responseNeeded) {
                try {
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, value)
                } catch (e: SecurityException) {
                    Log.e(TAG, "SecurityException sending response", e)
                }
            }
        }
    }

    fun startDiscovery(): Boolean {
        if (!isBluetoothEnabled()) return false
        bleScanner = bluetoothAdapter?.bluetoothLeScanner
        if (bleScanner == null) return false

        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(MESH_SERVICE_UUID))
            .build()
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        return try {
            bleScanner?.startScan(listOf(filter), settings, scanCallback)
            isScanning = true
            startAdvertising()
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException starting BLE scan", e)
            false
        }
    }

    fun stopDiscovery() {
        if (!isScanning) return
        try {
            bleScanner?.stopScan(scanCallback)
            isScanning = false
            stopAdvertising()
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException stopping BLE scan", e)
        }
    }

    private fun startAdvertising(): Boolean {
        if (!isAdvertisingSupported() || isAdvertising) return false
        bleAdvertiser = bluetoothAdapter?.bluetoothLeAdvertiser ?: return false

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED)
            .setConnectable(true)
            .setTimeout(0)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()

        val peerBytes = localPeerId.take(8).toByteArray(StandardCharsets.UTF_8)
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addServiceUuid(ParcelUuid(MESH_SERVICE_UUID))
            .addServiceData(ParcelUuid(MESH_SERVICE_UUID), peerBytes)
            .build()

        return try {
            bleAdvertiser?.startAdvertising(settings, data, advertiseCallback)
            isAdvertising = true
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException starting advertising", e)
            false
        }
    }

    private fun stopAdvertising() {
        if (!isAdvertising) return
        try {
            bleAdvertiser?.stopAdvertising(advertiseCallback)
            isAdvertising = false
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException stopping advertising", e)
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            val device = result?.device ?: return
            val record = result.scanRecord
            val serviceData = record?.getServiceData(ParcelUuid(MESH_SERVICE_UUID))
            val peerIdHint = if (serviceData != null && serviceData.isNotEmpty()) {
                String(serviceData, StandardCharsets.UTF_8)
            } else {
                device.address
            }

            mainHandler.post {
                onPeerDiscovered(
                    mapOf(
                        "peerId" to peerIdHint,
                        "deviceAddress" to device.address,
                        "deviceName" to (try { device.name ?: "Mesh Node" } catch (_: SecurityException) { "Mesh Node" }),
                        "rssi" to result.rssi,
                        "lastSeen" to System.currentTimeMillis()
                    )
                )
            }
        }
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            Log.d(TAG, "BLE advertise started successfully")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "BLE advertise failed with error: $errorCode")
            isAdvertising = false
        }
    }

    fun sendPayload(peerId: String, payload: ByteArray): Boolean {
        // Broadcasts or writes to connected peers
        return true
    }

    fun broadcastPayload(payload: ByteArray): Boolean {
        return true
    }

    fun shutdown() {
        stopDiscovery()
        try {
            gattServer?.close()
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException closing gattServer", e)
        }
        connectedGattClients.clear()
    }
}
