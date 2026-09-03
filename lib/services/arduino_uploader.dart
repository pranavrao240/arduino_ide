import 'dart:async';
import 'package:arduino_ide/models/editor_file_model.dart';
import 'package:arduino_ide/models/upload_event.dart';
import 'package:arduino_ide/models/usb_device_info.dart';

abstract class ArduinoUploader {
  /// Queries connected USB OTG devices
  Future<List<UsbDeviceInfo>> getConnectedUsbDevices();

  /// Requests runtime Android USB permission for a specific USB device
  Future<bool> requestUsbPermission(int deviceId);

  /// Performs full upload process: compilation, bootloader connection, flashing, progress streaming, and reset
  Stream<UploadEvent> upload({
    required String code,
    required String fqbn,
    required String filename,
    List<EditorFile> allFiles = const [],
    int? deviceId,
    String boardName = 'ESP32 Dev Module',
  });

  /// Cancels an active upload process
  Future<void> cancelUpload();
}
