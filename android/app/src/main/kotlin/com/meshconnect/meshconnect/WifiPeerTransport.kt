package com.meshconnect.meshconnect

import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.p2p.WifiP2pManager

class WifiPeerTransport(private val context: Context) {

    fun isWifiDirectSupported(): Boolean {
        return context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT)
    }

    fun getCapabilities(): Map<String, Any> {
        return mapOf(
            "wifiDirectSupported" to isWifiDirectSupported()
        )
    }
}
