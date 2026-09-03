import 'package:highlight/highlight.dart';
import 'package:highlight/languages/arduino.dart';
import 'package:highlight/languages/cpp.dart';

class EditorFile {
  const EditorFile({
    required this.name,
    required this.content,
    this.hasError = false,
    this.errorLine,
    this.cursorLine,
    this.sizeText,
    this.modifiedTimeText,
  });

  final String name;
  final String content;
  final bool hasError;
  final int? errorLine;
  final int? cursorLine;
  final String? sizeText;
  final String? modifiedTimeText;

  String get displaySize {
    if (sizeText != null && sizeText!.isNotEmpty) return sizeText!;
    final bytes = content.length;
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  String get displayModifiedTime => modifiedTimeText ?? 'Today, 14:30';

  String get extension => name.contains('.') ? name.split('.').last : '';

  Mode get languageMode {
    switch (extension.toLowerCase()) {
      case 'ino':
      case 'pde':
        return arduino;
      case 'h':
      case 'hpp':
      case 'cpp':
      case 'c':
      case 'cc':
      case 'cxx':
        return cpp;
      default:
        return arduino;
    }
  }

  EditorFile copyWith({
    String? name,
    String? content,
    bool? hasError,
    int? errorLine,
    int? cursorLine,
    String? sizeText,
    String? modifiedTimeText,
  }) {
    return EditorFile(
      name: name ?? this.name,
      content: content ?? this.content,
      hasError: hasError ?? this.hasError,
      errorLine: errorLine ?? this.errorLine,
      cursorLine: cursorLine ?? this.cursorLine,
      sizeText: sizeText ?? this.sizeText,
      modifiedTimeText: modifiedTimeText ?? this.modifiedTimeText,
    );
  }
}
