import 'package:flutter/material.dart';
import '../models/forum_topic.dart';
import '../services/directus_service.dart';
import '../services/user_service.dart';

class CreateForumTopicPage extends StatefulWidget {
  const CreateForumTopicPage({super.key});

  @override
  State<CreateForumTopicPage> createState() => _CreateForumTopicPageState();
}

class _CreateForumTopicPageState extends State<CreateForumTopicPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String? _selectedMinRank;
  int? _minFlames;
  int? _minFeathers;
  bool _isClosed = false;
  bool _isSubmitting = false;

  final List<String> _ranks = ['آذرگان', 'آذرین', 'آذرمهر'];

  void _submitTopic() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان و متن تاپیک را وارد کنید!'), backgroundColor: Colors.red),
      );
      return;
    }

    final userId = await UserService.getUserId();
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    final topic = ForumTopic(
      id: 0,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      creatorId: userId,
      createdAt: '',
      minRank: _selectedMinRank,
      minFlames: _minFlames,
      minFeathers: _minFeathers,
      isClosed: _isClosed,
    );

    final success = await DirectusService.createForumTopic(topic);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true); // برگشت با نتیجه موفقیت
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در ساخت تاپیک!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(title: const Text('ساخت تاپیک جدید'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'عنوان تاپیک', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _contentController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'متن تاپیک', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 20),
            const Text('شرایط نظردهی (اختیاری):', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            
            // انتخاب حداقل رتبه
            DropdownButtonFormField<String>(
              initialValue: _selectedMinRank,
              decoration: const InputDecoration(labelText: 'حداقل رتبه', labelStyle: TextStyle(color: Colors.white54)),
              dropdownColor: const Color(0xFF2A2A3B),
              style: const TextStyle(color: Colors.white),
              items: [
                const DropdownMenuItem(value: null, child: Text('همه')),
                ..._ranks.map((rank) => DropdownMenuItem(value: rank, child: Text(rank))),
              ],
              onChanged: (val) => setState(() => _selectedMinRank = val),
            ),
            const SizedBox(height: 10),
            
            // حداقل شعله
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'حداقل شعله', labelStyle: TextStyle(color: Colors.white54)),
              onChanged: (val) => _minFlames = int.tryParse(val),
            ),
            const SizedBox(height: 10),
            
            // حداقل پر ققنوس
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'حداقل پر ققنوس', labelStyle: TextStyle(color: Colors.white54)),
              onChanged: (val) => _minFeathers = int.tryParse(val),
            ),
            const SizedBox(height: 15),

            // بستن نظردهی
            SwitchListTile(
              title: const Text('بستن نظردهی برای همه', style: TextStyle(color: Colors.white70)),
              value: _isClosed,
              activeThumbColor: const Color(0xFF6B4EE6),
              onChanged: (val) => setState(() => _isClosed = val),
            ),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTopic,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EE6)),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ساخت تاپیک', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}