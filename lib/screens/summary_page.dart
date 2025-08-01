import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import '../notifiers/theme_notifier.dart';
import '../notifiers/environment_notifier.dart';
import '../widgets/settings_drawer.dart';
import 'package:study_io/styles.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Resumos', style: AppFonts().montserratTitle.copyWith()),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset('assets/icon/Icon_fill.png'),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),
      body: _summaries.isEmpty
          ? const Center(child: Text('Nenhum resumo criado ainda.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: _summaries.map((summary) {
                  return GestureDetector(
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.tile,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary.description.isEmpty
                                ? 'Sem descrição'
                                : summary.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white70,
                                ),
                                onPressed: () =>
                                    _showCreateEditDialog(summary: summary),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white70,
                                ),
                                onPressed: () => _exportSummary(summary),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteSummary(summary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEditDialog(),
        backgroundColor: currentTheme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

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
