class Task {
  final String? id;
  final String title;
  final String description;
  final DateTime date;
  final int priority;
  final bool completed;
  final DateTime? startTime;
  final DateTime? endTime;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.priority,
    this.completed = false,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'priority': priority,
      'completed': completed ? 1 : 0,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      priority: map['priority'] ?? 0,
      completed: (map['completed'] == 1) || (map['completed'] == true),
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }

  factory Task.fromDoc(dynamic doc) {
    return Task.fromMap(doc);
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    int? priority,
    bool? completed,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  int getStudyMinutes() {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!).inMinutes;
    }
    return 0;
  }
}
