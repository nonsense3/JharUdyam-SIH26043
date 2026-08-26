class ProblemModel {
  final String? id;
  final String? ticketNo;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String department;
  final String? duplicateOf;
  final String imageUrl;
  final String imagePath;
  final String address;
  final double latitude;
  final double longitude;
  final String reporterId;
  final String reporterName;
  final String status;
  final String? releasedTo;
  final DateTime? createdAt;

  ProblemModel({
    this.id,
    this.ticketNo,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.department,
    this.duplicateOf,
    required this.imageUrl,
    required this.imagePath,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.reporterId,
    this.reporterName = 'Citizen report · mobile app',
    this.status = 'submitted',
    this.releasedTo,
    this.createdAt,
  });

  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    return ProblemModel(
      id: json['id']?.toString(),
      ticketNo: json['ticket_no']?.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'low',
      department: json['department'] ?? '',
      duplicateOf: json['duplicate_of']?.toString(),
      imageUrl: json['image_url'] ?? '',
      imagePath: json['image_path'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      reporterId: json['reporter_id'] ?? '',
      reporterName: json['reporter_name'] ?? 'Citizen report · mobile app',
      status: json['status'] ?? 'submitted',
      releasedTo: json['released_to']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'department': department,
      if (duplicateOf != null) 'duplicate_of': duplicateOf,
      'image_url': imageUrl,
      'image_path': imagePath,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
    };
  }

  String get relativeTime {
    if (createdAt == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[createdAt!.month - 1];
      return '$month ${createdAt!.day}';
    }
  }

  String get shortAddress {
    if (address.length <= 50) return address;
    return '${address.substring(0, 47)}...';
  }
}
