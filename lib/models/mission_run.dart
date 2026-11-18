class MissionRun {
  final int? id;
  final int userId;
  final int missionId;
  final String status;

  MissionRun({
    this.id,
    required this.userId,
    required this.missionId,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'mission_id': missionId,
      'status': status,
    };
  }
}