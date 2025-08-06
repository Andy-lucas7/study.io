import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:study_io/models/summary.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:study_io/core/app_config.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/settings_drawer.dart';

// Utility function for sanitizing file names
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

  Future<void> _saveSummaries() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/summaries.json');
    final jsonString = jsonEncode(_summaries.map((s) => s.toMap()).toList());
    await file.writeAsString(jsonString);
  }

  Future<void> _exportSummary(Summary summary) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final textFile = File(
        '${directory.path}/${_sanitizeFileName(summary.title)}.txt',
      );

      String textContent =
          '''Título: ${summary.title}
Descrição: ${summary.description}
Data de criação: ${summary.createdAt.toString()}

Conteúdo:
${summary.content}''';

      await textFile.writeAsString(textContent);

      List<XFile> filesToShare = [XFile(textFile.path)];

      if (summary.audioPath != null &&
          await File(summary.audioPath!).exists()) {
        filesToShare.add(XFile(summary.audioPath!));
      }

      await Share.shareXFiles(
        filesToShare,
        text: 'Resumo: ${summary.title}',
        subject: summary.title,
      );

      if (await textFile.exists()) {
        await textFile.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resumo compartilhado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e')),
        );
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

      if (summary.audioPath != null) {
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
        child: const Icon(Icons.add, color: Colors.white),
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
    if (_isPlaying) {
      _audioPlayer.stop();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (widget.summary.audioPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.summary.audioPath!));
        setState(() => _isPlaying = true);
        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reproduzir áudio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportSummary() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final textFile = File(
        '${directory.path}/${_sanitizeFileName(widget.summary.title)}.txt',
      );

      String textContent =
          '''Título: ${widget.summary.title}
Descrição: ${widget.summary.description}
Data de criação: ${widget.summary.createdAt.toString()}

Conteúdo:
${widget.summary.content}''';

      await textFile.writeAsString(textContent);

      List<XFile> filesToShare = [XFile(textFile.path)];

      if (widget.summary.audioPath != null &&
          await File(widget.summary.audioPath!).exists()) {
        filesToShare.add(XFile(widget.summary.audioPath!));
      }

      await Share.shareXFiles(
        filesToShare,
        text: 'Resumo: ${widget.summary.title}',
        subject: widget.summary.title,
      );

      if (await textFile.exists()) {
        await textFile.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resumo compartilhado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.summary.title.isEmpty ? 'Resumo' : widget.summary.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.summary.description.isNotEmpty) ...[
              const Text(
                'Descrição:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.summary.description),
              const SizedBox(height: 16),
            ],
            if (widget.summary.content.isNotEmpty) ...[
              const Text(
                'Conteúdo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(widget.summary.content),
              const SizedBox(height: 16),
            ],
            if (widget.summary.audioPath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.audiotrack, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Áudio: ${widget.summary.audioPath!.split('/').last}\nSalvo em: ${widget.summary.audioPath}',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _togglePlayback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlaying
                            ? Colors.orange
                            : Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Pausar' : 'Reproduzir'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Criado em: ${widget.summary.createdAt.day}/${widget.summary.createdAt.month}/${widget.summary.createdAt.year} às ${widget.summary.createdAt.hour.toString().padLeft(2, '0')}:${widget.summary.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _exportSummary();
          },
          icon: const Icon(Icons.share),
          label: const Text('Compartilhar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
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
  bool _hasUnsavedAudio = false;

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

  Future<bool> _checkAudioPermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    } else {
      status = await Permission.microphone.request();
      return status.isGranted;
    }
  }

  Future<void> _toggleRecording() async {
    final hasPermission = await _checkAudioPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de microfone negada')),
      );
      return;
    }

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
            _hasUnsavedAudio = true;
            _audioFileNameController.text = fileName;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Gravação iniciada em: $newAudioPath'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
        });

        if (path != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Áudio salvo em: $path')),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na gravação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioFilePath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
        setState(() => _isPlaying = true);
        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reproduzir áudio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAudioAndContent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Deseja apagar o conteúdo de texto e áudio? Esta ação não pode ser desfeita.',
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
      if (_isRecording) {
        await _audioRecorder.stop();
        setState(() => _isRecording = false);
      }

      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
      }

      if (_audioFilePath != null) {
        final audioFile = File(_audioFilePath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }

      setState(() {
        _contentController.clear();
        _audioFilePath = null;
        _hasUnsavedAudio = false;
        _audioFileNameController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conteúdo e áudio apagados'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isRecording) {
          await _audioRecorder.stop();
          setState(() => _isRecording = false);
        }
        if (_isPlaying) {
          await _audioPlayer.stop();
          setState(() => _isPlaying = false);
        }
        return true;
      },
      child: AlertDialog(
        title: Text(widget.summary == null ? 'Novo Resumo' : 'Editar Resumo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _audioFileNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do arquivo de áudio (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: resumo_audio',
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRecording
                        ? Colors.red.shade200
                        : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      size: 32,
                      color: _isRecording ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(
                            _isRecording ? 'Parar gravação' : 'Gravar áudio',
                          ),
                        ),
                        if (_audioFilePath != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _togglePlayback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isPlaying
                                  ? Colors.orange
                                  : Theme.of(context).colorScheme.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                            label: Text(_isPlaying ? 'Pausar' : 'Reproduzir'),
                          ),
                        ],
                      ],
                    ),
                    if (_audioFilePath != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.audiotrack,
                              color: Colors.green.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Áudio: ${_audioFilePath!.split('/').last}\nSalvo em: $_audioFilePath',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo (texto)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              if (_contentController.text.isNotEmpty || _audioFilePath != null)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _deleteAudioAndContent,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Limpar conteúdo e áudio'),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_isRecording) {
                await _audioRecorder.stop();
                setState(() => _isRecording = false);
              }
              if (_isPlaying) {
                await _audioPlayer.stop();
                setState(() => _isPlaying = false);
              }
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.trim().isEmpty &&
                  _contentController.text.trim().isEmpty &&
                  _audioFilePath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Insira pelo menos um título, texto ou grave um áudio',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (_isRecording) {
                await _audioRecorder.stop();
                setState(() => _isRecording = false);
              }

              if (_isPlaying) {
                await _audioPlayer.stop();
                setState(() => _isPlaying = false);
              }

              final newSummary = Summary(
                id: widget.summary?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text.trim().isEmpty
                    ? 'Resumo ${DateTime.now().day}/${DateTime.now().month}'
                    : _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                content: _contentController.text.trim(),
                createdAt: widget.summary?.createdAt ?? DateTime.now(),
              );

              newSummary.audioPath = _audioFilePath;

              widget.onSave(newSummary);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.summary == null
                        ? 'Resumo criado com sucesso!'
                        : 'Resumo atualizado com sucesso!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}