package com.bizunite.org.arduino_ide

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import com.bizunite.org.arduino_ide.arduino.ArduinoCompilerEngine
import com.bizunite.org.arduino_ide.arduino.upload.ArduinoUploadEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val USB_CHANNEL = "com.bizunite.org.arduino_ide/usb_serial"
    private lateinit var compilerEngine: ArduinoCompilerEngine
    private lateinit var uploadEngine: ArduinoUploadEngine

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. USB Serial Detection Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USB_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getConnectedDevices" -> {
                    try {
                        val usbManager = getSystemService(Context.USB_SERVICE) as? UsbManager
                        val deviceList: HashMap<String, UsbDevice>? = usbManager?.deviceList
                        val devices = mutableListOf<Map<String, Any?>>()

                        deviceList?.values?.forEach { device ->
                            devices.add(
                                mapOf(
                                    "deviceName" to device.deviceName,
                                    "productName" to (device.productName ?: ""),
                                    "manufacturerName" to (device.manufacturerName ?: ""),
                                    "vendorId" to device.vendorId,
                                    "productId" to device.productId,
                                    "deviceId" to device.deviceId
                                )
                            )
                        }
                        result.success(devices)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Arduino & ESP32 Native Asynchronous Compilation Engine
        compilerEngine = ArduinoCompilerEngine(applicationContext)
        compilerEngine.register(flutterEngine)

        // 3. Arduino & ESP32 Native USB OTG Upload and Flashing Engine
        uploadEngine = ArduinoUploadEngine(applicationContext)
        uploadEngine.register(flutterEngine)
    }
}
