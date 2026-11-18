import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/land_selection_page.dart';
import 'services/user_service.dart';
import 'services/settings_service.dart';

void main() {
  runApp(const SarzaminAzarApp());
}

class SarzaminAzarApp extends StatefulWidget {
  const SarzaminAzarApp({super.key});

  @override
  State<SarzaminAzarApp> createState() => _SarzaminAzarAppState();
}

class _SarzaminAzarAppState extends State<SarzaminAzarApp> {
  Map<String, String> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // خواندن رنگ‌ها و پس‌زمینه سراسری
    final primaryColor = SettingsService.hexToColor(_settings['primary_color'] ?? '#6B4EE6');
    final backgroundColor = SettingsService.hexToColor(_settings['background_color'] ?? '#1E1E2C');
    final textColor = SettingsService.hexToColor(_settings['text_color'] ?? '#FFFFFF');
    final globalBgUrl = _settings['global_bg_image'] ?? '';

    return MaterialApp(
      title: 'سرزمین آذر',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fa', 'IR')],
      locale: const Locale('fa', 'IR'),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          surface: backgroundColor,
          onSurface: textColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: textColor,
          ),
        ),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            if (globalBgUrl.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  globalBgUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: backgroundColor),
                ),
              )
            else
              Positioned.fill(child: Container(color: backgroundColor)),
            
            // لایه تاریک برای خوانایی
            Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.5))),

            ?child,
          ],
        );
      },
      home: const LoginPage(),
    );
  }
}

// ==========================================
// صفحه لاگین
// ==========================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String _logoUrl = '';
  String _loginBgUrl = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final logoUrl = await SettingsService.getValue('login_logo_image', '');
    final bgUrl = await SettingsService.getValue('login_bg_image', '');
    setState(() {
      _logoUrl = logoUrl;
      _loginBgUrl = bgUrl;
    });
  }

  void _login() async {
    String mobile = _phoneController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً شماره موبایل خود را وارد کنید')),
      );
      return;
    }

    setState(() => _isLoading = true);
    var user = await UserService.findUser(mobile);
    user ??= await UserService.createUser(mobile);
    setState(() => _isLoading = false);

    if (user != null) {
      await UserService.saveUserId(user['id']);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LandSelectionPage()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در ورود! دوباره تلاش کنید.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          image: _loginBgUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(_loginBgUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {}, // جلوگیری از کرش
                )
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _logoUrl.isNotEmpty
                    ? Image.network(
                        _logoUrl,
                        height: 150,
                        width: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_fire_department, size: 80, color: Colors.orangeAccent),
                      )
                    : const Icon(Icons.local_fire_department, size: 80, color: Colors.orangeAccent),
                const SizedBox(height: 20),
                const Text('سرزمین آذر', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '۰۹۱۲۳۴۵۶۷۸۹',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.black26,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('ورود به سرزمین'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}