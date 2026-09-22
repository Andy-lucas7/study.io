class Metric {
  final String? id;
  final String date; // Formato AAAA-MM-DD
  final int studyMinutes;
  final int pauses;
  final String environment;

  Metric({
    this.id,
    required this.date,
    required this.studyMinutes,
    required this.pauses,
    required this.environment,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'studyMinutes': studyMinutes,
      'pauses': pauses,
      'environment': environment,
    };
  }

  factory Metric.fromMap(Map<String, dynamic> map) {
    return Metric(
      id: map['id']?.toString(),
      date: map['date'] ?? '',
      studyMinutes: map['studyMinutes'] ?? 0,
      pauses: map['pauses'] ?? 0,
      environment: map['environment'] ?? '',
    );
  }

  factory Metric.fromDoc(dynamic doc) {
    return Metric.fromMap(doc);
  }
}
