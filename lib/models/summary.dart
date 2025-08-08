import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Summary {
  final String? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String description;
  String? audioUrl;
  String? audioPath;

  Summary({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.description,
    this.audioUrl,
    this.audioPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'audioUrl': audioUrl,
    };
  }

  factory Summary.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Summary(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      description: data['description'] ?? '',
      audioUrl: data['audioUrl'],
    );
  }

  final CollectionReference _summaryCollection = FirebaseFirestore.instance
      .collection('summaries');

  Future<void> save() async {
    if (id == null) {
      await _summaryCollection.add(toMap());
    } else {
      await _summaryCollection.doc(id).set(toMap());
    }
  }

  Future<void> delete() async {
    if (id != null) {
      if (audioUrl != null && audioUrl!.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.refFromURL(audioUrl!);
        await storageRef.delete();
      }
      await _summaryCollection.doc(id).delete();
    }
  }

  static Future<String> uploadAudioFile(File audioFile, String fileName) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('summary_audios')
        .child(fileName);
    final uploadTask = await ref.putFile(audioFile);
    final url = await ref.getDownloadURL();
    return url;
  }
}
