class BookComment {
  final int id;
  final int bookId;
  final int userId;
  final String commentText;
  final int? parentId;
  final String createdAt;

  BookComment({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.commentText,
    this.parentId,
    required this.createdAt,
  });

  factory BookComment.fromJson(Map<String, dynamic> json) {
    return BookComment(
      id: json['id'],
      bookId: json['book_id'],
      userId: json['user_id'],
      commentText: json['comment_text'] ?? '',
      parentId: json['parent_id'],
      createdAt: json['created_at'] ?? '',
    );
  }
}