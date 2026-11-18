import 'package:flutter/material.dart';
import '../models/forum_topic.dart';
import '../models/forum_reply.dart';
import '../services/directus_service.dart';
import '../services/user_service.dart';

class ForumTopicDetailPage extends StatefulWidget {
  final ForumTopic topic;
  const ForumTopicDetailPage({super.key, required this.topic});

  @override
  State<ForumTopicDetailPage> createState() => _ForumTopicDetailPageState();
}

class _ForumTopicDetailPageState extends State<ForumTopicDetailPage> {
  List<ForumReply> _replies = [];
  bool _isLoading = true;
  final TextEditingController _replyController = TextEditingController();
  bool _canReply = false;
  String? _replyErrorMessage;

  int? _currentUserId;
  String? _currentUserRank;
  int _currentUserFlames = 0;
  int _currentUserFeathers = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await UserService.getUserId();
    if (userId != null) {
      final profile = await UserService.getUserProfile(userId);
      final replies = await DirectusService.getForumReplies(widget.topic.id);
      setState(() {
        _currentUserId = userId;
        _currentUserRank = profile?['rank'] ?? 'آذرگان';
        _currentUserFlames = profile?['flames'] ?? 0;
        _currentUserFeathers = profile?['phoenix_feathers'] ?? 0;
        _replies = replies;
        _isLoading = false;
        _checkReplyPermission();
      });
    }
  }

  void _checkReplyPermission() {
    if (widget.topic.isClosed) {
      _canReply = false;
      _replyErrorMessage = 'نظردهی برای این تاپیک بسته شده است.';
      return;
    }
    if (widget.topic.minRank != null) {
      final rankOrder = {'آذرگان': 1, 'آذرین': 2, 'آذرمهر': 3};
      final userRankLevel = rankOrder[_currentUserRank] ?? 1;
      final requiredRankLevel = rankOrder[widget.topic.minRank] ?? 1;
      if (userRankLevel < requiredRankLevel) {
        _canReply = false;
        _replyErrorMessage = 'شما باید حداقل رتبه "${widget.topic.minRank}" را داشته باشید.';
        return;
      }
    }
    if (widget.topic.minFlames != null && _currentUserFlames < widget.topic.minFlames!) {
      _canReply = false;
      _replyErrorMessage = 'شما باید حداقل ${widget.topic.minFlames} شعله داشته باشید.';
      return;
    }
    if (widget.topic.minFeathers != null && _currentUserFeathers < widget.topic.minFeathers!) {
      _canReply = false;
      _replyErrorMessage = 'شما باید حداقل ${widget.topic.minFeathers} پر ققنوس داشته باشید.';
      return;
    }
    _canReply = true;
    _replyErrorMessage = null;
  }

  void _submitReply({int? parentId}) async {
    if (_replyController.text.trim().isEmpty) return;
    if (_currentUserId == null) return;
    final success = await DirectusService.createForumReply(
      widget.topic.id,
      _currentUserId!,
      _replyController.text.trim(),
      parentId: parentId,
    );
    if (success) {
      _replyController.clear();
      _loadData();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در ثبت نظر!'), backgroundColor: Colors.red),
      );
    }
  }

  void _showReplyDialog(ForumReply parentReply) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('پاسخ به نظر'),
          content: TextField(controller: replyController, decoration: const InputDecoration(hintText: 'پاسخ خود را بنویسید...'), maxLines: 3),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                if (replyController.text.trim().isEmpty) return;
                final success = await DirectusService.createForumReply(
                  widget.topic.id, 
                  _currentUserId!, 
                  replyController.text.trim(), 
                  parentId: parentReply.id,
                );
                if (success) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
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

  void _showEditDialog() {
    final titleController = TextEditingController(text: widget.topic.title);
    final contentController = TextEditingController(text: widget.topic.content);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ویرایش تاپیک'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان')),
                TextField(controller: contentController, maxLines: 5, decoration: const InputDecoration(labelText: 'متن')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
                final success = await DirectusService.updateForumTopic(widget.topic.id, titleController.text.trim(), contentController.text.trim());
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف تاپیک'),
          content: const Text('آیا از حذف این تاپیک مطمئن هستید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final success = await DirectusService.deleteForumTopic(widget.topic.id);
                if (success) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

    Widget _buildReplyCard(ForumReply reply, {bool isReply = false}) {
    final replies = _replies.where((r) => r.parentId == reply.id).toList();
    
    // چک کردن اینکه آیا کاربر اجازه حذف این نظر رو داره یا نه
    // (اگر نویسنده نظر باشه، یا ادمین (آیدی 1) باشه، یا سازنده تاپیک باشه)
    final bool canDelete = _currentUserId == reply.userId || 
                           _currentUserId == 1 || 
                           _currentUserId == widget.topic.creatorId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: isReply ? const Color(0xFF22222E) : const Color(0xFF2A2A3B),
          margin: EdgeInsets.only(right: isReply ? 40.0 : 0.0, bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('کاربر ${reply.userId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 5),
                Text(reply.content, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 5),
                Text(reply.createdAt.substring(0, 10), style: const TextStyle(fontSize: 10, color: Colors.white30)),
                
                // دکمه‌های پاسخ و حذف
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _showReplyDialog(reply),
                      child: const Text('پاسخ', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                    ),
                    if (canDelete)
                      TextButton.icon(
                        onPressed: () => _confirmDeleteReply(reply),
                        icon: const Icon(Icons.delete, size: 14, color: Colors.redAccent),
                        label: const Text('حذف', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // نمایش پاسخ‌ها (به صورت بازگشتی و تودرتو)
        ...replies.map((r) => _buildReplyCard(r, isReply: true)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainReplies = _replies.where((r) => r.parentId == null).toList();
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(widget.topic.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentUserId == widget.topic.creatorId)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') _showEditDialog();
                if (value == 'delete') _confirmDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('ویرایش تاپیک')),
                const PopupMenuItem(value: 'delete', child: Text('حذف تاپیک', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.topic.content, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('ایجاد شده در: ${widget.topic.createdAt.substring(0, 10)}', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  if (widget.topic.updatedAt != null)
                    Text('آخرین ویرایش: ${widget.topic.updatedAt!.substring(0, 10)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                  const Divider(height: 40, color: Colors.white24),
                  const Text('نظرات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 10),
                  if (mainReplies.isEmpty)
                    const Text('هنوز نظری ثبت نشده است.', style: TextStyle(color: Colors.white30))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mainReplies.length,
                      itemBuilder: (context, index) {
                        return _buildReplyCard(mainReplies[index]);
                      },
                    ),
                  const SizedBox(height: 20),
                  if (_canReply)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
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
                          onPressed: () => _submitReply(),
                        ),
                      ],
                    )
                  else if (_replyErrorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: Text(_replyErrorMessage!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
    );
  }
    // 💡 دیالوگ حذف نظر
  void _confirmDeleteReply(ForumReply reply) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف نظر'),
          content: const Text('آیا از حذف این نظر مطمئن هستید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final success = await DirectusService.deleteForumReply(reply.id);
                if (success) {
                  if (!mounted) return;
                  Navigator.pop(context); // بستن دیالوگ
                  _loadData(); // رفرش لیست نظرات
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('خطا در حذف نظر!'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }
}