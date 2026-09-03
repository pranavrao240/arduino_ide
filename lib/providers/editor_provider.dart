import 'package:arduino_ide/controllers/editor_controller.dart';
import 'package:flutter_riverpod/legacy.dart';

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) => EditorNotifier(),
);
