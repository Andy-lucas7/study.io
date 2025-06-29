class Task {
  int? id;
  String title;
  String description;
  String date;
  int priority;
  bool completed;
  DateTime? startTime;
  DateTime? endTime;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.priority,
    this.completed = false,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date,
        'priority': priority,
        'completed': completed ? 1 : 0,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        date: map['date'],
        priority: map['priority'],
        completed: map['completed'] == 1,
        startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
        endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      );

  int getStudyMinutes() {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!).inMinutes;
    }
    return 0;
  }
}