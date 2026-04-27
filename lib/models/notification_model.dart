class NotificationModel {
  final String title;
  final String message;
  final String type;
  final String category;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const NotificationModel({
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    this.metadata,
    required this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Info',
      category: json['category']?.toString() ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'category': category,
      if (metadata != null) 'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
