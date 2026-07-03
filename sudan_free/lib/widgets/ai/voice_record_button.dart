import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:io';
import '../../services/ai_service.dart';

class VoiceRecordButton extends StatefulWidget {
  final Function(String text) onResult;

  const VoiceRecordButton({super.key, required this.onResult});

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = Directory.systemTemp;
        _recordedFilePath = '${tempDir.path}/voice_request.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordedFilePath!,
        );
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      if (path != null) {
        final text = await AiService().transcribeAudioToServiceRequest(path);
        widget.onResult(text);
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onLongPress: _startRecording,
      onLongPressUp: _stopRecording,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: _isRecording
              ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
              : null,
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}
