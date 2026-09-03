enum TerminalLogType {
  command,
  info,
  warning,
  error,
  success,
}

class TerminalLog {
  const TerminalLog({
    required this.message,
    required this.type,
    required this.timestamp,
    this.file,
    this.line,
    this.column,
  });

  final String message;
  final TerminalLogType type;
  final DateTime timestamp;
  final String? file;
  final int? line;
  final int? column;

  factory TerminalLog.command(String cmd) => TerminalLog(
        message: cmd,
        type: TerminalLogType.command,
        timestamp: DateTime.now(),
      );

  factory TerminalLog.info(String msg) => TerminalLog(
        message: msg,
        type: TerminalLogType.info,
        timestamp: DateTime.now(),
      );

  factory TerminalLog.warning(String msg, {String? file, int? line, int? column}) =>
      TerminalLog(
        message: msg,
        type: TerminalLogType.warning,
        timestamp: DateTime.now(),
        file: file,
        line: line,
        column: column,
      );

  factory TerminalLog.error(String msg, {String? file, int? line, int? column}) =>
      TerminalLog(
        message: msg,
        type: TerminalLogType.error,
        timestamp: DateTime.now(),
        file: file,
        line: line,
        column: column,
      );

  factory TerminalLog.success(String msg) => TerminalLog(
        message: msg,
        type: TerminalLogType.success,
        timestamp: DateTime.now(),
      );
}
