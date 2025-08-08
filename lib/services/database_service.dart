import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _collection = 'tasks';

  // Inicialização (compatibilidade)
  static Future<void> init() async {
    return;
  }

  // Obtem stream de tasks em tempo real para uma data específica (normalizada)
  static Stream<List<Task>> streamTasksByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _firestore
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: dayStart.toIso8601String())
        .where('date', isLessThan: dayEnd.toIso8601String())
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data()..['id'] = doc.id))
            .toList());
  }

  static Future<List<Task>> getTasksByDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final snapshot = await _firestore
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: dayStart.toIso8601String())
        .where('date', isLessThan: dayEnd.toIso8601String())
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  static Stream<List<Task>> streamAllTasks() {
    return _firestore.collection(_collection).orderBy('date').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data()..['id'] = doc.id))
            .toList());
  }

  static Future<List<Task>> getTasks() async {
    final snapshot = await _firestore.collection(_collection).orderBy('date').get();
    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  static Future<void> insertTask(Task task) async {
    final data = task.toMap();
    data.remove('id');
    await _firestore.collection(_collection).add(data);
  }

  static Future<void> updateTask(Task task) async {
    if (task.id == null) throw Exception("Task ID is null, cannot update.");
    final data = task.toMap();
    data.remove('id');
    await _firestore.collection(_collection).doc(task.id.toString()).update(data);
  }

  static Future<void> deleteTask(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  static Future<void> updateTaskTime(String taskId, int? pomodoroCount, int? timeSpent) async {
    final docRef = _firestore.collection(_collection).doc(taskId);
    final updates = <String, dynamic>{};

    if (pomodoroCount != null) updates['pomodoroCount'] = pomodoroCount;
    if (timeSpent != null) updates['timeSpent'] = timeSpent;

    await docRef.update(updates);
  }

  static Future<Task?> getTaskById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Task.fromMap(doc.data()!..['id'] = doc.id);
    }
    return null;
  }
}
