class FingerprintDevice {
  final String id;
  final String name;
  final String? location;
  final String status;
  final bool isOnline;

  FingerprintDevice({
    required this.id,
    required this.name,
    this.location,
    this.status = 'active',
    this.isOnline = false,
  });

  factory FingerprintDevice.fromJson(Map<String, dynamic> json) {
    return FingerprintDevice(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      location: json['location'],
      status: json['status'] ?? 'active',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (location != null) 'location': location,
      'status': status,
      'isOnline': isOnline,
    };
  }
}
