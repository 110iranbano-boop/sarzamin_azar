import 'package:flutter/material.dart';
import '../services/directus_service.dart';
import '../models/mission.dart';
import 'mission_detail_page.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});
  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  late Future<List<Mission>> _missionsFuture;

  @override
  void initState() {
    super.initState();
    _missionsFuture = DirectusService.getMissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // 💡 شفاف
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('مأموریت‌ها'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Mission>>(
        future: _missionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطا: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }
          final missions = snapshot.data ?? [];
          if (missions.isEmpty) {
            return const Center(child: Text('هنوز مأموریتی ثبت نشده', style: TextStyle(color: Colors.white70)));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              final m = missions[index];
              return Card(
                color: const Color(0xFF2A2A3B).withValues(alpha: 0.9),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
                  title: Text(m.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${m.category} • ${m.flamesReward} شعله', style: const TextStyle(color: Colors.white54)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MissionDetailPage(mission: m)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}