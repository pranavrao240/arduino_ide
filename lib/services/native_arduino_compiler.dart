import 'dart:async';
import 'package:arduino_ide/models/compilation_event.dart';
import 'package:arduino_ide/models/editor_file_model.dart';
import 'package:arduino_ide/services/arduino_compiler.dart';
import 'package:flutter/services.dart';

class NativeArduinoCompiler implements ArduinoCompiler {
  static const MethodChannel _channel = MethodChannel('arduino/compiler');
  static const EventChannel _eventChannel =
      EventChannel('arduino/compiler/events');

  // GCC diagnostic error/warning pattern: Sketch.ino:15:3: error: 'digitalWrit' was not declared
  static final RegExp _gccDiagnosticRegex = RegExp(
    r'^(?:(?<file>[^:\n\r]+):(?<line>\d+):(?:(?<col>\d+):)?\s+)?(?<type>error|warning|fatal error):\s*(?<msg>.*)$',
    caseSensitive: false,
  );

  @override
  Future<bool> isInstalled() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('checkToolchain');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initializeCompiler');
    } catch (_) {}
  }

  @override
  Stream<CompilationEvent> verify({
    required String code,
    required String fqbn,
    String filename = 'Sketch.ino',
    List<EditorFile> allFiles = const [],
    String boardName = 'ESP32 Dev Module',
  }) {
    late StreamController<CompilationEvent> controller;
    StreamSubscription<dynamic>? eventSubscription;

    controller = StreamController<CompilationEvent>(
      onListen: () async {
        try {
          // Listen to live native compiler event stream
          eventSubscription = _eventChannel.receiveBroadcastStream().listen(
            (dynamic rawEvent) {
              if (rawEvent is Map) {
                final event = CompilationEvent.fromMap(rawEvent);
                controller.add(event);
                if (event.type == CompilationEventType.finished) {
                  controller.close();
                }
              }
            },
            onError: (dynamic error) {
              controller.add(
                CompilationEvent(
                  type: CompilationEventType.error,
                  message: 'Native process error: $error',
                  timestamp: DateTime.now(),
                ),
              );
              controller.add(
                CompilationEvent(
                  type: CompilationEventType.finished,
                  message: 'Compilation terminated with error.',
                  timestamp: DateTime.now(),
                  exitCode: 1,
                ),
              );
              controller.close();
            },
          );

          // Prepare sketch files map
          final fileMap = <String, String>{};
          for (final f in allFiles) {
            fileMap[f.name] = f.content;
          }

          // Trigger native compilation
          final dynamic result = await _channel.invokeMethod('compile', {
            'code': code,
            'fqbn': fqbn,
            'filename': filename,
            'board': boardName,
            'files': fileMap,
          });

          // Handle immediate sync events if provided by platform
          if (result is Map) {
            final List<dynamic>? events = result['events'] as List<dynamic>?;
            if (events != null && events.isNotEmpty && !controller.isClosed) {
              for (final e in events) {
                if (e is Map) {
                  controller.add(CompilationEvent.fromMap(e));
                }
              }
              if (!controller.isClosed) {
                controller.close();
              }
            }
          }
        } on PlatformException catch (e) {
          controller.add(
            CompilationEvent(
              type: CompilationEventType.error,
              message: e.message ?? 'Compiler execution failed',
              timestamp: DateTime.now(),
            ),
          );
          controller.add(
            CompilationEvent(
              type: CompilationEventType.finished,
              message: 'Compilation failed.',
              timestamp: DateTime.now(),
              exitCode: 1,
            ),
          );
          controller.close();
        } catch (e) {
          controller.add(
            CompilationEvent(
              type: CompilationEventType.error,
              message: e.toString(),
              timestamp: DateTime.now(),
            ),
          );
          controller.add(
            CompilationEvent(
              type: CompilationEventType.finished,
              message: 'Compilation failed.',
              timestamp: DateTime.now(),
              exitCode: 1,
            ),
          );
          controller.close();
        }
      },
      onCancel: () {
        eventSubscription?.cancel();
        cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancelCompilation');
    } catch (_) {}
  }

  /// Helper to parse diagnostic lines
  static CompilationEvent? parseDiagnosticLine(String line) {
    final match = _gccDiagnosticRegex.firstMatch(line.trim());
    if (match == null) return null;

    final file = match.namedGroup('file');
    final lineStr = match.namedGroup('line');
    final colStr = match.namedGroup('col');
    final typeStr = match.namedGroup('type')?.toLowerCase() ?? 'error';
    final msg = match.namedGroup('msg') ?? line;

    final isWarning = typeStr == 'warning';

    return CompilationEvent(
      type: isWarning ? CompilationEventType.warning : CompilationEventType.error,
      message: msg,
      timestamp: DateTime.now(),
      file: file,
      line: lineStr != null ? int.tryParse(lineStr) : null,
      column: colStr != null ? int.tryParse(colStr) : null,
    );
  }
}
