enum CompilationEventType {
  started,
  command,
  stdout,
  stderr,
  warning,
  error,
  success,
  finished,
}

class CompilationEvent {
  const CompilationEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.file,
    this.line,
    this.column,
    this.exitCode,
    this.sketchBytes,
    this.maxSketchBytes,
    this.globalVarBytes,
    this.maxGlobalVarBytes,
  });

  final CompilationEventType type;
  final String message;
  final DateTime timestamp;
  final String? file;
  final int? line;
  final int? column;
  final int? exitCode;
  final int? sketchBytes;
  final int? maxSketchBytes;
  final int? globalVarBytes;
  final int? maxGlobalVarBytes;

  factory CompilationEvent.fromMap(Map<dynamic, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'stdout';
    final type = CompilationEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => CompilationEventType.stdout,
    );

    return CompilationEvent(
      type: type,
      message: map['message'] as String? ?? '',
      timestamp: DateTime.now(),
      file: map['file'] as String?,
      line: map['line'] as int?,
      column: map['column'] as int?,
      exitCode: map['exitCode'] as int?,
      sketchBytes: map['sketchBytes'] as int?,
      maxSketchBytes: map['maxSketchBytes'] as int?,
      globalVarBytes: map['globalVarBytes'] as int?,
      maxGlobalVarBytes: map['maxGlobalVarBytes'] as int?,
    );
  }
}
