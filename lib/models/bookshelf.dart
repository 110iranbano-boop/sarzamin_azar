class Bookshelf {
  final int id;
  final int userId;
  final String name;
  final String? topic;
  final bool isPrivate;

  Bookshelf({
    required this.id,
    required this.userId,
    required this.name,
    this.topic,
    this.isPrivate = false,
  });

  factory Bookshelf.fromJson(Map<String, dynamic> json) {
    return Bookshelf(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? 'قفسه بدون نام',
      topic: json['topic'],
      isPrivate: json['is_private'] ?? false,
    );
  }
}