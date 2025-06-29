class Metric {
  final int? id;
  final String date;
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

  factory Metric.fromMap(Map<String, dynamic> map) {
    return Metric(
      id: map['id'],
      date: map['date'],
      studyMinutes: map['studyMinutes'],
      pauses: map['pauses'],
      environment: map['environment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'studyMinutes': studyMinutes,
      'pauses': pauses,
      'environment': environment,
    };
  }
}
