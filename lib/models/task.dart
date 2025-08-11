import 'package:cloud_firestore/cloud_firestore.dart';

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
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'priority': priority,
      'completed': completed,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return Task(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: parseDate(map['date']),
      priority: map['priority'] ?? 0,
      completed: map['completed'] ?? false,
      startTime: parseNullableDate(map['startTime']),
      endTime: parseNullableDate(map['endTime']),
    );
  }

  factory Task.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] is Timestamp ? (data['date'] as Timestamp).toDate() : DateTime.now(),
      priority: data['priority'] ?? 0,
      completed: data['completed'] ?? false,
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : null,
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
    );
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
