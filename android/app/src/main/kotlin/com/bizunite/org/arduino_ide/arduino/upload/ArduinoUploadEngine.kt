package com.bizunite.org.arduino_ide.arduino.upload

import android.content.Context
import android.util.Log
import com.bizunite.org.arduino_ide.arduino.ArduinoToolchainManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ArduinoUploadEngine(private val context: Context) {
    private val TAG = "ArduinoUploadEngine"
    private val METHOD_CHANNEL = "arduino/upload"
    private val EVENT_CHANNEL = "arduino/upload/events"

    private val toolchainManager = ArduinoToolchainManager(context)
    private val usbDeviceManager = UsbDeviceManager(context)
    private var eventSink: EventChannel.EventSink? = null
    private var currentUploadManager: ArduinoUploadManager? = null

    fun register(flutterEngine: FlutterEngine) {
        // 1. Register EventChannel for live upload event streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "Upload EventChannel stream listener attached")
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "Upload EventChannel stream listener cancelled")
                    eventSink = null
                }
            })

        // 2. Register MethodChannel for upload and USB commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getUsbDevices" -> {
                        try {
                            val devices = usbDeviceManager.getConnectedDevices()
                            val deviceList = devices.map { dev ->
                                mapOf(
                                    "name" to dev.deviceName,
                                    "deviceName" to dev.deviceName,
                                    "productName" to (dev.productName ?: dev.deviceName),
                                    "manufacturerName" to (dev.manufacturerName ?: ""),
                                    "vendorId" to dev.vendorId,
                                    "productId" to dev.productId,
                                    "deviceId" to dev.deviceId,
                                    "chipType" to usbDeviceManager.identifyChip(dev).name,
                                    "hasPermission" to usbDeviceManager.hasPermission(dev)
                                )
                            }
                            result.success(deviceList)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error querying USB devices", e)
                            result.error("USB_ERROR", e.message, null)
                        }
                    }

                    "requestUsbPermission" -> {
                        val deviceId = call.argument<Int>("deviceId")
                        val devices = usbDeviceManager.getConnectedDevices()
                        val target = if (deviceId != null) devices.find { it.deviceId == deviceId } else usbDeviceManager.findEsp32Device()

                        if (target == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.Main).launch {
                            val granted = usbDeviceManager.requestPermission(target)
                            result.success(granted)
                        }
                    }

                    "upload" -> {
                        try {
                            val code = call.argument<String>("code") ?: ""
                            val fqbn = call.argument<String>("fqbn") ?: "esp32:esp32:esp32"
                            val filename = call.argument<String>("filename") ?: "Sketch.ino"
                            val board = call.argument<String>("board") ?: "ESP32 Dev Module"
                            val deviceId = call.argument<Int>("deviceId")
                            val files = call.argument<Map<String, String>>("files") ?: emptyMap()

                            val manager = ArduinoUploadManager(context, toolchainManager) { eventSink }
                            currentUploadManager = manager
                            manager.startUpload(
                                code = code,
                                fqbn = fqbn,
                                filename = filename,
                                boardName = board,
                                deviceId = deviceId,
                                files = files
                            )
                            result.success(mapOf("status" to "upload_started"))
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed starting upload", e)
                            result.error("UPLOAD_ERROR", e.message, null)
                        }
                    }

                    "cancelUpload" -> {
                        currentUploadManager?.cancel()
                        currentUploadManager = null
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
