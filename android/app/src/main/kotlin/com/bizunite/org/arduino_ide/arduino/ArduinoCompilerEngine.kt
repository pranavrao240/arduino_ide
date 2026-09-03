package com.bizunite.org.arduino_ide.arduino

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class ArduinoCompilerEngine(private val context: Context) {
    private val TAG = "ArduinoCompilerEngine"
    private val METHOD_CHANNEL = "arduino/compiler"
    private val EVENT_CHANNEL = "arduino/compiler/events"

    private val toolchainManager = ArduinoToolchainManager(context)
    private var eventSink: EventChannel.EventSink? = null
    private var currentProcess: CompilationProcess? = null

    fun register(flutterEngine: FlutterEngine) {
        // 1. Register EventChannel for live event streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "EventChannel stream listener attached")
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "EventChannel stream listener cancelled")
                    eventSink = null
                }
            })

        // 2. Register MethodChannel for commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkToolchain" -> {
                        val isInstalled = toolchainManager.isInstalled()
                        result.success(isInstalled)
                    }

                    "getCompilerPath" -> {
                        val path = toolchainManager.getCompilerPath()
                        result.success(path)
                    }

                    "getToolchainVersion" -> {
                        val version = toolchainManager.getToolchainVersion()
                        result.success(version)
                    }

                    "compile" -> {
                        try {
                            val code = call.argument<String>("code") ?: ""
                            val fqbn = call.argument<String>("fqbn") ?: "esp32:esp32:esp32"
                            val filename = call.argument<String>("filename") ?: "Sketch.ino"
                            val board = call.argument<String>("board") ?: "ESP32 Dev Module"
                            val files = call.argument<Map<String, String>>("files") ?: emptyMap()

                            val process = CompilationProcess(toolchainManager) { eventSink }
                            currentProcess = process
                            process.startCompilation(
                                code = code,
                                fqbn = fqbn,
                                filename = filename,
                                boardName = board,
                                files = files
                            )
                            result.success(mapOf("status" to "compilation_started"))
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to start compilation", e)
                            result.error("COMPILATION_ERROR", e.message, null)
                        }
                    }

                    "cancelCompilation" -> {
                        currentProcess?.cancel()
                        currentProcess = null
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
