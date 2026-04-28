class FingerprintDevice {
  final String id;
  final String deviceIdentifier;
  final String name;
  final String? location;
  final String status;
  final bool isOnline;
  final bool isActive;
  final String? lastSeenAt;

  FingerprintDevice({
    required this.id,
    required this.deviceIdentifier,
    required this.name,
    this.location,
    this.status = 'active',
    this.isOnline = false,
    this.isActive = true,
    this.lastSeenAt,
  });

  factory FingerprintDevice.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString().trim() ?? '';
    final rawLocation = json['location']?.toString().trim() ?? '';
    final rawStatus = json['status']?.toString();
    final isActive = json['isActive'] as bool? ?? rawStatus != 'inactive';
    final lastSeenAt = json['lastSeenAt']?.toString();

    return FingerprintDevice(
      id: json['id']?.toString() ?? '',
      deviceIdentifier: json['deviceIdentifier']?.toString() ?? '',
      name: rawName.isNotEmpty ? rawName : 'Unnamed Device',
      location: rawLocation.isNotEmpty ? rawLocation : null,
      status: rawStatus ?? (isActive ? 'active' : 'inactive'),
      isOnline: json['isOnline'] as bool? ?? lastSeenAt != null,
      isActive: isActive,
      lastSeenAt: lastSeenAt,
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
      'isActive': isActive,
      if (lastSeenAt != null) 'lastSeenAt': lastSeenAt,
    };
  }
}
