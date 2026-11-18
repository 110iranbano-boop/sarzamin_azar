import 'package:flutter/material.dart';
import '../models/bookshelf.dart';
import '../models/book.dart';
import '../services/directus_service.dart';
import '../services/user_service.dart';
import 'book_detail_page.dart';

class MyLibraryPage extends StatefulWidget {
  const MyLibraryPage({super.key});

  @override
  State<MyLibraryPage> createState() => _MyLibraryPageState();
}

class _MyLibraryPageState extends State<MyLibraryPage> {
  List<Bookshelf> _shelves = [];
  Map<int, List<Book>> _shelfBooks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await UserService.getUserId();
    if (userId != null) {
      final shelves = await DirectusService.getUserBookshelves(userId);
      Map<int, List<Book>> booksMap = {};
      for (var shelf in shelves) {
        final books = await DirectusService.getBooksInShelf(shelf.id);
        booksMap[shelf.id] = books;
      }
      setState(() {
        _shelves = shelves;
        _shelfBooks = booksMap;
        _isLoading = false;
      });
    }
  }

  void _showAddShelfDialog() async {
    final userId = await UserService.getUserId();
    if (userId == null) return;
    
    if (_shelves.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شما حداکثر می‌توانید ۱۰ قفسه داشته باشید!'), backgroundColor: Colors.red),
      );
      return;
    }

    final nameController = TextEditingController();
    final topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ساخت قفسه جدید'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام قفسه')),
              TextField(controller: topicController, decoration: const InputDecoration(labelText: 'موضوع')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final success = await DirectusService.createBookshelf(
                  userId, 
                  nameController.text.trim(), 
                  topicController.text.trim(),
                );
                if (success) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('ساخت'),
            ),
          ],
        );
      },
    );
  }

  void _showEditShelfDialog(Bookshelf shelf) {
    final nameController = TextEditingController(text: shelf.name);
    final topicController = TextEditingController(text: shelf.topic ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ویرایش قفسه'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام قفسه')),
              TextField(controller: topicController, decoration: const InputDecoration(labelText: 'موضوع')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final success = await DirectusService.updateBookshelf(
                  shelf.id, 
                  nameController.text.trim(), 
                  topicController.text.trim(),
                );
                if (success) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        );
      },
    );
  }

  void _deleteShelf(Bookshelf shelf) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف قفسه'),
          content: Text('آیا از حذف قفسه "${shelf.name}" مطمئن هستید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final success = await DirectusService.deleteBookshelf(shelf.id);
                if (success) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('کتابخانه شخصی من'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddShelfDialog,
            tooltip: 'ساخت قفسه جدید',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shelves.isEmpty
              ? const Center(child: Text('شما هنوز هیچ قفسه‌ای نساخته‌اید.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _shelves.length,
                  itemBuilder: (context, index) {
                    final shelf = _shelves[index];
                    final booksInShelf = _shelfBooks[shelf.id] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عنوان قفسه و دکمه‌های ویرایش/حذف
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(shelf.isPrivate ? Icons.lock : Icons.folder, color: Colors.blueAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    shelf.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.white54),
                                onSelected: (value) {
                                  if (value == 'edit') _showEditShelfDialog(shelf);
                                  if (value == 'delete') _deleteShelf(shelf);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                                  const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ردیف افقی کتاب‌ها
                        SizedBox(
                          height: 210, // ارتفاع رو کمی بیشتر کردیم تا دکمه جا بشه
                          child: booksInShelf.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text('این قفسه خالی است.', style: TextStyle(color: Colors.white30)),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  itemCount: booksInShelf.length,
                                  itemBuilder: (context, bookIndex) {
                                    final book = booksInShelf[bookIndex];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
                                        ).then((_) => _loadData());
                                      },
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.only(left: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 💡 بخش عکس و دکمه حذف
                                            SizedBox(
                                              height: 160, // ارتفاع عکس
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: book.coverImage != null && book.coverImage!.isNotEmpty
                                                        ? Image.network(book.coverImage!, width: 120, height: 160, fit: BoxFit.cover)
                                                        : Container(width: 120, height: 160, color: Colors.grey[800], child: const Icon(Icons.book, color: Colors.white30)),
                                                  ),
                                                  // دکمه حذف
                                                  Positioned(
                                                    top: 5,
                                                    right: 5,
                                                    child: GestureDetector(
                                                      onTap: () async {
                                                        final userId = await UserService.getUserId();
                                                        if (userId == null) return;
                                                        
                                                        final success = await DirectusService.removeBookFromShelf(shelf.id, book.id, userId);
                                                        if (success) {
                                                          _loadData();
                                                          if (!mounted) return;
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('کتاب از قفسه حذف شد!'), backgroundColor: Colors.green),
                                                          );
                                                        }
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.black54,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              book.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            Text(
                                              book.author,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10, color: Colors.white54),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
    );
  }
}