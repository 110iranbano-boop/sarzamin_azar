import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'main_screen.dart';

class LandSelectionPage extends StatefulWidget {
  const LandSelectionPage({super.key});

  @override
  State<LandSelectionPage> createState() => _LandSelectionPageState();
}

class _LandSelectionPageState extends State<LandSelectionPage> {
  String _backgroundImageUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final url = await SettingsService.getValue('land_selection_image', '');
    setState(() {
      _backgroundImageUrl = url;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _backgroundImageUrl.isNotEmpty
                ? Image.network(
                    _backgroundImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black,
                      child: const Center(child: Text('تصویر پس‌زمینه یافت نشد', style: TextStyle(color: Colors.white54))),
                    ),
                  )
                : Container(color: Colors.black),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.32,
            left: MediaQuery.of(context).size.width * 0.15,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              child: Container(
                width: 150,
                height: 200,
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}