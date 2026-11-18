class Mission {
  final int id;
  final String title;
  final String description;
  final String category;
  final int flamesReward;
  final bool requiresApproval;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.flamesReward,
    required this.requiresApproval,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'بدون عنوان',
      description: json['description'] ?? 'بدون توضیحات',
      category: json['category'] ?? 'عمومی',
      flamesReward: json['flames_reward'] ?? 0,
      requiresApproval: json['requires_approval'] ?? false,
    );
  }
}