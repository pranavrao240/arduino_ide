import 'package:arduino_ide/models/arduino_board.dart';
import 'package:arduino_ide/models/compilation_event.dart';
import 'package:arduino_ide/models/terminal_log.dart';
import 'package:arduino_ide/models/upload_event.dart';
import 'package:arduino_ide/models/upload_result.dart';
import 'package:arduino_ide/models/usb_device_info.dart';
import 'package:arduino_ide/services/native_arduino_compiler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Arduino Compiler & Models Tests', () {
    test('ArduinoBoard FQBN and memory definitions', () {
      expect(ArduinoBoard.esp32DevModule.fqbn, 'esp32:esp32:esp32');
      expect(ArduinoBoard.esp32DevModule.architecture, 'esp32');
      expect(ArduinoBoard.esp32DevModule.maxFlashBytes, 1310720);
      expect(ArduinoBoard.esp32DevModule.maxRamBytes, 327680);

      expect(ArduinoBoard.arduinoUno.fqbn, 'arduino:avr:uno');
      expect(ArduinoBoard.fromName('ESP32 Dev Module'), ArduinoBoard.esp32DevModule);
    });

    test('CompilationEvent and TerminalLog creation', () {
      final cmdLog = TerminalLog.command('\$ arduino-cli compile --fqbn esp32:esp32:esp32 Sketch.ino');
      expect(cmdLog.type, TerminalLogType.command);
      expect(cmdLog.message, contains('arduino-cli'));

      final errLog = TerminalLog.error(
        "'digitalWrit' was not declared in this scope",
        file: 'Sketch.ino',
        line: 15,
        column: 3,
      );
      expect(errLog.type, TerminalLogType.error);
      expect(errLog.line, 15);
      expect(errLog.column, 3);
    });

    test('GCC Diagnostic Error parsing', () {
      const line = "Sketch.ino:15:3: error: 'digitalWrit' was not declared in this scope";
      final event = NativeArduinoCompiler.parseDiagnosticLine(line);

      expect(event, isNotNull);
      expect(event!.type, CompilationEventType.error);
      expect(event.file, 'Sketch.ino');
      expect(event.line, 15);
      expect(event.column, 3);
      expect(event.message, contains("'digitalWrit' was not declared in this scope"));
    });

    test('GCC Diagnostic Warning parsing', () {
      const line = 'Sensor.h:42:10: warning: unused variable ‘counter’ [-Wunused-variable]';
      final event = NativeArduinoCompiler.parseDiagnosticLine(line);

      expect(event, isNotNull);
      expect(event!.type, CompilationEventType.warning);
      expect(event.file, 'Sensor.h');
      expect(event.line, 42);
      expect(event.column, 10);
    });

    test('UploadEvent and UsbDeviceInfo parsing', () {
      final dev = UsbDeviceInfo.fromMap({
        'name': '/dev/bus/usb/001/002',
        'productName': 'CP2102 USB to UART Bridge Controller',
        'vendorId': 0x10C4,
        'productId': 0xEA60,
        'deviceId': 1002,
        'chipType': 'CP210X',
        'hasPermission': true,
      });

      expect(dev.displayName, contains('CP2102'));
      expect(dev.chipType, 'CP210X');
      expect(dev.hasPermission, true);

      final event = UploadEvent.fromMap({
        'type': 'progress',
        'message': 'Writing: 45% (110 KB / 245 KB)',
        'progress': 0.45,
        'writtenBytes': 112640,
        'totalBytes': 250880,
      });

      expect(event.type, UploadEventType.progress);
      expect(event.progress, 0.45);
      expect(event.writtenBytes, 112640);
    });
  });
}
