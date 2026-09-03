import 'dart:async';
import 'package:flutter/services.dart';

class DetectedSerialDevice {
  const DetectedSerialDevice({
    required this.portName,
    required this.deviceName,
    required this.isConnected,
    this.description,
    this.manufacturer,
    this.vendorId,
    this.productId,
  });

  final String portName;
  final String deviceName;
  final bool isConnected;
  final String? description;
  final String? manufacturer;
  final int? vendorId;
  final int? productId;
}

class SerialPortService {
  static const MethodChannel _channel =
      MethodChannel('com.bizunite.org.arduino_ide/usb_serial');

  /// Known Vendor IDs for Arduino & USB-to-Serial Microcontrollers
  static const int _arduinoVid = 0x2341;
  static const int _ch340Vid = 0x1a86; // Common Arduino Nano / Uno clones
  static const int _cp210xVid = 0x10c4; // ESP32 / NodeMCU / CP2102
  static const int _ftdiVid = 0x0403; // FTDI chips
  static const int _rp2040Vid = 0x2e8a; // Raspberry Pi Pico
  static const int _espressifVid = 0x303a; // ESP32-S2/S3/C3

  /// Scans connected USB serial devices and identifies connected Arduino hardware
  static Future<DetectedSerialDevice> checkConnection({
    String? preferredPort,
  }) async {
    try {
      final rawDevices =
          await _channel.invokeMethod<List<dynamic>>('getConnectedDevices');

      if (rawDevices == null || rawDevices.isEmpty) {
        return const DetectedSerialDevice(
          portName: 'No Port',
          deviceName: 'No Device',
          isConnected: false,
        );
      }

      final first = Map<String, dynamic>.from(rawDevices.first as Map);
      final vid = (first['vendorId'] as int?) ?? 0;
      final pid = (first['productId'] as int?) ?? 0;
      final manufacturer =
          ((first['manufacturerName'] as String?) ?? '').toLowerCase();
      final product =
          ((first['productName'] as String?) ?? '').toLowerCase();
      final portName =
          (first['deviceName'] as String?) ?? '/dev/bus/usb/001';

      String detectedName = 'USB Serial Device';

      // Identify board type based on VID/PID, product name, or manufacturer
      if (vid == _arduinoVid ||
          manufacturer.contains('arduino') ||
          product.contains('arduino')) {
        if (product.contains('mega')) {
          detectedName = 'Arduino Mega 2560';
        } else if (product.contains('nano')) {
          detectedName = 'Arduino Nano';
        } else {
          detectedName = 'Arduino Uno';
        }
      } else if (vid == _ch340Vid ||
          product.contains('ch340') ||
          manufacturer.contains('wch')) {
        detectedName = 'Arduino (CH340)';
      } else if (vid == _cp210xVid ||
          vid == _espressifVid ||
          product.contains('esp32') ||
          manufacturer.contains('espressif')) {
        detectedName = 'ESP32 Dev Module';
      } else if (vid == _rp2040Vid || product.contains('pico')) {
        detectedName = 'Raspberry Pi Pico';
      } else if (vid == _ftdiVid || manufacturer.contains('ftdi')) {
        detectedName = 'FTDI Serial';
      } else {
        detectedName = product.isNotEmpty
            ? (first['productName'] as String)
            : 'Arduino Uno';
      }

      return DetectedSerialDevice(
        portName: portName,
        deviceName: detectedName,
        isConnected: true,
        description: first['productName'] as String?,
        manufacturer: first['manufacturerName'] as String?,
        vendorId: vid,
        productId: pid,
      );
    } catch (_) {
      return const DetectedSerialDevice(
        portName: 'Disconnected',
        deviceName: 'No Device',
        isConnected: false,
      );
    }
  }
}
