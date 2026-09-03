import 'dart:async';
import 'package:arduino_ide/models/editor_file_model.dart';
import 'package:arduino_ide/models/upload_event.dart';
import 'package:arduino_ide/models/usb_device_info.dart';
import 'package:arduino_ide/services/arduino_uploader.dart';
import 'package:flutter/services.dart';

class NativeArduinoUploader implements ArduinoUploader {
  static const MethodChannel _channel = MethodChannel('arduino/upload');
  static const EventChannel _eventChannel =
      EventChannel('arduino/upload/events');

  @override
  Future<List<UsbDeviceInfo>> getConnectedUsbDevices() async {
    try {
      final List<dynamic>? rawList =
          await _channel.invokeMethod<List<dynamic>>('getUsbDevices');
      if (rawList == null) return [];

      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((m) => UsbDeviceInfo.fromMap(m))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> requestUsbPermission(int deviceId) async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'requestUsbPermission',
        {'deviceId': deviceId},
      );
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<UploadEvent> upload({
    required String code,
    required String fqbn,
    required String filename,
    List<EditorFile> allFiles = const [],
    int? deviceId,
    String boardName = 'ESP32 Dev Module',
  }) {
    late StreamController<UploadEvent> controller;
    StreamSubscription<dynamic>? eventSubscription;

    controller = StreamController<UploadEvent>(
      onListen: () async {
        try {
          // Listen to native upload event stream
          eventSubscription = _eventChannel.receiveBroadcastStream().listen(
            (dynamic rawEvent) {
              if (rawEvent is Map) {
                final event = UploadEvent.fromMap(rawEvent);
                controller.add(event);
                if (event.type == UploadEventType.finished) {
                  controller.close();
                }
              }
            },
            onError: (dynamic error) {
              controller.add(
                UploadEvent(
                  type: UploadEventType.error,
                  message: 'Upload error: $error',
                  timestamp: DateTime.now(),
                ),
              );
              controller.add(
                UploadEvent(
                  type: UploadEventType.finished,
                  message: 'Upload terminated.',
                  timestamp: DateTime.now(),
                  exitCode: 1,
                ),
              );
              controller.close();
            },
          );

          final fileMap = <String, String>{};
          for (final f in allFiles) {
            fileMap[f.name] = f.content;
          }

          // Trigger native upload orchestration
          await _channel.invokeMethod('upload', {
            'code': code,
            'fqbn': fqbn,
            'filename': filename,
            'board': boardName,
            'deviceId': deviceId,
            'files': fileMap,
          });
        } on PlatformException catch (e) {
          controller.add(
            UploadEvent(
              type: UploadEventType.error,
              message: e.message ?? 'Upload initialization failed',
              timestamp: DateTime.now(),
            ),
          );
          controller.add(
            UploadEvent(
              type: UploadEventType.finished,
              message: 'Upload failed.',
              timestamp: DateTime.now(),
              exitCode: 1,
            ),
          );
          controller.close();
        } catch (e) {
          controller.add(
            UploadEvent(
              type: UploadEventType.error,
              message: e.toString(),
              timestamp: DateTime.now(),
            ),
          );
          controller.add(
            UploadEvent(
              type: UploadEventType.finished,
              message: 'Upload failed.',
              timestamp: DateTime.now(),
              exitCode: 1,
            ),
          );
          controller.close();
        }
      },
      onCancel: () {
        eventSubscription?.cancel();
        cancelUpload();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> cancelUpload() async {
    try {
      await _channel.invokeMethod('cancelUpload');
    } catch (_) {}
  }
}
