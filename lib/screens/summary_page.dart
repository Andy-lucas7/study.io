import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_io/core/app_config.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/settings_drawer.dart';
import '../models/summary.dart';

String _sanitizeFileName(String fileName) {
  return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
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
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('summaries');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        setState(() {
          _summaries = jsonList.map((json) {
            final summary = Summary.fromMap(json);
            if (json['audioPath'] != null) {
              summary.audioPath = json['audioPath'];
            }
            return summary;
          }).toList();
        });
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/summaries.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        setState(() {
          _summaries = jsonList.map((json) {
            final summary = Summary.fromMap(json);
            if (json['audioPath'] != null) {
              summary.audioPath = json['audioPath'];
            }
            return summary;
          }).toList();
        });
      }
    }
  }

  Future<void> _saveSummaries() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_summaries.map((s) => s.toMap()).toList());
      await prefs.setString('summaries', jsonString);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/summaries.json');
      final jsonString = jsonEncode(_summaries.map((s) => s.toMap()).toList());
      await file.writeAsString(jsonString);
    }
  }

  Future<void> _exportSummary(Summary summary) async {
    try {
      String textFilePath;
      if (kIsWeb) {
        textFilePath = 'summary_${_sanitizeFileName(summary.title)}.txt';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        textFilePath =
            '${directory.path}/${_sanitizeFileName(summary.title)}.txt';
      }
      String textContent =
          '''Título: ${summary.title}
Descrição: ${summary.description}
Data de criação: ${summary.createdAt.toString()}

Conteúdo:
${summary.content}''';
      List<XFile> filesToShare = [];
      if (!kIsWeb) {
        final textFile = File(textFilePath);
        await textFile.writeAsString(textContent);
        filesToShare.add(XFile(textFilePath));
      }

      if (summary.audioPath != null &&
          !kIsWeb &&
          await File(summary.audioPath!).exists()) {
        filesToShare.add(XFile(summary.audioPath!));
      }

      await Share.shareXFiles(
        filesToShare,
        text: kIsWeb ? textContent : 'Resumo: ${summary.title}',
        subject: summary.title,
      );

      if (!kIsWeb && await File(textFilePath).exists()) {
        await File(textFilePath).delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resumo compartilhado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao compartilhar: $e')));
      }
    }
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
        content: const Text(
          'Deseja apagar este resumo? Esta ação não pode ser desfeita.',
        ),
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

      if (summary.audioPath != null && !kIsWeb) {
        final audioFile = File(summary.audioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resumo apagado com sucesso')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(12),
          child: Container(),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Resumos', style: AppConfig().montserratTitle.copyWith()),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset('assets/icon/Icon_fill.png'),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SettingsDrawer(),
      body: _summaries.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.summarize, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum resumo criado ainda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toque no + para criar seu primeiro resumo',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: _summaries.map((summary) {
                  return GestureDetector(
                    onTap: () => _showSummaryDetails(summary),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppConfig.tile,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  summary.title.isEmpty
                                      ? 'Sem título'
                                      : summary.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (summary.audioPath != null)
                                const Icon(
                                  Icons.mic,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                            ],
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
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _showCreateEditDialog(summary: summary),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => _exportSummary(summary),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
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
        child: const Icon(HugeIcons.strokeRoundedNoteAdd, color: Colors.white),
      ),
    );
  }

  void _showSummaryDetails(Summary summary) {
    showDialog(
      context: context,
      builder: (context) {
        return _SummaryDetailsDialog(summary: summary);
      },
    );
  }
}

class _SummaryDetailsDialog extends StatefulWidget {
  final Summary summary;
  const _SummaryDetailsDialog({required this.summary});
  @override
  State<_SummaryDetailsDialog> createState() => _SummaryDetailsDialogState();
}

class _SummaryDetailsDialogState extends State<_SummaryDetailsDialog> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      if (widget.summary.audioPath != null) {
        await _audioPlayer.play(DeviceFileSource(widget.summary.audioPath!));
        setState(() => _isPlaying = true);
        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() => _isPlaying = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.summary.title.isEmpty
                      ? 'Sem ttulo'
                      : widget.summary.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.summary.description.isNotEmpty) ...[
                  Text(
                    widget.summary.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  widget.summary.content,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (widget.summary.audioPath != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Áudio gravado',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'FECHAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _audioFileNameController = TextEditingController();

  final Record _audioRecorder = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    if (widget.summary != null) {
      _titleController.text = widget.summary!.title;
      _descriptionController.text = widget.summary!.description;
      _contentController.text = widget.summary!.content;
      _audioFilePath = widget.summary!.audioPath;
      if (_audioFilePath != null) {
        _audioFileNameController.text = _audioFilePath!.split('/').last;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _audioFileNameController.dispose();
    _stopRecordingIfActive();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _stopRecordingIfActive() async {
    if (_isRecording) {
      await _audioRecorder.stop();
    }
    _audioRecorder.dispose();
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  Future<bool> _checkAudioPermission() async {
    if (kIsWeb) return true;
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _toggleRecording() async {
    if (kIsWeb) return;
    final hasPermission = await _checkAudioPermission();
    if (!hasPermission) return;

    try {
      if (!_isRecording) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = _audioFileNameController.text.trim().isEmpty
            ? 'audio_summary_${DateTime.now().millisecondsSinceEpoch}.m4a'
            : '${_sanitizeFileName(_audioFileNameController.text.trim())}.m4a';
        final newAudioPath = '${dir.path}/$fileName';

        if (await _audioRecorder.hasPermission()) {
          await _audioRecorder.start(
            path: newAudioPath,
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
          );
          setState(() {
            _isRecording = true;
            _audioFilePath = newAudioPath;
            _audioFileNameController.text = fileName;
          });
        }
      } else {
        await _audioRecorder.stop();
        setState(() => _isRecording = false);
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_audioFilePath != null) {
        await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
        setState(() => _isPlaying = true);
        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() => _isPlaying = false);
        });
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white.withOpacity(0.7))
            : null,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.summary == null ? 'NOVO RESUMO' : 'EDITAR RESUMO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    _titleController,
                    'Título',
                    icon: HugeIcons.strokeRoundedBook02,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _descriptionController,
                    'Descrição (opcional)',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _contentController,
                    'Conteúdo (texto)',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),
                  if (!kIsWeb) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _toggleRecording,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRecording
                                      ? Colors.red
                                      : Colors.white.withOpacity(0.2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                icon: Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                ),
                                label: Text(_isRecording ? 'Parar' : 'Gravar'),
                              ),
                              if (_audioFilePath != null)
                                ElevatedButton.icon(
                                  onPressed: _togglePlayback,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isPlaying
                                        ? Colors.orange
                                        : Colors.white.withOpacity(0.2),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                  ),
                                  label: Text(_isPlaying ? 'Pausar' : 'Ouvir'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCELAR',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final newSummary = Summary(
                            id:
                                widget.summary?.id ??
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            title: _titleController.text.trim().isEmpty
                                ? 'Resumo'
                                : _titleController.text.trim(),
                            description: _descriptionController.text.trim(),
                            content: _contentController.text.trim(),
                            createdAt:
                                widget.summary?.createdAt ?? DateTime.now(),
                          );
                          newSummary.audioPath = _audioFilePath;
                          widget.onSave(newSummary);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'SALVAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
