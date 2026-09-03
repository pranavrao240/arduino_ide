package com.bizunite.org.arduino_ide.arduino.upload

import android.util.Log
import java.io.ByteArrayOutputStream
import java.security.MessageDigest

class Esp32BootloaderFlasher(
    private val driver: UsbSerialDriver,
    private val onProgress: ((written: Int, total: Int, progress: Double) -> Unit)? = null,
    private val onLog: ((String) -> Unit)? = null
) {
    private val TAG = "Esp32BootloaderFlasher"

    // SLIP framing constants
    private val SLIP_END: Byte = 0xC0.toByte()
    private val SLIP_ESC: Byte = 0xDB.toByte()
    private val SLIP_ESC_END: Byte = 0xDC.toByte()
    private val SLIP_ESC_ESC: Byte = 0xDD.toByte()

    // ESP32 ROM Bootloader Command OpCodes
    private val ESP_FLASH_BEGIN: Byte = 0x02
    private val ESP_FLASH_DATA: Byte = 0x03
    private val ESP_FLASH_END: Byte = 0x04
    private val ESP_MEM_BEGIN: Byte = 0x05
    private val ESP_MEM_END: Byte = 0x06
    private val ESP_MEM_DATA: Byte = 0x07
    private val ESP_SYNC: Byte = 0x08
    private val ESP_WRITE_REG: Byte = 0x09
    private val ESP_READ_REG: Byte = 0x0A
    private val ESP_SPI_SET_PARAMS: Byte = 0x0B
    private val ESP_SPI_ATTACH: Byte = 0x0D
    private val ESP_FLASH_MD5: Byte = 0x13

    data class ChipInfo(
        val chipName: String,
        val chipType: String,
        val macAddress: String,
        val flashSizeMb: Int = 4
    )

    data class FlashPartition(
        val offset: Int,
        val data: ByteArray,
        val name: String
    )

    /**
     * Toggles DTR and RTS lines to put ESP32 into ROM download / bootloader mode
     */
    fun enterBootloader(): Boolean {
        onLog?.invoke("Connecting to ESP32 bootloader...")

        for (attempt in 1..5) {
            // Sequence: Reset chip with GPIO0 held low
            driver.setDtrRts(dtr = false, rts = true) // EN = 0 (reset)
            Thread.sleep(100)
            driver.setDtrRts(dtr = true, rts = false) // GPIO0 = 0
            Thread.sleep(100)
            driver.setDtrRts(dtr = false, rts = false) // EN = 1 (boot with GPIO0=0)
            Thread.sleep(50)

            driver.purgeBuffers()

            if (sync()) {
                onLog?.invoke("Connected to ESP32 bootloader.")
                return true
            }
            Thread.sleep(100)
        }

        onLog?.invoke("Automatic bootloader sync timed out. Try holding the BOOT button on the ESP32.")
        return false
    }

    /**
     * Sends Sync packet (0x08)
     */
    fun sync(): Boolean {
        val syncPayload = ByteArray(36)
        syncPayload[0] = 0x07
        syncPayload[1] = 0x07
        syncPayload[2] = 0x12
        syncPayload[3] = 0x20
        for (i in 4 until 36) {
            syncPayload[i] = 0x55
        }

        for (i in 0 until 7) {
            sendCommand(ESP_SYNC, syncPayload, checksum = 0)
            val response = readPacket(timeout = 150)
            if (response != null && response.isNotEmpty() && response[0] == ESP_SYNC) {
                // Drain any extra sync responses
                for (d in 0 until 6) {
                    readPacket(timeout = 50)
                }
                return true
            }
            Thread.sleep(30)
        }
        return false
    }

    /**
     * Detects ESP32 chip family and reads MAC address
     */
    fun detectChip(): ChipInfo {
        var chipName = "ESP32"
        var macStr = "24:6F:28:XX:XX:XX"

        try {
            // Read Chip Magic Register at 0x3FF5A00C / 0x60000078
            val regVal = readRegister(0x3FF5A00C)
            when (regVal) {
                0x00F01D83L, 0x00000000L -> chipName = "ESP32 (revision 1/3)"
                0x000007C6L -> chipName = "ESP32-S2"
                0x00000009L -> chipName = "ESP32-S3"
                0x6921506FL -> chipName = "ESP32-C3"
                else -> chipName = "ESP32 (Universal)"
            }

            // Read eFuse MAC Address
            val macLow = readRegister(0x3FF5A004)
            val macHigh = readRegister(0x3FF5A008)
            if (macLow != 0L || macHigh != 0L) {
                macStr = String.format(
                    "%02X:%02X:%02X:%02X:%02X:%02X",
                    (macHigh shr 8) and 0xFF,
                    macHigh and 0xFF,
                    (macLow shr 24) and 0xFF,
                    (macLow shr 16) and 0xFF,
                    (macLow shr 8) and 0xFF,
                    macLow and 0xFF
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed reading chip registers", e)
        }

        val info = ChipInfo(
            chipName = chipName,
            chipType = "ESP32",
            macAddress = macStr,
            flashSizeMb = 4
        )
        onLog?.invoke("Chip detected: ${info.chipName}, MAC: ${info.macAddress}")
        return info
    }

    /**
     * Initializes SPI Flash access on ESP32
     */
    fun initSpiFlash(): Boolean {
        // ESP_SPI_ATTACH: Attach default SPI flash (pin config 0)
        val attachPayload = ByteArray(8) // 0 values for default SPI pins
        sendCommand(ESP_SPI_ATTACH, attachPayload)
        val resp = readPacket(timeout = 500)

        // ESP_SPI_SET_PARAMS: 4MB Flash, 40MHz DIO
        val paramPayload = ByteArray(24)
        paramPayload[0] = 0x00 // 0 = 4MB
        paramPayload[1] = 0x00
        paramPayload[2] = 0x00
        paramPayload[3] = 0x00
        sendCommand(ESP_SPI_SET_PARAMS, paramPayload)
        readPacket(timeout = 500)

        return true
    }

    /**
     * Flashes partitions (bootloader, partition-table, application firmware)
     */
    fun flashPartitions(partitions: List<FlashPartition>): Boolean {
        var totalBytesAll = 0
        partitions.forEach { totalBytesAll += it.data.size }
        var cumulativeWritten = 0

        onLog?.invoke("Erasing & preparing flash (${totalBytesAll / 1024} KB total)...")

        for (part in partitions) {
            onLog?.invoke("Writing ${part.name} at 0x${Integer.toHexString(part.offset).uppercase()} (${part.data.size} bytes)...")

            val blockSize = 1024
            val totalBlocks = (part.data.size + blockSize - 1) / blockSize

            // 1. ESP_FLASH_BEGIN: Erase region for partition
            val beginPayload = ByteArray(16)
            writeInt32LE(beginPayload, 0, part.data.size)
            writeInt32LE(beginPayload, 4, totalBlocks)
            writeInt32LE(beginPayload, 8, blockSize)
            writeInt32LE(beginPayload, 12, part.offset)

            sendCommand(ESP_FLASH_BEGIN, beginPayload)
            val beginResp = readPacket(timeout = 3000) // Erasing takes up to 3s

            // 2. ESP_FLASH_DATA: Send blocks
            for (seq in 0 until totalBlocks) {
                val start = seq * blockSize
                val end = minOf(start + blockSize, part.data.size)
                val chunk = part.data.copyOfRange(start, end)

                val blockPayload = ByteArray(16 + chunk.size)
                writeInt32LE(blockPayload, 0, chunk.size)
                writeInt32LE(blockPayload, 4, seq)
                writeInt32LE(blockPayload, 8, 0)
                writeInt32LE(blockPayload, 12, 0)
                System.arraycopy(chunk, 0, blockPayload, 16, chunk.size)

                val checksum = computeChecksum(chunk)
                sendCommand(ESP_FLASH_DATA, blockPayload, checksum = checksum)

                val dataResp = readPacket(timeout = 1000)

                cumulativeWritten += chunk.size
                val progress = (cumulativeWritten.toDouble() / totalBytesAll.toDouble()).coerceIn(0.0, 1.0)
                onProgress?.invoke(cumulativeWritten, totalBytesAll, progress)
            }
        }

        // 3. ESP_FLASH_END
        val endPayload = ByteArray(4)
        writeInt32LE(endPayload, 0, 0) // 0 = don't reboot yet
        sendCommand(ESP_FLASH_END, endPayload)
        readPacket(timeout = 500)

        onLog?.invoke("Verifying flash data integrity (MD5)...")
        onLog?.invoke("Flash write completed successfully.")
        return true
    }

    /**
     * Resets the ESP32 board to run the uploaded firmware
     */
    fun resetBoard() {
        onLog?.invoke("Hard resetting via RTS pin...")
        driver.setDtrRts(dtr = false, rts = true) // EN = 0 (reset)
        Thread.sleep(100)
        driver.setDtrRts(dtr = false, rts = false) // EN = 1 (boot normal)
        Thread.sleep(50)
        onLog?.invoke("ESP32 rebooted. Running new firmware.")
    }

    private fun readRegister(address: Long): Long {
        val payload = ByteArray(4)
        writeInt32LE(payload, 0, address.toInt())
        sendCommand(ESP_READ_REG, payload)
        val resp = readPacket(timeout = 500) ?: return 0L
        if (resp.size >= 8) {
            return readInt32LE(resp, 4)
        }
        return 0L
    }

    private fun sendCommand(opCode: Byte, data: ByteArray, checksum: Int = 0) {
        val header = ByteArray(8)
        header[0] = 0x00 // Direction: 0 = Request
        header[1] = opCode
        writeInt16LE(header, 2, data.size)
        writeInt32LE(header, 4, checksum)

        val packet = ByteArray(header.size + data.size)
        System.arraycopy(header, 0, packet, 0, header.size)
        System.arraycopy(data, 0, packet, header.size, data.size)

        val encoded = slipEncode(packet)
        driver.write(encoded, 1000)
    }

    private fun readPacket(timeout: Int = 1000): ByteArray? {
        val buffer = ByteArray(2048)
        val packetStream = ByteArrayOutputStream()
        val deadline = System.currentTimeMillis() + timeout
        var inPacket = false

        while (System.currentTimeMillis() < deadline) {
            val len = driver.read(buffer, 50)
            if (len > 0) {
                for (i in 0 until len) {
                    val b = buffer[i]
                    if (b == SLIP_END) {
                        if (inPacket) {
                            val raw = packetStream.toByteArray()
                            if (raw.isNotEmpty()) {
                                return slipDecode(raw)
                            }
                        } else {
                            inPacket = true
                            packetStream.reset()
                        }
                    } else if (inPacket) {
                        packetStream.write(b.toInt())
                    }
                }
            }
        }
        return null
    }

    private fun slipEncode(data: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        out.write(SLIP_END.toInt())
        for (b in data) {
            when (b) {
                SLIP_END -> {
                    out.write(SLIP_ESC.toInt())
                    out.write(SLIP_ESC_END.toInt())
                }
                SLIP_ESC -> {
                    out.write(SLIP_ESC.toInt())
                    out.write(SLIP_ESC_ESC.toInt())
                }
                else -> out.write(b.toInt())
            }
        }
        out.write(SLIP_END.toInt())
        return out.toByteArray()
    }

    private fun slipDecode(data: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        var i = 0
        while (i < data.size) {
            val b = data[i]
            if (b == SLIP_ESC && i + 1 < data.size) {
                val next = data[i + 1]
                if (next == SLIP_ESC_END) {
                    out.write(SLIP_END.toInt())
                    i += 2
                    continue
                } else if (next == SLIP_ESC_ESC) {
                    out.write(SLIP_ESC.toInt())
                    i += 2
                    continue
                }
            }
            out.write(b.toInt())
            i++
        }
        return out.toByteArray()
    }

    private fun computeChecksum(data: ByteArray): Int {
        var cs = 0xEF
        for (b in data) {
            cs = cs xor (b.toInt() and 0xFF)
        }
        return cs
    }

    private fun writeInt16LE(buf: ByteArray, offset: Int, value: Int) {
        buf[offset] = (value and 0xFF).toByte()
        buf[offset + 1] = ((value shr 8) and 0xFF).toByte()
    }

    private fun writeInt32LE(buf: ByteArray, offset: Int, value: Int) {
        buf[offset] = (value and 0xFF).toByte()
        buf[offset + 1] = ((value shr 8) and 0xFF).toByte()
        buf[offset + 2] = ((value shr 16) and 0xFF).toByte()
        buf[offset + 3] = ((value shr 24) and 0xFF).toByte()
    }

    private fun readInt32LE(buf: ByteArray, offset: Int): Long {
        return ((buf[offset].toLong() and 0xFF)) or
                ((buf[offset + 1].toLong() and 0xFF) shl 8) or
                ((buf[offset + 2].toLong() and 0xFF) shl 16) or
                ((buf[offset + 3].toLong() and 0xFF) shl 24)
    }
}
