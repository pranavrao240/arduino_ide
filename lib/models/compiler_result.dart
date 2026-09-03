class CompileError {
  const CompileError({
    required this.file,
    required this.line,
    required this.column,
    required this.message,
    this.snippet,
    this.hint,
  });

  final String file;
  final int line;
  final int column;
  final String message;
  final String? snippet;
  final String? hint;

  String get formattedMessage => '$file:$line:$column: error: $message';
}

class CompileWarning {
  const CompileWarning({
    required this.file,
    required this.line,
    required this.column,
    required this.message,
    this.snippet,
  });

  final String file;
  final int line;
  final int column;
  final String message;
  final String? snippet;

  String get formattedMessage => '$file:$line:$column: warning: $message';
}

class CompilationResult {
  const CompilationResult({
    required this.success,
    this.exitCode = 0,
    this.durationMs = 0,
    this.errors = const [],
    this.warnings = const [],
    this.sketchBytes = 0,
    this.maxSketchBytes = 1310720,
    this.globalVarBytes = 0,
    this.maxGlobalVarBytes = 327680,
  });

  final bool success;
  final int exitCode;
  final int durationMs;
  final List<CompileError> errors;
  final List<CompileWarning> warnings;
  final int sketchBytes;
  final int maxSketchBytes;
  final int globalVarBytes;
  final int maxGlobalVarBytes;

  double get sketchPercentage => maxSketchBytes > 0
      ? ((sketchBytes / maxSketchBytes) * 100).clamp(0.0, 100.0)
      : 0.0;

  double get globalVarPercentage => maxGlobalVarBytes > 0
      ? ((globalVarBytes / maxGlobalVarBytes) * 100).clamp(0.0, 100.0)
      : 0.0;
}

/// Backwards compatibility alias
typedef CompilerError = CompileError;
typedef CompileResult = CompilationResult;
