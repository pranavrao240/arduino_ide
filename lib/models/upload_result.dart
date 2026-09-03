class UploadResult {
  const UploadResult({
    required this.success,
    required this.message,
    this.durationMs = 0,
    this.totalBytes = 0,
    this.chipName,
    this.macAddress,
  });

  final bool success;
  final String message;
  final int durationMs;
  final int totalBytes;
  final String? chipName;
  final String? macAddress;
}
