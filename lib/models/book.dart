class Book {
  final int id;
  final String title;
  final String author;
  final String? publisher;
  final int? publishYear;
  final int? pageCount;
  final String? coverImage;
  final String? description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.publisher,
    this.publishYear,
    this.pageCount,
    this.coverImage,
    this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'] ?? 'بدون عنوان',
      author: json['author'] ?? 'نویسنده ناشناس',
      publisher: json['publisher'],
      publishYear: json['publish_year'],
      pageCount: json['page_count'],
      coverImage: json['cover_image'],
      description: json['description'],
    );
  }
}