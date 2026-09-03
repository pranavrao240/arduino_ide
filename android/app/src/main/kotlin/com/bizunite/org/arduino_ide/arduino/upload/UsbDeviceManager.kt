package com.bizunite.org.arduino_ide.arduino.upload

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine

enum class UsbSerialChip {
    CP210X,
    CH340,
    FTDI,
    CDC_ACM,
    UNKNOWN
}

class UsbDeviceManager(private val context: Context) {
    private val TAG = "UsbDeviceManager"
    private val ACTION_USB_PERMISSION = "com.bizunite.org.arduino_ide.USB_PERMISSION"

    val usbManager: UsbManager
        get() = context.getSystemService(Context.USB_SERVICE) as UsbManager

    fun getConnectedDevices(): List<UsbDevice> {
        val deviceList = usbManager.deviceList ?: return emptyList()
        return deviceList.values.toList()
    }

    fun findEsp32Device(): UsbDevice? {
        val devices = getConnectedDevices()
        if (devices.isEmpty()) return null

        // Priority 1: Match known ESP32 USB-UART Chips (CP210x, CH340, FTDI, Espressif)
        for (device in devices) {
            val chip = identifyChip(device)
            if (chip != UsbSerialChip.UNKNOWN) {
                return device
            }
        }

        // Priority 2: Fallback to first USB device
        return devices.firstOrNull()
    }

    fun identifyChip(device: UsbDevice): UsbSerialChip {
        val vid = device.vendorId
        val pid = device.productId

        return when {
            // CP210x (Silicon Labs: CP2102, CP2104, CP2105, etc.)
            vid == 0x10C4 -> UsbSerialChip.CP210X

            // CH340 / CH341 (WCH)
            vid == 0x1A86 -> UsbSerialChip.CH340

            // FTDI (FT232R, FT2232, etc.)
            vid == 0x0403 -> UsbSerialChip.FTDI

            // Espressif Native USB CDC / CDC-ACM / Arduino
            vid == 0x303A || vid == 0x2341 || vid == 0x2E8A || isCdcAcmDevice(device) -> UsbSerialChip.CDC_ACM

            else -> UsbSerialChip.UNKNOWN
        }
    }

    private fun isCdcAcmDevice(device: UsbDevice): Boolean {
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            // USB CDC Communication Interface (0x02) or Data Interface (0x0A)
            if (intf.interfaceClass == 0x02 || intf.interfaceClass == 0x0A) {
                return true
            }
        }
        return false
    }

    fun hasPermission(device: UsbDevice): Boolean {
        return usbManager.hasPermission(device)
    }

    suspend fun requestPermission(device: UsbDevice): Boolean = suspendCancellableCoroutine { continuation ->
        if (hasPermission(device)) {
            continuation.resume(true)
            return@suspendCancellableCoroutine
        }

        val permissionReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (ACTION_USB_PERMISSION == intent.action) {
                    synchronized(this) {
                        try {
                            context.unregisterReceiver(this)
                        } catch (_: Exception) {}

                        val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                        Log.d(TAG, "USB Permission result for device ${device.deviceName}: $granted")
                        if (continuation.isActive) {
                            continuation.resume(granted)
                        }
                    }
                }
            }
        }

        val filter = IntentFilter(ACTION_USB_PERMISSION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(permissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(permissionReceiver, filter)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val intent = Intent(ACTION_USB_PERMISSION)
        intent.setPackage(context.packageName)
        val permissionIntent = PendingIntent.getBroadcast(context, 0, intent, flags)

        Log.d(TAG, "Requesting USB permission for ${device.deviceName} (VID: ${device.vendorId}, PID: ${device.productId})")
        usbManager.requestPermission(device, permissionIntent)

        continuation.invokeOnCancellation {
            try {
                context.unregisterReceiver(permissionReceiver)
            } catch (_: Exception) {}
        }
    }
}
