package com.bizunite.org.arduino_ide.arduino.upload

import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.util.Log

class UsbSerialDriver(
    private val usbManager: UsbManager,
    private val device: UsbDevice,
    private val chipType: UsbSerialChip
) {
    private val TAG = "UsbSerialDriver"

    private var connection: UsbDeviceConnection? = null
    private var usbInterface: UsbInterface? = null
    private var readEndpoint: UsbEndpoint? = null
    private var writeEndpoint: UsbEndpoint? = null

    val isOpen: Boolean
        get() = connection != null

    fun open(baudRate: Int = 115200): Boolean {
        val conn = usbManager.openDevice(device) ?: run {
            Log.e(TAG, "Failed to open UsbDeviceConnection for ${device.deviceName}")
            return false
        }
        connection = conn

        // Find and claim communication/data interface
        var dataInterface: UsbInterface? = null
        for (i in 0 until device.interfaceCount) {
            val intf = device.getInterface(i)
            // Look for Bulk In and Bulk Out endpoints
            var hasIn = false
            var hasOut = false
            for (j in 0 until intf.endpointCount) {
                val ep = intf.getEndpoint(j)
                if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                    if (ep.direction == UsbConstants.USB_DIR_IN) hasIn = true
                    if (ep.direction == UsbConstants.USB_DIR_OUT) hasOut = true
                }
            }
            if (hasIn && hasOut) {
                dataInterface = intf
                break
            }
        }

        if (dataInterface == null && device.interfaceCount > 0) {
            dataInterface = device.getInterface(0)
        }

        if (dataInterface == null) {
            Log.e(TAG, "No suitable USB data interface found")
            conn.close()
            connection = null
            return false
        }

        usbInterface = dataInterface
        if (!conn.claimInterface(dataInterface, true)) {
            Log.e(TAG, "Failed to claim USB interface ${dataInterface.id}")
            conn.close()
            connection = null
            return false
        }

        // Assign endpoints
        for (i in 0 until dataInterface.endpointCount) {
            val ep = dataInterface.getEndpoint(i)
            if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                if (ep.direction == UsbConstants.USB_DIR_IN) {
                    readEndpoint = ep
                } else if (ep.direction == UsbConstants.USB_DIR_OUT) {
                    writeEndpoint = ep
                }
            }
        }

        // Initialize chip specific serial parameters
        val initSuccess = initChip(baudRate)
        if (!initSuccess) {
            Log.w(TAG, "Chip initialization had warnings, but endpoints are active")
        }

        Log.d(TAG, "USB Serial opened successfully for ${device.deviceName} ($chipType) at $baudRate baud")
        return true
    }

    private fun initChip(baudRate: Int): Boolean {
        val conn = connection ?: return false

        return when (chipType) {
            UsbSerialChip.CP210X -> {
                // CP210x Enable interface
                conn.controlTransfer(0x41, 0x00, 0x0001, 0, null, 0, 1000)
                // Set Baudrate
                val baudBytes = byteArrayOf(
                    (baudRate and 0xFF).toByte(),
                    ((baudRate shr 8) and 0xFF).toByte(),
                    ((baudRate shr 16) and 0xFF).toByte(),
                    ((baudRate shr 24) and 0xFF).toByte()
                )
                conn.controlTransfer(0x41, 0x1E, 0, 0, baudBytes, 4, 1000)
                // Set Line Control 8N1 (8 data bits, 1 stop bit, no parity)
                conn.controlTransfer(0x41, 0x03, 0x0800, 0, null, 0, 1000)
                // Initial DTR/RTS state
                setDtrRts(false, false)
                true
            }

            UsbSerialChip.CH340 -> {
                // CH340 Init sequence
                conn.controlTransfer(0x40, 0xA1, 0, 0, null, 0, 1000)
                conn.controlTransfer(0x40, 0x9A, 0x2518, 0x0050, null, 0, 1000)
                conn.controlTransfer(0x40, 0xA1, 0x501F, 0xD90A, null, 0, 1000)
                setDtrRts(false, false)
                true
            }

            UsbSerialChip.FTDI -> {
                // FTDI Reset
                conn.controlTransfer(0x40, 0x00, 0, 0, null, 0, 1000)
                // FTDI Set Baudrate for 115200 (divisor: 26)
                conn.controlTransfer(0x40, 0x03, 0x001A, 0, null, 0, 1000)
                // 8N1
                conn.controlTransfer(0x40, 0x04, 0x0008, 0, null, 0, 1000)
                setDtrRts(false, false)
                true
            }

            UsbSerialChip.CDC_ACM -> {
                // Set Line Coding: 115200, 1 stop bit, no parity, 8 data bits
                val lineCoding = byteArrayOf(
                    (baudRate and 0xFF).toByte(),
                    ((baudRate shr 8) and 0xFF).toByte(),
                    ((baudRate shr 16) and 0xFF).toByte(),
                    ((baudRate shr 24) and 0xFF).toByte(),
                    0x00, // 1 stop bit
                    0x00, // no parity
                    0x08  // 8 data bits
                )
                conn.controlTransfer(0x21, 0x20, 0, 0, lineCoding, 7, 1000)
                setDtrRts(true, true)
                true
            }

            UsbSerialChip.UNKNOWN -> {
                setDtrRts(true, true)
                true
            }
        }
    }

    /**
     * Sets DTR and RTS line state to control ESP32 hardware auto-reset circuit
     */
    fun setDtrRts(dtr: Boolean, rts: Boolean) {
        val conn = connection ?: return

        when (chipType) {
            UsbSerialChip.CP210X -> {
                var value = 0x0000
                if (dtr) value = value or 0x0101 else value = value or 0x0100
                if (rts) value = value or 0x0202 else value = value or 0x0200
                conn.controlTransfer(0x41, 0x07, value, 0, null, 0, 500)
            }

            UsbSerialChip.CH340 -> {
                var value = 0
                if (!dtr) value = value or 0x20
                if (!rts) value = value or 0x40
                conn.controlTransfer(0x40, 0xA4, value, 0, null, 0, 500)
            }

            UsbSerialChip.FTDI -> {
                var value = 0
                if (dtr) value = value or 0x0101 else value = value or 0x0100
                if (rts) value = value or 0x0202 else value = value or 0x0200
                conn.controlTransfer(0x40, 0x01, value, 0, null, 0, 500)
            }

            UsbSerialChip.CDC_ACM, UsbSerialChip.UNKNOWN -> {
                var value = 0
                if (dtr) value = value or 0x01
                if (rts) value = value or 0x02
                conn.controlTransfer(0x21, 0x22, value, 0, null, 0, 500)
            }
        }
    }

    fun write(data: ByteArray, timeout: Int = 2000): Int {
        val conn = connection ?: return -1
        val ep = writeEndpoint ?: return -1
        return conn.bulkTransfer(ep, data, data.size, timeout)
    }

    fun read(buffer: ByteArray, timeout: Int = 2000): Int {
        val conn = connection ?: return -1
        val ep = readEndpoint ?: return -1
        return conn.bulkTransfer(ep, buffer, buffer.size, timeout)
    }

    fun purgeBuffers() {
        val temp = ByteArray(1024)
        while (read(temp, 50) > 0) {
            // Drain remaining bytes
        }
    }

    fun close() {
        try {
            setDtrRts(false, false)
            usbInterface?.let { connection?.releaseInterface(it) }
            connection?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing USB connection", e)
        } finally {
            connection = null
            usbInterface = null
            readEndpoint = null
            writeEndpoint = null
        }
    }
}
