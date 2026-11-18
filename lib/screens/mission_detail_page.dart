import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../models/mission_run.dart';
import '../services/directus_service.dart';
import '../services/user_service.dart';

class MissionDetailPage extends StatefulWidget {
  final Mission mission;
  const MissionDetailPage({super.key, required this.mission});

  @override
  State<MissionDetailPage> createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends State<MissionDetailPage> {
  bool _isSubmitting = false;
  bool _isChecking = true;
  bool _alreadyCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkIfCompleted();
  }

  // چک کردن اینکه آیا کاربر قبلا این مأموریت رو انجام داده یا نه
  Future<void> _checkIfCompleted() async {
    final userId = await UserService.getUserId();
    if (userId != null) {
      final hasCompleted = await DirectusService.checkMissionRun(userId, widget.mission.id);
      setState(() {
        _alreadyCompleted = hasCompleted;
        _isChecking = false;
      });
    }
  }

  void _submitMission() async {
    setState(() => _isSubmitting = true);

    final int? userId = await UserService.getUserId();
    if (userId == null) return;

    final run = MissionRun(userId: userId, missionId: widget.mission.id);
    final success = await DirectusService.submitMission(run);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      final reward = widget.mission.flamesReward;
      await UserService.addFlamesToUser(userId, reward);
      await DirectusService.logReward(
        userId: userId,
        missionId: widget.mission.id,
        amount: reward,
        reason: 'پاداش انجام مأموریت: ${widget.mission.title}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('مأموریت ثبت شد و $reward شعله دریافت کردید!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در ثبت!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(title: Text(widget.mission.title), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('توضیحات: ${widget.mission.description}', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            Text('پاداش: ${widget.mission.flamesReward} شعله', style: const TextStyle(color: Colors.orangeAccent)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _alreadyCompleted) ? null : _submitMission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alreadyCompleted ? Colors.grey : const Color(0xFF6B4EE6),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _alreadyCompleted ? 'شما این مأموریت را انجام داده‌اید' : 'انجام دادم!',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}