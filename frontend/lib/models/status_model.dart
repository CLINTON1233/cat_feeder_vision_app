class StatusModel {
  final String cooldown;

  StatusModel({required this.cooldown});

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(cooldown: json['cooldown']?.toString() ?? "UNKNOWN");
  }
}
