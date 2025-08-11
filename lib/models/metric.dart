import 'package:cloud_firestore/cloud_firestore.dart';

class Metric {
  final String? id;
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

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'studyMinutes': studyMinutes,
      'pauses': pauses,
      'environment': environment,
    };
  }

  factory Metric.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Metric(
      id: doc.id,
      date: data['date'] ?? '',
      studyMinutes: data['studyMinutes'] ?? 0,
      pauses: data['pauses'] ?? 0,
      environment: data['environment'] ?? '',
    );
  }

  final CollectionReference _metricCollection = FirebaseFirestore.instance.collection('metrics');

  Future<void> save() async {
    if (id == null) {
      await _metricCollection.add(toMap());
    } else {
      await _metricCollection.doc(id).set(toMap());
    }
  }

  Future<void> delete() async {
    if (id != null) {
      await _metricCollection.doc(id).delete();
    }
  }
}