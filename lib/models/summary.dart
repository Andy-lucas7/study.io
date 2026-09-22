import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class Summary {
  final String? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String description;
  String? audioPath;

  Summary({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.description,
    this.audioPath,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'audioPath': audioPath,
    };
  }

  factory Summary.fromMap(Map<String, dynamic> map) {
    return Summary(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      description: map['description'] ?? '',
      audioPath: map['audioPath'],
    );
  }

  factory Summary.fromDoc(dynamic doc) {
    return Summary.fromMap(doc);
  }

  static Future<String> saveAudioFileLocally(
    File audioFile,
    String fileName,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(appDir.path, 'summary_audios'));

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final targetPath = p.join(audioDir.path, fileName);
    await audioFile.copy(targetPath);
    return targetPath;
  }
}
