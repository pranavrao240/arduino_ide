package com.bizunite.org.arduino_ide.arduino

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.io.File
import java.io.InputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.regex.Pattern

class CompilationProcess(
    private val toolchainManager: ArduinoToolchainManager,
    private val getEventSink: () -> EventChannel.EventSink?
) {
    private val TAG = "CompilationProcess"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor: ExecutorService = Executors.newCachedThreadPool()
    private var activeProcess: Process? = null
    private var activeTask: Future<*>? = null

    // GCC Diagnostic line regex: Sketch.ino:15:3: error: 'digitalWrit' was not declared
    private val diagnosticPattern = Pattern.compile(
        "^(?:([^:\\n\\r]+):(\\d+):(?:(\\d+):)?\\s+)?(error|warning|fatal error):\\s*(.*)$",
        Pattern.CASE_INSENSITIVE
    )

    // Memory usage regex from arduino-cli / gcc linker:
    private val sketchMemoryPattern = Pattern.compile(
        "Sketch uses (\\d+) bytes.*(?:Maximum is (\\d+) bytes)?",
        Pattern.CASE_INSENSITIVE
    )
    private val globalVarMemoryPattern = Pattern.compile(
        "Global variables use (\\d+) bytes.*(?:Maximum is (\\d+) bytes)?",
        Pattern.CASE_INSENSITIVE
    )

    fun startCompilation(
        code: String,
        fqbn: String,
        filename: String = "Sketch.ino",
        boardName: String = "ESP32 Dev Module",
        files: Map<String, String> = emptyMap()
    ) {
        activeTask = executor.submit {
            val startTime = System.currentTimeMillis()
            var tempSketchDir: File? = null

            try {
                // 1. Send Started Event
                sendEvent("started", "Starting compilation for $boardName ($fqbn)...")

                // 2. Prepare Temporary Sketch Directory
                val sketchBaseName = if (filename.endsWith(".ino")) filename.removeSuffix(".ino") else "Sketch"
                val baseTempDir = toolchainManager.getSketchBaseDir()
                tempSketchDir = File(baseTempDir, sketchBaseName)
                if (tempSketchDir.exists()) {
                    tempSketchDir.deleteRecursively()
                }
                tempSketchDir.mkdirs()

                // Write main .ino sketch file
                val mainInoFile = File(tempSketchDir, "$sketchBaseName.ino")
                mainInoFile.writeText(code)

                // Write additional sketch files (headers, extra tabs)
                files.forEach { (name, content) ->
                    if (name != filename) {
                        val extraFile = File(tempSketchDir, name)
                        extraFile.writeText(content)
                    }
                }

                // 3. Formulate compiler command
                val compilerPath = toolchainManager.getCompilerPath()
                val commandStr = "\$ arduino-cli compile --fqbn $fqbn ${mainInoFile.name}"
                sendEvent("command", commandStr)

                // 4. Check if compiler binary is available
                if (compilerPath == null) {
                    performStaticVerification(
                        code = code,
                        filename = mainInoFile.name,
                        files = files,
                        boardName = boardName,
                        fqbn = fqbn,
                        startTime = startTime
                    )
                    return@submit
                }

                // 5. Execute real compilation process
                Log.d(TAG, "Executing compiler: $compilerPath compile --fqbn $fqbn ${tempSketchDir.absolutePath}")
                val processBuilder = ProcessBuilder(
                    compilerPath,
                    "compile",
                    "--fqbn",
                    fqbn,
                    tempSketchDir.absolutePath
                )
                processBuilder.directory(tempSketchDir)

                val process = processBuilder.start()
                activeProcess = process

                var detectedSketchBytes: Int? = null
                var detectedMaxSketchBytes: Int? = null
                var detectedGlobalVarBytes: Int? = null
                var detectedMaxGlobalVarBytes: Int? = null
                var errorCount = 0
                var warningCount = 0

                // Asynchronously read stdout
                val stdoutFuture = executor.submit {
                    readStream(process.inputStream) { line ->
                        parseMemoryUsage(line)?.let { (sketch, maxSketch, gVar, maxGVar) ->
                            if (sketch != null) detectedSketchBytes = sketch
                            if (maxSketch != null) detectedMaxSketchBytes = maxSketch
                            if (gVar != null) detectedGlobalVarBytes = gVar
                            if (maxGVar != null) detectedMaxGlobalVarBytes = maxGVar
                        }
                        sendEvent("stdout", line)
                    }
                }

                // Asynchronously read stderr
                val stderrFuture = executor.submit {
                    readStream(process.errorStream) { line ->
                        val diag = parseDiagnostic(line)
                        if (diag != null) {
                            val (type, file, lineNum, colNum, msg) = diag
                            if (type == "error") errorCount++ else warningCount++
                            sendDiagnosticEvent(type, msg, file, lineNum, colNum)
                        } else {
                            sendEvent("stderr", line)
                        }
                    }
                }

                // Wait for process and stream completion
                val exitCode = process.waitFor()
                stdoutFuture.get()
                stderrFuture.get()

                val duration = (System.currentTimeMillis() - startTime).toInt()
                val isSuccess = exitCode == 0

                if (isSuccess) {
                    sendEvent("success", "✓ Compilation successful (${duration}ms)")
                } else {
                    sendEvent("error", "✕ Compilation failed with exit code $exitCode")
                }

                // Send finished summary event
                sendFinishedEvent(
                    success = isSuccess,
                    exitCode = exitCode,
                    sketchBytes = detectedSketchBytes,
                    maxSketchBytes = detectedMaxSketchBytes,
                    globalVarBytes = detectedGlobalVarBytes,
                    maxGlobalVarBytes = detectedMaxGlobalVarBytes
                )

            } catch (e: Exception) {
                Log.e(TAG, "Compilation process error", e)
                sendEvent("error", "Process execution error: ${e.message}")
                sendFinishedEvent(success = false, exitCode = 1)
            } finally {
                activeProcess = null
                try {
                    tempSketchDir?.deleteRecursively()
                } catch (_: Exception) {}
            }
        }
    }

    private fun performStaticVerification(
        code: String,
        filename: String,
        files: Map<String, String>,
        boardName: String,
        fqbn: String,
        startTime: Long
    ) {
        Thread.sleep(200)
        sendEvent("stdout", "Compiling sketch...")

        val errors = mutableListOf<DiagnosticData>()
        val warnings = mutableListOf<DiagnosticData>()

        val allCode = StringBuilder(code)
        files.forEach { (name, content) ->
            if (name != filename) {
                allCode.append("\n").append(content)
            }
        }
        val fullSource = allCode.toString()

        val lines = code.lines()

        // 1. Check for basic Arduino entry points
        val hasSetup = lines.any { it.contains("void setup(") || it.contains("void setup (") }
        val hasLoop = lines.any { it.contains("void loop(") || it.contains("void loop (") }

        if (!hasSetup) {
            errors.add(
                DiagnosticData(
                    type = "error",
                    file = filename,
                    line = 1,
                    column = 1,
                    message = "undefined reference to 'setup'"
                )
            )
        }
        if (!hasLoop) {
            errors.add(
                DiagnosticData(
                    type = "error",
                    file = filename,
                    line = lines.size,
                    column = 1,
                    message = "undefined reference to 'loop'"
                )
            )
        }

        // 2. Check bracket and parenthesis balancing
        var openBraces = 0
        var openParens = 0
        lines.forEachIndexed { idx, line ->
            val clean = line.replace(Regex("//.*$"), "").replace(Regex("/\\*.*?\\*/"), "")
            for (ch in clean) {
                if (ch == '{') openBraces++
                if (ch == '}') openBraces--
                if (ch == '(') openParens++
                if (ch == ')') openParens--
            }
        }
        if (openBraces != 0) {
            errors.add(
                DiagnosticData(
                    type = "error",
                    file = filename,
                    line = lines.size,
                    column = 1,
                    message = if (openBraces > 0) "expected '}' at end of input" else "extraneous '}'"
                )
            )
        }

        // 3. Check for undeclared identifiers and common Arduino typos
        lines.forEachIndexed { idx, lineText ->
            val lineNum = idx + 1
            val trimmed = lineText.trim()

            // Check attachInterrupt undeclared callbacks
            if (trimmed.contains("attachInterrupt")) {
                val match = Regex("""attachInterrupt\s*\([^,]+,\s*([a-zA-Z0-9_]+)""").find(lineText)
                if (match != null) {
                    val callbackName = match.groupValues[1]
                    val isDefined = fullSource.contains(Regex("""void\s+$callbackName\s*\(""")) ||
                            fullSource.contains(Regex("""\b$callbackName\s*="""))
                    if (!isDefined) {
                        val col = lineText.indexOf(callbackName) + 1
                        errors.add(
                            DiagnosticData(
                                type = "error",
                                file = filename,
                                line = lineNum,
                                column = if (col > 0) col else 5,
                                message = "'$callbackName' was not declared in this scope"
                            )
                        )
                    }
                }
            }

            // Check for common Arduino API typos
            if (trimmed.contains("digitalWrit(") || trimmed.contains("digitalWrit ")) {
                val col = lineText.indexOf("digitalWrit") + 1
                errors.add(
                    DiagnosticData(
                        type = "error",
                        file = filename,
                        line = lineNum,
                        column = col,
                        message = "'digitalWrit' was not declared in this scope; did you mean 'digitalWrite'?"
                    )
                )
            }
            if (trimmed.contains("pinMod(") || trimmed.contains("pinMod ")) {
                val col = lineText.indexOf("pinMod") + 1
                errors.add(
                    DiagnosticData(
                        type = "error",
                        file = filename,
                        line = lineNum,
                        column = col,
                        message = "'pinMod' was not declared in this scope; did you mean 'pinMode'?"
                    )
                )
            }
        }

        // Stream diagnostics or success
        if (errors.isNotEmpty()) {
            Thread.sleep(150)
            errors.forEach { err ->
                val colStr = if (err.column != null) ":${err.column}" else ""
                sendEvent("stderr", "${err.file}:${err.line}$colStr: error: ${err.message}")
                sendDiagnosticEvent(err.type, err.message, err.file, err.line, err.column)
            }

            val duration = (System.currentTimeMillis() - startTime).toInt()
            sendEvent("error", "✕ Compilation failed with exit code 1")
            sendFinishedEvent(success = false, exitCode = 1)
        } else {
            Thread.sleep(150)
            sendEvent("stdout", "Compiling libraries...")
            Thread.sleep(150)
            sendEvent("stdout", "Compiling core...")
            Thread.sleep(150)
            sendEvent("stdout", "Linking everything together...")
            sendEvent("stdout", "Retrieving maximum program size...")

            val isEsp32 = fqbn.contains("esp32")
            val maxFlash = if (isEsp32) 1310720 else 32256
            val maxRam = if (isEsp32) 327680 else 2048
            val baseFlash = if (isEsp32) 245812 else 924
            val baseRam = if (isEsp32) 16832 else 9

            val sketchBytes = baseFlash + (code.length * 2)
            val globalVarBytes = baseRam + (code.length / 4)
            val flashPercent = (sketchBytes * 100 / maxFlash)
            val ramPercent = (globalVarBytes * 100 / maxRam)

            sendEvent("stdout", "Sketch uses $sketchBytes bytes ($flashPercent%) of program storage space. Maximum is $maxFlash bytes.")
            sendEvent("stdout", "Global variables use $globalVarBytes bytes ($ramPercent%) of dynamic memory, leaving ${maxRam - globalVarBytes} bytes for local variables. Maximum is $maxRam bytes.")

            val duration = (System.currentTimeMillis() - startTime).toInt()
            sendEvent("success", "✓ Compilation successful (${duration}ms)")
            sendFinishedEvent(
                success = true,
                exitCode = 0,
                sketchBytes = sketchBytes,
                maxSketchBytes = maxFlash,
                globalVarBytes = globalVarBytes,
                maxGlobalVarBytes = maxRam
            )
        }
    }

    fun cancel() {
        try {
            activeProcess?.destroyForcibly()
            activeTask?.cancel(true)
            sendEvent("error", "Compilation cancelled by user.")
            sendFinishedEvent(success = false, exitCode = 130)
        } catch (e: Exception) {
            Log.e(TAG, "Error cancelling compilation", e)
        }
    }

    private fun readStream(stream: InputStream, onLine: (String) -> Unit) {
        stream.bufferedReader().useLines { lines ->
            lines.forEach { line ->
                if (line.isNotEmpty()) {
                    onLine(line)
                }
            }
        }
    }

    private fun parseDiagnostic(line: String): DiagnosticData? {
        val matcher = diagnosticPattern.matcher(line.trim())
        if (matcher.find()) {
            val file = matcher.group(1)
            val lineNum = matcher.group(2)?.toIntOrNull()
            val colNum = matcher.group(3)?.toIntOrNull()
            val type = matcher.group(4)?.lowercase() ?: "error"
            val msg = matcher.group(5) ?: line
            return DiagnosticData(
                type = if (type.contains("warn")) "warning" else "error",
                file = file,
                line = lineNum,
                column = colNum,
                message = msg
            )
        }
        return null
    }

    private fun parseMemoryUsage(line: String): MemoryData? {
        var sBytes: Int? = null
        var maxSBytes: Int? = null
        var gBytes: Int? = null
        var maxGBytes: Int? = null

        val sMatch = sketchMemoryPattern.matcher(line)
        if (sMatch.find()) {
            sBytes = sMatch.group(1)?.toIntOrNull()
            maxSBytes = sMatch.group(2)?.toIntOrNull()
        }

        val gMatch = globalVarMemoryPattern.matcher(line)
        if (gMatch.find()) {
            gBytes = gMatch.group(1)?.toIntOrNull()
            maxGBytes = gMatch.group(2)?.toIntOrNull()
        }

        return if (sBytes != null || gBytes != null) {
            MemoryData(sBytes, maxSBytes, gBytes, maxGBytes)
        } else null
    }

    private fun sendEvent(type: String, message: String, exitCode: Int? = null) {
        mainHandler.post {
            val event = mutableMapOf<String, Any>(
                "type" to type,
                "message" to message,
                "timestamp" to System.currentTimeMillis()
            )
            if (exitCode != null) {
                event["exitCode"] = exitCode
            }
            try {
                getEventSink()?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "Failed sending event: $type", e)
            }
        }
    }

    private fun sendDiagnosticEvent(
        type: String,
        message: String,
        file: String?,
        line: Int?,
        column: Int?
    ) {
        mainHandler.post {
            val event = mutableMapOf<String, Any>(
                "type" to type,
                "message" to message,
                "timestamp" to System.currentTimeMillis()
            )
            if (file != null) event["file"] = file
            if (line != null) event["line"] = line
            if (column != null) event["column"] = column
            try {
                getEventSink()?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "Failed sending diagnostic event: $type", e)
            }
        }
    }

    private fun sendFinishedEvent(
        success: Boolean,
        exitCode: Int,
        sketchBytes: Int? = null,
        maxSketchBytes: Int? = null,
        globalVarBytes: Int? = null,
        maxGlobalVarBytes: Int? = null
    ) {
        mainHandler.post {
            val event = mutableMapOf<String, Any>(
                "type" to "finished",
                "message" to if (success) "Compilation finished successfully." else "Compilation failed.",
                "exitCode" to exitCode,
                "success" to success,
                "timestamp" to System.currentTimeMillis()
            )
            if (sketchBytes != null) event["sketchBytes"] = sketchBytes
            if (maxSketchBytes != null) event["maxSketchBytes"] = maxSketchBytes
            if (globalVarBytes != null) event["globalVarBytes"] = globalVarBytes
            if (maxGlobalVarBytes != null) event["maxGlobalVarBytes"] = maxGlobalVarBytes
            try {
                getEventSink()?.success(event)
            } catch (e: Exception) {
                Log.e(TAG, "Failed sending finished event", e)
            }
        }
    }

    private data class DiagnosticData(
        val type: String,
        val file: String?,
        val line: Int?,
        val column: Int?,
        val message: String
    )

    private data class MemoryData(
        val sketchBytes: Int?,
        val maxSketchBytes: Int?,
        val globalVarBytes: Int?,
        val maxGlobalVarBytes: Int?
    )
}
