import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';

import '../notifiers/theme_notifier.dart';
import '../widgets/settings_drawer.dart';

class Summary {
  String id;
  String title;
  String description;
  String content;
  DateTime createdAt;

  Summary({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  List<Summary> _summaries = [];

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/summaries.json');
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _summaries = jsonList.map((json) => Summary.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveSummaries() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/summaries.json');
    final jsonString = jsonEncode(_summaries.map((s) => s.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<void> _exportSummary(Summary summary) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${summary.title}.txt');
    await file.writeAsString(summary.content);
    await Share.shareFiles([file.path], text: summary.title);
  }

  void _showCreateEditDialog({Summary? summary}) {
    showDialog(
      context: context,
      builder: (context) => SummaryDialog(
        summary: summary,
        onSave: (newSummary) {
          setState(() {
            if (summary == null) {
              _summaries.add(newSummary);
            } else {
              final index = _summaries.indexWhere((s) => s.id == summary.id);
              if (index != -1) _summaries[index] = newSummary;
            }
          });
          _saveSummaries();
        },
      ),
    );
  }

  Future<void> _deleteSummary(Summary summary) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja apagar este resumo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _summaries.removeWhere((s) => s.id == summary.id);
      });
      await _saveSummaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final currentTheme = themeNotifier.themeMode == ThemeMode.light
        ? themeNotifier.lightTheme
        : themeNotifier.darkTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Resumos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),
      body: _summaries.isEmpty
          ? const Center(child: Text('Nenhum resumo criado ainda.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _summaries.length,
              itemBuilder: (context, index) {
                final summary = _summaries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: const Color.fromARGB(255, 35, 42, 56),
                    title: Text(summary.title),
                    subtitle: Text(
                      summary.description.isEmpty
                          ? 'Sem descrição'
                          : summary.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showCreateEditDialog(summary: summary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _exportSummary(summary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSummary(summary),
                        ),
                      ],
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(summary.title),
                          content: SingleChildScrollView(
                            child: Text(summary.content),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fechar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditDialog(),
        backgroundColor: currentTheme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// --------------------------------------------
// Widget SummaryDialog para criar/editar resumo
// --------------------------------------------

class SummaryDialog extends StatefulWidget {
  final Summary? summary;
  final void Function(Summary) onSave;

  const SummaryDialog({super.key, this.summary, required this.onSave});

  @override
  State<SummaryDialog> createState() => _SummaryDialogState();
}

class _SummaryDialogState extends State<SummaryDialog> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lastRecognized = '';

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    if (widget.summary != null) {
      _titleController.text = widget.summary!.title;
      _descriptionController.text = widget.summary!.description;
      _contentController.text = widget.summary!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _toggleRecording() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de microfone negada')),
        );
      }
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'notListening') {
            setState(() => _isListening = false);
          } else if (val == 'listening') {
            setState(() => _isListening = true);
          }
        },
        onError: (val) {
          debugPrint('Speech error: $val');
          setState(() => _isListening = false);
        },
      );

      if (available) {
        _lastRecognized = '';
        _speech.listen(
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          onResult: (val) {
            final recognized = val.recognizedWords.trim();
            if (recognized.isEmpty || recognized == _lastRecognized) return;

            final newPart = recognized.replaceFirst(_lastRecognized, '').trim();

            if (newPart.isNotEmpty) {
              _contentController.text = _contentController.text.isEmpty
                  ? newPart
                  : '${_contentController.text} $newPart';
              _contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentController.text.length),
              );
            }

            _lastRecognized = recognized;
          },
          cancelOnError: true,
        );
        setState(() => _isListening = true);
      }
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.summary == null ? 'Novo Resumo' : 'Editar Resumo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _toggleRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
              label: Text(
                _isListening ? 'Parar' : 'Gravar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Conteúdo'),
              maxLines: 5,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _contentController.clear();
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Apagar conteúdo',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_isListening) {
              await _speech.stop();
              setState(() => _isListening = false);
            }
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.isEmpty ||
                _contentController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Título e conteúdo são obrigatórios'),
                ),
              );
              return;
            }

            final newSummary = Summary(
              id: widget.summary?.id ?? DateTime.now().toIso8601String(),
              title: _titleController.text,
              description: _descriptionController.text,
              content: _contentController.text,
              createdAt: widget.summary?.createdAt ?? DateTime.now(),
            );

            widget.onSave(newSummary);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
