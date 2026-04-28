class FingerprintDevice {
  final String id;
  final String deviceIdentifier;
  final String name;
  final String? location;
  final String status;
  final bool isOnline;

  FingerprintDevice({
    required this.id,
    required this.deviceIdentifier,
    required this.name,
    this.location,
    this.status = 'active',
    this.isOnline = false,
  });

  factory FingerprintDevice.fromJson(Map<String, dynamic> json) {
    return FingerprintDevice(
      id: json['id']?.toString() ?? '',
      deviceIdentifier: json['deviceIdentifier']?.toString() ?? '',
      name: json['name'] ?? '',
      location: json['location'],
      status: json['status'] ?? 'active',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceIdentifier': deviceIdentifier,
      'name': name,
      if (location != null) 'location': location,
      'status': status,
      'isOnline': isOnline,
    };
  }
}
