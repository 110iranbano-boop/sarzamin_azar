class ForumReply {
  final int id;
  final int topicId;
  final int userId;
  final String content;
  final int? parentId; // 💡 این فیلد باید باشه
  final String createdAt;

  ForumReply({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.content,
    this.parentId,
    required this.createdAt,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    return ForumReply(
      id: json['id'],
      topicId: json['topic_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      content: json['content'] ?? '',
      parentId: json['parent_id'], // 💡 این خط باید باشه
      createdAt: json['created_at'] ?? '',
    );
  }
}