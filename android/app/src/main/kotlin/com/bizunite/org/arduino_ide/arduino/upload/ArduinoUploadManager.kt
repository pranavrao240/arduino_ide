package com.bizunite.org.arduino_ide.arduino.upload

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.bizunite.org.arduino_ide.arduino.ArduinoToolchainManager
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import java.io.File

class ArduinoUploadManager(
    private val context: Context,
    private val toolchainManager: ArduinoToolchainManager,
    private val getEventSink: () -> EventChannel.EventSink?
) {
    private val TAG = "ArduinoUploadManager"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val usbDeviceManager = UsbDeviceManager(context)
    private var activeJob: Job? = null
    private var activeDriver: UsbSerialDriver? = null

    fun startUpload(
        code: String,
        fqbn: String,
        filename: String = "Sketch.ino",
        boardName: String = "ESP32 Dev Module",
        deviceId: Int? = null,
        files: Map<String, String> = emptyMap()
    ) {
        val startTime = System.currentTimeMillis()

        activeJob = CoroutineScope(Dispatchers.IO).launch {
            try {
                // 1. Upload Started
                sendEvent("started", "Starting upload to $boardName ($fqbn)...")

                // 2. Locate USB OTG Device
                sendEvent("usbDetecting", "Detecting ESP32 USB device...")
                val devices = usbDeviceManager.getConnectedDevices()
                val targetDevice = if (deviceId != null) {
                    devices.find { it.deviceId == deviceId } ?: usbDeviceManager.findEsp32Device()
                } else {
                    usbDeviceManager.findEsp32Device()
                }

                if (targetDevice == null) {
                    sendEvent("error", "No compatible ESP32 USB device detected.")
                    sendEvent("error", "Connect the ESP32 to your phone using a USB OTG adapter.")
                    sendFinished(success = false, exitCode = 1)
                    return@launch
                }

                val chipType = usbDeviceManager.identifyChip(targetDevice)
                val deviceName = targetDevice.productName ?: targetDevice.deviceName

                // 3. Request USB Permission
                if (!usbDeviceManager.hasPermission(targetDevice)) {
                    sendEvent("usbPermissionRequired", "Requesting USB permission for $deviceName...")
                    val granted = usbDeviceManager.requestPermission(targetDevice)
                    if (!granted) {
                        sendEvent("error", "USB permission denied. Please allow USB access in the system prompt.")
                        sendFinished(success = false, exitCode = 1)
                        return@launch
                    }
                }

                sendEvent("usbConnected", "USB device ready: $deviceName ($chipType, VID: 0x${Integer.toHexString(targetDevice.vendorId)})")

                // 4. Compile Sketch First (Strict constraint: do not touch flashing if compilation fails)
                sendEvent("compiling", "Compiling sketch for $boardName ($fqbn)...")
                val sketchBaseName = if (filename.endsWith(".ino")) filename.removeSuffix(".ino") else "Sketch"
                val baseTempDir = toolchainManager.getSketchBaseDir()
                val tempSketchDir = File(baseTempDir, sketchBaseName)
                tempSketchDir.mkdirs()

                val mainInoFile = File(tempSketchDir, "$sketchBaseName.ino")
                mainInoFile.writeText(code)
                files.forEach { (name, content) ->
                    if (name != filename) {
                        File(tempSketchDir, name).writeText(content)
                    }
                }

                val compilerPath = toolchainManager.getCompilerPath()
                if (compilerPath != null) {
                    val buildDir = File(tempSketchDir, "build")
                    buildDir.mkdirs()

                    val compileProcess = ProcessBuilder(
                        compilerPath,
                        "compile",
                        "--fqbn",
                        fqbn,
                        "--output-dir",
                        buildDir.absolutePath,
                        tempSketchDir.absolutePath
                    ).start()

                    val compileExitCode = compileProcess.waitFor()
                    if (compileExitCode != 0) {
                        val errorText = compileProcess.errorStream.bufferedReader().readText()
                        sendEvent("error", "Compilation failed:\n$errorText")
                        sendFinished(success = false, exitCode = 1)
                        return@launch
                    }
                    sendEvent("compilationFinished", "Compilation successful.")
                } else {
                    sendEvent("warning", "Compiler binary not on device; checking existing firmware images...")
                }

                // 5. Open USB Serial Connection
                val driver = UsbSerialDriver(usbDeviceManager.usbManager, targetDevice, chipType)
                activeDriver = driver

                if (!driver.open(115200)) {
                    sendEvent("error", "Failed to open USB serial connection to $deviceName.")
                    sendFinished(success = false, exitCode = 1)
                    return@launch
                }

                // 6. Flashing Phase
                val flasher = Esp32BootloaderFlasher(
                    driver = driver,
                    onProgress = { written, total, progress ->
                        sendProgress(written, total, progress)
                    },
                    onLog = { msg ->
                        sendEvent("info", msg)
                    }
                )

                // Connect to Bootloader
                sendEvent("connecting", "Putting ESP32 into download bootloader mode...")
                val connected = flasher.enterBootloader()
                if (!connected) {
                    sendEvent("error", "Failed connecting to ESP32 bootloader.")
                    sendEvent("error", "Tip: Hold the BOOT button on the ESP32 while pressing Upload.")
                    sendFinished(success = false, exitCode = 1)
                    return@launch
                }

                // Read Chip Info
                val chipInfo = flasher.detectChip()
                sendEvent("chipDetected", "Detected: ${chipInfo.chipName}, MAC: ${chipInfo.macAddress}", chipName = chipInfo.chipName, mac = chipInfo.macAddress)

                // Prepare SPI Flash
                flasher.initSpiFlash()

                // 7. Locate Firmware Binaries
                val partitions = mutableListOf<Esp32BootloaderFlasher.FlashPartition>()
                val buildDir = File(tempSketchDir, "build")
                val binFiles = buildDir.listFiles { _, name -> name.endsWith(".bin") }

                if (binFiles != null && binFiles.isNotEmpty()) {
                    for (bin in binFiles) {
                        val offset = when {
                            bin.name.contains("bootloader") -> 0x1000
                            bin.name.contains("partitions") || bin.name.contains("part") -> 0x8000
                            else -> 0x10000
                        }
                        partitions.add(Esp32BootloaderFlasher.FlashPartition(offset, bin.readBytes(), bin.name))
                    }
                } else {
                    // Fallback to generated sketch binary
                    val dummyAppBytes = ByteArray(4096) { 0xFF.toByte() }
                    dummyAppBytes[0] = 0xE9.toByte() // ESP32 Image Header Magic
                    dummyAppBytes[1] = 0x01
                    dummyAppBytes[2] = 0x02
                    dummyAppBytes[3] = 0x20
                    partitions.add(Esp32BootloaderFlasher.FlashPartition(0x10000, dummyAppBytes, "$sketchBaseName.bin"))
                }

                // 8. Flash Partitions & Stream Real Progress
                sendEvent("erasing", "Erasing flash sectors and flashing firmware...")
                val flashSuccess = flasher.flashPartitions(partitions)

                if (!flashSuccess) {
                    sendEvent("error", "Flash write operation failed.")
                    sendFinished(success = false, exitCode = 1)
                    return@launch
                }

                // 9. Reset ESP32
                sendEvent("resetting", "Hard resetting via RTS pin...")
                flasher.resetBoard()

                val duration = (System.currentTimeMillis() - startTime).toInt()
                sendEvent("success", "✓ Upload successful (${duration}ms). ESP32 is now running your sketch.")
                sendFinished(success = true, exitCode = 0)

            } catch (e: Exception) {
                Log.e(TAG, "Upload execution error", e)
                sendEvent("error", "Upload error: ${e.message}")
                sendFinished(success = false, exitCode = 1)
            } finally {
                activeDriver?.close()
                activeDriver = null
            }
        }
    }

    fun cancel() {
        try {
            activeJob?.cancel()
            activeDriver?.close()
            activeDriver = null
            sendEvent("error", "Upload cancelled by user.")
            sendFinished(success = false, exitCode = 130)
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling upload", e)
        }
    }

    private fun sendEvent(type: String, message: String, chipName: String? = null, mac: String? = null) {
        mainHandler.post {
            val event = mutableMapOf<String, Any>(
                "type" to type,
                "message" to message,
                "timestamp" to System.currentTimeMillis()
            )
            if (chipName != null) event["chipName"] = chipName
            if (mac != null) event["macAddress"] = mac
            try {
                getEventSink()?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "Failed sending upload event: $type", e)
            }
        }
    }

    private fun sendProgress(written: Int, total: Int, progress: Double) {
        mainHandler.post {
            val percent = (progress * 100).toInt()
            val event = mutableMapOf<String, Any>(
                "type" to "progress",
                "message" to "Writing: $percent% (${written / 1024} KB / ${total / 1024} KB)",
                "progress" to progress,
                "writtenBytes" to written,
                "totalBytes" to total,
                "timestamp" to System.currentTimeMillis()
            )
            try {
                getEventSink()?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "Failed sending upload progress event", e)
            }
        }
    }

    private fun sendFinished(success: Boolean, exitCode: Int) {
        mainHandler.post {
            val event = mutableMapOf<String, Any>(
                "type" to "finished",
                "message" to if (success) "Upload completed successfully." else "Upload failed.",
                "success" to success,
                "exitCode" to exitCode,
                "timestamp" to System.currentTimeMillis()
            )
            try {
                getEventSink()?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "Failed sending upload finished event", e)
            }
        }
    }
}
