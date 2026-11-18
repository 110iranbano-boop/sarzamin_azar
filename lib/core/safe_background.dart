import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SafeBackground extends StatefulWidget {
  final String settingKey;
  final Widget child;
  final Color fallbackColor;

  const SafeBackground({
    super.key,
    required this.settingKey,
    required this.child,
    this.fallbackColor = const Color(0xFF1E1E2C),
  });

  @override
  State<SafeBackground> createState() => _SafeBackgroundState();
}

class _SafeBackgroundState extends State<SafeBackground> {
  String _imageUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final url = await SettingsService.getValue(widget.settingKey, '');
    setState(() {
      _imageUrl = url;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Container(color: widget.fallbackColor);
    
    return Stack(
      children: [
        // اگر عکس وجود داشت، به عنوان پس‌زمینه نمایش بده
        if (_imageUrl.isNotEmpty)
          Positioned.fill(
            child: Image.network(
              _imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: widget.fallbackColor),
            ),
          )
        else
          Positioned.fill(child: Container(color: widget.fallbackColor)),
        
        // یک لایه تاریک برای اینکه متن‌ها روی عکس خوانا باشن
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        
        // محتوای اصلی صفحه
        widget.child,
      ],
    );
  }
}