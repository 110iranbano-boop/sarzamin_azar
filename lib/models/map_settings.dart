class MapSettings {
  final int id;
  final String backgroundImageUrl;
  final bool isActive;

  MapSettings({
    required this.id,
    required this.backgroundImageUrl,
    required this.isActive,
  });

  factory MapSettings.fromJson(Map<String, dynamic> json) {
    return MapSettings(
      id: json['id'],
      backgroundImageUrl: json['background_image_url'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}