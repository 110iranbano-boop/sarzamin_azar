import 'package:flutter/material.dart';
import '../models/forum_topic.dart';
import '../services/directus_service.dart';
import '../services/user_service.dart';
import 'forum_topic_detail_page.dart';
import 'create_forum_topic_page.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  List<ForumTopic> _topics = [];
  bool _isLoading = true;
  int? _currentUserId;
  int _userFeathers = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await UserService.getUserId();
    if (userId != null) {
      final profile = await UserService.getUserProfile(userId);
      final topics = await DirectusService.getForumTopics();
      setState(() {
        _currentUserId = userId;
        _userFeathers = profile?['phoenix_feathers'] ?? 0;
        _topics = topics;
        _isLoading = false;
      });
    }
  }

  void _createTopic() async {
    if (_userFeathers < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای ساخت تاپیک باید حداقل ۲ پر ققنوس داشته باشید!'), backgroundColor: Colors.red),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateForumTopicPage()),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 💡 شفاف
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('تالار گفتگو'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
              ? const Center(child: Text('هنوز تاپیکی ساخته نشده است.', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 80),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final topic = _topics[index];
                    return Card(
                      color: const Color(0xFF2A2A3B).withValues(alpha: 0.9),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          topic.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text(
                              topic.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('ایجاد: ${topic.createdAt.substring(0, 10)}', style: const TextStyle(fontSize: 10, color: Colors.white30)),
                                if (topic.updatedAt != null) ...[
                                  const SizedBox(width: 10),
                                  Text('ویرایش: ${topic.updatedAt!.substring(0, 10)}', style: const TextStyle(fontSize: 10, color: Colors.orangeAccent)),
                                ],
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ForumTopicDetailPage(topic: topic)),
                          ).then((_) => _loadData());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTopic,
        backgroundColor: const Color(0xFF6B4EE6),
        child: const Icon(Icons.add),
      ),
    );
  }
}