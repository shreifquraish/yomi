class Note {
  int? id;
  String title;
  String content;
  DateTime timestamp;
  int color; // ARGB color integer

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.color = 0xFFFFFFFF, // Default white color
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'color': color,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      color: map['color'] ?? 0xFFFFFFFF,
    );
  }
}

