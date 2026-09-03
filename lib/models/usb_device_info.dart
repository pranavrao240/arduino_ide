class UsbDeviceInfo {
  const UsbDeviceInfo({
    required this.name,
    required this.vendorId,
    required this.productId,
    required this.deviceId,
    this.productName,
    this.manufacturerName,
    this.chipType = 'Unknown',
    this.hasPermission = false,
  });

  final String name;
  final int vendorId;
  final int productId;
  final int deviceId;
  final String? productName;
  final String? manufacturerName;
  final String chipType;
  final bool hasPermission;

  String get displayName =>
      productName?.isNotEmpty == true ? productName! : name;

  factory UsbDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return UsbDeviceInfo(
      name: map['name'] as String? ?? map['deviceName'] as String? ?? 'USB Device',
      vendorId: (map['vendorId'] as int?) ?? 0,
      productId: (map['productId'] as int?) ?? 0,
      deviceId: (map['deviceId'] as int?) ?? 0,
      productName: map['productName'] as String?,
      manufacturerName: map['manufacturerName'] as String?,
      chipType: map['chipType'] as String? ?? 'Unknown',
      hasPermission: map['hasPermission'] as bool? ?? false,
    );
  }
}
