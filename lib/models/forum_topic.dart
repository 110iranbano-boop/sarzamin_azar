class ForumTopic {
  final int id;
  final String title;
  final String content;
  final int creatorId;
  final String createdAt;
  final String? updatedAt; // تاریخ ویرایش (اگر ویرایش شده باشد)
  final String? minRank;
  final int? minFlames;
  final int? minFeathers;
  final bool isClosed;

  ForumTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.creatorId,
    required this.createdAt,
    this.updatedAt,
    this.minRank,
    this.minFlames,
    this.minFeathers,
    this.isClosed = false,
  });

  factory ForumTopic.fromJson(Map<String, dynamic> json) {
    return ForumTopic(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      creatorId: json['creator_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      minRank: json['min_rank'],
      minFlames: json['min_flames'],
      minFeathers: json['min_feathers'],
      isClosed: json['is_closed'] ?? false,
    );
  }
}