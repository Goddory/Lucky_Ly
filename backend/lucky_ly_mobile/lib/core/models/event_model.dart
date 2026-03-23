class EventModel {
  final String id;
  final String title;
  final DateTime date;
  final String type;
  final String? userId;
  final String? note;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.userId,
    this.note,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    
    try {
      final rawDate = json['date'];
      if (rawDate != null) {
        if (rawDate is String) {
          // Try to parse ISO 8601 format
          parsedDate = DateTime.parse(rawDate);
        } else if (rawDate is DateTime) {
          parsedDate = rawDate;
        } else {
          print('Warning: Unexpected date type: ${rawDate.runtimeType}');
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    return EventModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      date: parsedDate,
      type: json['type'] ?? 'personal_note',
      userId: json['user_id']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String(),
      'type': type,
      if (note != null) 'note': note,
    };
  }
}
