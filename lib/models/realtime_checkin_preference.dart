/// Preference payload for `/api/NotificationPreference/realtime-checkin`.
/// Parses common camelCase / PascalCase shapes from the backend.
class RealtimeCheckinPreference {
  final bool enabled;

  const RealtimeCheckinPreference({required this.enabled});

  static bool _readBool(Map<String, dynamic> json) {
    final v = json['enabled'] ??
        json['Enabled'] ??
        json['isEnabled'] ??
        json['IsEnabled'] ??
        json['realtimeCheckIn'] ??
        json['RealtimeCheckIn'] ??
        json['realtimeCheckin'] ??
        json['value'] ??
        json['Value'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  factory RealtimeCheckinPreference.fromJson(Map<String, dynamic> json) {
    return RealtimeCheckinPreference(enabled: _readBool(json));
  }

  /// Body for PUT; backend typically accepts camelCase JSON.
  Map<String, dynamic> toJson() => {'enabled': enabled};
}
