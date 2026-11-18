import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/book_comment.dart';
import '../services/directus_service.dart';
import '../services/user_service.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  List<BookComment> _comments = [];
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final comments = await DirectusService.getBookComments(widget.book.id);
    setState(() {
      _comments = comments;
      _isLoading = false;
    });
  }

  void _submitComment({int? parentId}) async {
    if (_commentController.text.trim().isEmpty) return;
    final userId = await UserService.getUserId();
    if (userId == null) return;

    final success = await DirectusService.addBookComment(
      widget.book.id,
      userId,
      _commentController.text.trim(),
      parentId: parentId,
    );

    if (success) {
      _commentController.clear();
      _loadComments();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در ثبت نظر!'), backgroundColor: Colors.red),
      );
    }
  }

  void _showReplyDialog(BookComment parentComment) {
    final replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('پاسخ به نظر'),
          content: TextField(
            controller: replyController,
            decoration: const InputDecoration(hintText: 'پاسخ خود را بنویسید...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (replyController.text.trim().isEmpty) return;
                
                final userId = await UserService.getUserId();
                if (userId == null) return;

                final success = await DirectusService.addBookComment(
                  widget.book.id,
                  userId,
                  replyController.text.trim(),
                  parentId: parentComment.id,
                );

                if (success) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadComments();
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('خطا در ثبت پاسخ!'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('ارسال'),
            ),
          ],
        );
      },
    );
  }

  // 💡 نمایش لیست قفسه‌ها برای انتخاب
  void _showAddToShelfDialog() async {
    final userId = await UserService.getUserId();
    if (userId == null) return;
    
    final shelves = await DirectusService.getUserBookshelves(userId);

    if (shelves.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شما هنوز هیچ قفسه‌ای نساخته‌اید!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('انتخاب قفسه'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: shelves.length,
              itemBuilder: (context, index) {
                final shelf = shelves[index];
                return ListTile(
                  title: Text(shelf.name),
                  leading: Icon(shelf.isPrivate ? Icons.lock : Icons.folder),
                  onTap: () async {
                    final success = await DirectusService.addBookToShelf(shelf.id, widget.book.id, userId);
                    if (!mounted) return;
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('کتاب به قفسه اضافه شد!'), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('خطا در افزودن کتاب!'), backgroundColor: Colors.red),
                      );
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 💡 تابع ساخت ویجت کامنت (با قابلیت تودرتو شدن)
  Widget _buildCommentCard(BookComment comment, {bool isReply = false}) {
    final replies = _comments.where((c) => c.parentId == comment.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: isReply ? const Color(0xFF22222E) : const Color(0xFF2A2A3B),
          margin: EdgeInsets.only(
            right: isReply ? 30.0 : 0.0,
            bottom: 10,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('کاربر ${comment.userId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 5),
                Text(comment.commentText, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 5),
                Text(comment.createdAt, style: const TextStyle(fontSize: 10, color: Colors.white30)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _showReplyDialog(comment),
                    child: const Text('پاسخ', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...replies.map((reply) => _buildCommentCard(reply, isReply: true)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainComments = _comments.where((c) => c.parentId == null).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: widget.book.coverImage != null && widget.book.coverImage!.isNotEmpty
                    ? Image.network(widget.book.coverImage!, height: 250, fit: BoxFit.cover)
                    : const Icon(Icons.book, size: 100, color: Colors.white30),
              ),
            ),
            const SizedBox(height: 20),
            Text('نویسنده: ${widget.book.author}', style: const TextStyle(fontSize: 18, color: Colors.white)),
            if (widget.book.publisher != null) Text('انتشارات: ${widget.book.publisher}', style: const TextStyle(color: Colors.white70)),
            if (widget.book.publishYear != null) Text('سال انتشار: ${widget.book.publishYear}', style: const TextStyle(color: Colors.white70)),
            if (widget.book.pageCount != null) Text('تعداد صفحات: ${widget.book.pageCount}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            const Text('توضیحات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 10),
            Text(widget.book.description ?? 'توضیحاتی ثبت نشده است.', style: const TextStyle(color: Colors.white, height: 1.5)),
            
            const SizedBox(height: 20),
            // 💡 دکمه افزودن به قفسه
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddToShelfDialog,
                icon: const Icon(Icons.add),
                label: const Text('افزودن به قفسه شخصی'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EE6),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            
            const Divider(height: 40, color: Colors.white24),
            
            const Text('نظرات کاربران:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'نظر خود را بنویسید...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _submitComment(),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (mainComments.isEmpty)
              const Text('هنوز نظری ثبت نشده است.', style: TextStyle(color: Colors.white30))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mainComments.length,
                itemBuilder: (context, index) {
                  return _buildCommentCard(mainComments[index]);
                },
              ),
          ],
        ),
      ),
    );
  }
}