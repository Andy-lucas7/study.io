class Summary {
  final String id;
  final String title;
  final String description;
  final String content;
  final DateTime createdAt;

  Summary({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Summary.fromMap(Map<String, dynamic> map) {
    return Summary(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
