class MapHotspot {
  final int id;
  final String title;
  final double xPos;
  final double yPos;
  final String actionType; // forum, missions, library, profile, location
  final String? iconUrl;
  final bool isActive;

  MapHotspot({
    required this.id,
    required this.title,
    required this.xPos,
    required this.yPos,
    required this.actionType,
    this.iconUrl,
    required this.isActive,
  });

  factory MapHotspot.fromJson(Map<String, dynamic> json) {
    return MapHotspot(
      id: json['id'],
      title: json['title'] ?? '',
      xPos: (json['x_pos'] as num?)?.toDouble() ?? 0.0,
      yPos: (json['y_pos'] as num?)?.toDouble() ?? 0.0,
      actionType: json['action_type'] ?? '',
      iconUrl: json['icon_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}