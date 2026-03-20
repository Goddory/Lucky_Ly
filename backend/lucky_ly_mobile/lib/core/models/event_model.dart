class EventModel {
  final String id;
  final String title;
  final DateTime date;
  final String type;
  final String? userId;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.userId,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      date: DateTime.parse(json['date']),
      type: json['type'] ?? 'personal_note',
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}
