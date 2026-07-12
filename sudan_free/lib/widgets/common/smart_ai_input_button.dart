import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sudan_free/services/ai_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SmartAiInputButton extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onEnhance;
  final bool isEnhancing;
  final bool isArabic;

  const SmartAiInputButton({
    super.key,
    required this.controller,
    required this.onEnhance,
    required this.isEnhancing,
    this.isArabic = true,
  });

  @override
  State<SmartAiInputButton> createState() => _SmartAiInputButtonState();
}

class _SmartAiInputButtonState extends State<SmartAiInputButton> {
  bool _isRecording = false;
  bool _isProcessingVoice = false;
  AudioRecorder? _audioRecorder;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _audioRecorder?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _startRecording() async {
    try {
      _audioRecorder = AudioRecorder();
      if (await _audioRecorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/ai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder!.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.isArabic ? 'يرجى السماح بالوصول إلى الميكروفون' : 'Please allow microphone access')),
          );
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      debugPrint('Recording error: $e');
    }
  }

  Future<void> _stopAndProcessRecording() async {
    if (_audioRecorder == null) return;
    try {
      final path = await _audioRecorder!.stop();
      setState(() {
        _isRecording = false;
        _isProcessingVoice = true;
      });
      
      if (path != null) {
        final transcribed = await AiService().transcribeAudioToServiceRequest(path);
        if (transcribed.isNotEmpty && !transcribed.startsWith('لم أتمكن') && !transcribed.startsWith('حدث خطأ')) {
          widget.controller.text = transcribed;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(transcribed), backgroundColor: Colors.red.shade400),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Voice processing error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingVoice = false);
      }
      _audioRecorder?.dispose();
      _audioRecorder = null;
    }
  }

  Future<void> _cancelRecording() async {
    if (_audioRecorder != null) {
      await _audioRecorder!.stop();
      await _audioRecorder!.dispose();
      _audioRecorder = null;
    }
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecording) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat()).fadeIn(duration: 500.ms).fadeOut(duration: 500.ms),
            const SizedBox(width: 12),
            Text(
              widget.isArabic ? 'جاري التسجيل...' : 'Recording...',
              style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: _cancelRecording,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              onPressed: _stopAndProcessRecording,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      );
    }

    if (_isProcessingVoice || widget.isEnhancing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            ),
            const SizedBox(width: 8),
            Text(
              _isProcessingVoice
                  ? (widget.isArabic ? 'جاري تحويل الصوت...' : 'Processing voice...')
                  : (widget.isArabic ? 'جاري التحسين...' : 'Enhancing...'),
              style: const TextStyle(color: Colors.amber),
            ),
          ],
        ),
      );
    }

    final isEmpty = widget.controller.text.trim().isEmpty;

    return TextButton.icon(
      onPressed: isEmpty ? _startRecording : widget.onEnhance,
      icon: Icon(
        isEmpty ? Icons.mic : Icons.auto_awesome,
        color: isEmpty ? Colors.blue : Colors.amber,
        size: 20,
      ),
      label: Text(
        isEmpty
            ? (widget.isArabic ? 'تسجيل بالصوت' : 'Voice Record')
            : (widget.isArabic ? 'المساعد Home ✨' : 'Home Assistant ✨'),
        style: TextStyle(
          color: isEmpty ? Colors.blue : Colors.amber,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: (isEmpty ? Colors.blue : Colors.amber).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
