import 'package:flutter/material.dart';
import '../models/map_settings.dart';
import '../models/map_hotspot.dart';
import '../services/directus_service.dart';
import 'missions_page.dart';
import 'forum_page.dart';
import 'library_page.dart';
import 'profile_page.dart';
import 'land_selection_page.dart';

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> {
  MapSettings? _mapSettings;
  List<MapHotspot> _hotspots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    final settings = await DirectusService.getMapSettings();
    final hotspots = await DirectusService.getMapHotspots();
    setState(() {
      _mapSettings = settings;
      _hotspots = hotspots;
      _isLoading = false;
    });
  }

  void _handleHotspotTap(MapHotspot hotspot) {
    switch (hotspot.actionType) {
      case 'forum':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ForumPage()));
        break;
      case 'missions':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const MissionsPage()));
        break;
      case 'library':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryPage()));
        break;
      case 'profile':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هنوز برای "${hotspot.title}" کاری تعریف نشده است.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_mapSettings == null) return const Scaffold(body: Center(child: Text('تنظیمات نقشه یافت نشد.')));

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black, // 💡 پس‌زمینه اختصاصی
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // ۱. تصویر پس‌زمینه از دیتابیس
          Positioned.fill(
            child: Image.network(
              _mapSettings!.backgroundImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1E1E2C),
                child: const Center(child: Icon(Icons.broken_image, color: Colors.white30, size: 50)),
              ),
            ),
          ),

          // ۲. نقاط قابل کلیک از دیتابیس
          ..._hotspots.map((hotspot) {
            return Positioned(
              top: screenSize.height * hotspot.yPos,
              left: screenSize.width * hotspot.xPos,
              child: GestureDetector(
                onTap: () => _handleHotspotTap(hotspot),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: hotspot.iconUrl != null && hotspot.iconUrl!.isNotEmpty
                      ? ClipOval(child: Image.network(hotspot.iconUrl!, fit: BoxFit.cover))
                      : null,
                ),
              ),
            );
          }),

          // 💡 دکمه بازگشت به صفحه انتخاب سرزمین
          Positioned(
            top: 40,
            right: 20,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LandSelectionPage()),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}