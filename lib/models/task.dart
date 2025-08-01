class Task {
  final int? id;
  final String title;
  final String description;
  final String date;
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
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'priority': priority,
      'completed': completed ? 1 : 0,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      date: map['date'],
      priority: map['priority'],
      completed: map['completed'] == 1,
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }

  int getStudyMinutes() {
    if (startTime == null) return 0;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!).inMinutes;
  }
}