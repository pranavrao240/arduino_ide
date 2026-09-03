import 'dart:async';
import 'package:arduino_ide/models/compilation_event.dart';
import 'package:arduino_ide/models/editor_file_model.dart';

abstract class ArduinoCompiler {
  /// Checks whether the compiler/toolchain is installed on the host device
  Future<bool> isInstalled();

  /// Prepares or initializes the compiler toolchain paths
  Future<void> initialize();

  /// Compiles and verifies the sketch asynchronously, streaming live compilation events
  Stream<CompilationEvent> verify({
    required String code,
    required String fqbn,
    String filename = 'Sketch.ino',
    List<EditorFile> allFiles = const [],
    String boardName = 'ESP32 Dev Module',
  });

  /// Cancels an active compilation process
  Future<void> cancel();
}
