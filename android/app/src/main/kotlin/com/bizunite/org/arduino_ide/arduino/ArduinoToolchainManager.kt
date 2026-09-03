package com.bizunite.org.arduino_ide.arduino

import android.content.Context
import android.util.Log
import java.io.File

class ArduinoToolchainManager(private val context: Context) {
    private val TAG = "ArduinoToolchainManager"

    private val toolchainDir: File
        get() = File(context.filesDir, "toolchain")

    private val compilerBinaries = listOf(
        "bin/arduino-cli",
        "arduino-cli",
        "bin/xtensa-esp32-elf-gcc",
        "xtensa-esp32-elf-gcc"
    )

    fun isInstalled(): Boolean {
        return getCompilerPath() != null
    }

    fun getCompilerPath(): String? {
        // 1. Check app internal storage toolchain dir
        for (relPath in compilerBinaries) {
            val file = File(toolchainDir, relPath)
            if (file.exists() && (file.canExecute() || file.setExecutable(true))) {
                Log.d(TAG, "Found compiler binary at: ${file.absolutePath}")
                return file.absolutePath
            }
        }

        // 2. Check system PATH
        val systemPath = System.getenv("PATH") ?: ""
        val paths = systemPath.split(":")
        for (p in paths) {
            val f = File(p, "arduino-cli")
            if (f.exists() && f.canExecute()) {
                Log.d(TAG, "Found system arduino-cli at: ${f.absolutePath}")
                return f.absolutePath
            }
        }

        Log.w(TAG, "No Arduino compiler or ESP32 toolchain binary found on device.")
        return null
    }

    fun getToolchainVersion(): String? {
        val path = getCompilerPath() ?: return null
        return try {
            val process = ProcessBuilder(path, "version").start()
            val output = process.inputStream.bufferedReader().readText().trim()
            process.waitFor()
            output
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get toolchain version", e)
            null
        }
    }

    fun getSketchBaseDir(): File {
        val dir = File(context.cacheDir, "projects/temp")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }
}
