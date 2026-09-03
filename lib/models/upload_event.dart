enum UploadEventType {
  started,
  usbDetecting,
  usbPermissionRequired,
  usbConnected,
  compiling,
  compilationFinished,
  connecting,
  chipDetected,
  erasing,
  writing,
  progress,
  verifying,
  resetting,
  success,
  warning,
  error,
  finished,
}

class UploadEvent {
  const UploadEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.progress,
    this.writtenBytes,
    this.totalBytes,
    this.chipName,
    this.macAddress,
    this.exitCode,
  });

  final UploadEventType type;
  final String message;
  final DateTime timestamp;
  final double? progress;
  final int? writtenBytes;
  final int? totalBytes;
  final String? chipName;
  final String? macAddress;
  final int? exitCode;

  factory UploadEvent.fromMap(Map<dynamic, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'info';
    final type = UploadEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => UploadEventType.started,
    );

    return UploadEvent(
      type: type,
      message: map['message'] as String? ?? '',
      timestamp: DateTime.now(),
      progress: (map['progress'] as num?)?.toDouble(),
      writtenBytes: map['writtenBytes'] as int?,
      totalBytes: map['totalBytes'] as int?,
      chipName: map['chipName'] as String?,
      macAddress: map['macAddress'] as String?,
      exitCode: map['exitCode'] as int?,
    );
  }
}
