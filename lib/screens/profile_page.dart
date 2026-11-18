import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/directus_service.dart';
import '../services/settings_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userProfile;
  List<dynamic> _history = [];
  bool _isLoading = true;
  bool _showUsername = true;
  bool _showMbti = true;
  bool _showHistory = true;
  
  String _profileFrameUrl = '';
  String _flameIconUrl = '';
  String _featherIconUrl = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await UserService.getUserId();
    if (userId != null) {
      final profile = await UserService.getUserProfile(userId);
      final history = await DirectusService.getUserHistory(userId);
      
      final frameUrl = await SettingsService.getValue('profile_frame_image', '');
      final flameUrl = await SettingsService.getValue('flame_icon_url', '');
      final featherUrl = await SettingsService.getValue('feather_icon_url', '');

      setState(() {
        _userProfile = profile;
        _history = history;
        _profileFrameUrl = frameUrl;
        _flameIconUrl = flameUrl;
        _featherIconUrl = featherUrl;
        _showUsername = profile?['show_username'] ?? true;
        _showMbti = profile?['show_mbti'] ?? true;
        _showHistory = profile?['show_history'] ?? true;
        _isLoading = false;
      });
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _userProfile?['name'] ?? '');
    final usernameController = TextEditingController(text: _userProfile?['username'] ?? '');
    final mbtiController = TextEditingController(text: _userProfile?['mbti'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ویرایش پروفایل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی')),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'نام کاربری')),
                TextField(controller: mbtiController, decoration: const InputDecoration(labelText: 'تایپ شخصیتی (مثلاً INTJ)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                final userId = await UserService.getUserId();
                if (userId != null) {
                  await UserService.updateUserProfile(userId, {
                    'name': nameController.text,
                    'username': usernameController.text,
                    'mbti': mbtiController.text,
                  });
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

  Future<void> _updatePrivacy(String field, bool value) async {
    final userId = await UserService.getUserId();
    if (userId == null) return;
    setState(() {
      if (field == 'username') _showUsername = value;
      if (field == 'mbti') _showMbti = value;
      if (field == 'history') _showHistory = value;
    });
  }

  void _convertFlames() async {
    final userId = await UserService.getUserId();
    if (userId == null) return;
    bool success = await UserService.convertFlamesToFeather(userId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تبدیل با موفقیت انجام شد!'), backgroundColor: Colors.green));
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شما حداقل ۵۰ شعله نیاز دارید!'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_userProfile == null) return const Scaffold(body: Center(child: Text('خطا در دریافت اطلاعات')));

    final flames = _userProfile!['flames'] ?? 0;
    final feathers = _userProfile!['phoenix_feathers'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('شخصیت من'), 
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditDialog),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
        child: Column(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  if (_profileFrameUrl.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        _profileFrameUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(_userProfile!['name'] ?? 'کاربر', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            if (_showUsername) Text('@${_userProfile!['username'] ?? 'user'}', style: const TextStyle(color: Colors.white54)),
            if (_showMbti && _userProfile!['mbti'] != null) 
              Chip(label: Text(_userProfile!['mbti']), backgroundColor: Colors.purpleAccent.withValues(alpha: 0.3)),
            
            const SizedBox(height: 20),
            
            const Text('نشان و مدال‌ها', style: TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 10),
            Container(
              height: 80,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(15)),
              child: const Center(child: Text('مدال‌ها و نشان‌های دریافتی در اینجا نمایش داده می‌شوند', style: TextStyle(color: Colors.white30))),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('شعله‌ها', '$flames', Colors.orangeAccent, Icons.local_fire_department, _flameIconUrl),
                _buildStatCard('پر ققنوس', '$feathers', Colors.redAccent, Icons.auto_awesome, _featherIconUrl),
              ],
            ),
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _convertFlames,
              child: const Text('تبدیل ۵۰ شعله به ۱ پر ققنوس'),
            ),

            const SizedBox(height: 30),

            const Text('تنظیمات نمایش پروفایل', style: TextStyle(fontSize: 18, color: Colors.white70)),
            SwitchListTile(
              title: const Text('نمایش نام کاربری به دیگران'),
              value: _showUsername,
              onChanged: (val) => _updatePrivacy('username', val),
            ),
            SwitchListTile(
              title: const Text('نمایش تایپ شخصیتی (MBTI)'),
              value: _showMbti,
              onChanged: (val) => _updatePrivacy('mbti', val),
            ),
            SwitchListTile(
              title: const Text('نمایش سابقه فعالیت‌ها'),
              value: _showHistory,
              onChanged: (val) => _updatePrivacy('history', val),
            ),

            const SizedBox(height: 30),

            if (_showHistory) ...[
              const Text('سابقه فعالیت‌ها', style: TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 10),
              if (_history.isEmpty)
                const Text('هنوز فعالیتی ثبت نشده است.', style: TextStyle(color: Colors.white30))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.blueAccent),
                      title: Text(item['title'] ?? 'فعالیت', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(item['date'] ?? '', style: const TextStyle(color: Colors.white54)),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, String iconUrl) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          iconUrl.isNotEmpty
              ? Image.network(iconUrl, width: 30, height: 30, errorBuilder: (context, error, stackTrace) => Icon(icon, color: color, size: 30))
              : Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}