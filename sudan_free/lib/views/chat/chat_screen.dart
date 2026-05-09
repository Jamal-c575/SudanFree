import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:timeago/timeago.dart' as timeago;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../profile/profile_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/job_provider.dart';
import '../../models/job_model.dart';
import '../../views/jobs/active_job_tracking_screen.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/linkable_text.dart';


class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  final bool autoOpenContractDialog;

  const ChatScreen({super.key, required this.chat, this.autoOpenContractDialog = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  DateTime? _recordStartTime;
  Timer? _typingTimer;
  bool _isMeTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<ChatProvider>().openChat(widget.chat, userId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTypingChanged(String value) {
    if (!_isMeTyping && value.isNotEmpty) {
      _isMeTyping = true;
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<ChatProvider>().setTypingStatus(userId, true);
      }
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isMeTyping) {
        _isMeTyping = false;
        final userId = context.read<AuthProvider>().user?.id;
        if (userId != null) {
          context.read<ChatProvider>().setTypingStatus(userId, false);
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final otherId = widget.chat.getOtherParticipantId(user.id);
    
    _messageController.clear();
    _onTypingChanged('');

    await context.read<ChatProvider>().sendMessage(
      senderId: user.id,
      senderName: user.name,
      receiverId: otherId,
      content: content,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null && mounted) {
      final auth = context.read<AuthProvider>();
      final chatProv = context.read<ChatProvider>();
      final user = auth.user;
      if (user == null) return;

      final otherId = widget.chat.getOtherParticipantId(user.id);

      await chatProv.sendImageMessage(
        senderId: user.id,
        senderName: user.name,
        receiverId: otherId,
        imageFile: File(image.path),
      );
    }
  }

  Future<void> _pickFile() async {
    // Temporarily disabled due to file_picker compilation issues
    /*
    final result = await fp.FilePicker.platform.pickFiles();
    // In some older or mismatched versions it might be fp.FilePicker.pickFiles();
    // wait I will replace it with the instance method if it's there? No, file_picker always has platform.
    // Wait, let's change it back to FilePicker.platform.pickFiles() without fp. but import it normally.
    
    if (result != null && result.files.single.path != null) {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      if (user == null) return;

      final otherId = widget.chat.getOtherParticipantId(user.id);

      await context.read<ChatProvider>().sendImageMessage(
        senderId: user.id,
        senderName: user.name,
        receiverId: otherId,
        imageFile: File(result.files.single.path!),
      );
    }
    */
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        
        setState(() {
          _isRecording = true;
          _recordStartTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null && _recordStartTime != null && mounted) {
        final duration = DateTime.now().difference(_recordStartTime!).inSeconds;
        if (duration < 1) return; // Ignore very short recordings

        final auth = context.read<AuthProvider>();
        final chatProv = context.read<ChatProvider>();
        final user = auth.user;
        if (user == null) return;

        final otherId = widget.chat.getOtherParticipantId(user.id);

        await chatProv.sendAudioMessage(
          senderId: user.id,
          senderName: user.name,
          receiverId: otherId,
          audioFile: File(path),
          duration: duration,
        );
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final user = authProvider.user;
    final messages = chatProvider.messages;
    final otherName = widget.chat.getOtherParticipantName(user?.id ?? '');
    final otherImage = widget.chat.getOtherParticipantImage(user?.id ?? '');
    final otherId = widget.chat.getOtherParticipantId(user?.id ?? '');
    final isOtherTyping = widget.chat.isTyping(otherId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(userId: otherId)),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: otherImage != null ? NetworkImage(otherImage) : null,
                child: otherImage == null ? Text(otherName.isNotEmpty ? otherName[0].toUpperCase() : '?') : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (isOtherTyping)
                      const Text('يكتب الآن...', style: TextStyle(fontSize: 12, color: AppColors.primary))
                    else
                      _buildOnlineStatus(otherId),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showContractBottomSheet(context),
            icon: const Icon(Icons.handshake, size: 22),
            tooltip: 'إنشاء عقد',
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يفضل استخدام واتساب أو الاتصال المباشر للتواصل، الدردشة هنا فقط لإنشاء وتنسيق العقود لضمان حقوقك.',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: messages.isEmpty && chatProvider.isLoading
                ? const LoadingIndicator()
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == user?.id;
                      return MessageBubble(message: message, isMe: isMe, chat: widget.chat);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!_isRecording) ...[
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: _showAttachmentOptions,
              ),
            ],
            Expanded(
              child: _isRecording
                  ? _buildRecordingIndicator()
                  : Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onTypingChanged,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        maxLines: null,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: FloatingActionButton(
                onPressed: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    _sendMessage();
                  }
                },
                mini: true,
                elevation: 2,
                backgroundColor: _isRecording ? Colors.red : AppColors.primary,
                child: Icon(
                  _isRecording 
                      ? Icons.mic 
                      : (_messageController.text.trim().isEmpty ? Icons.mic : Icons.send),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Row(
      children: [
        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        const Text('جاري التسجيل...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        const Spacer(),
        StreamBuilder<Duration>(
          stream: Stream.periodic(const Duration(seconds: 1), (count) => Duration(seconds: count)),
          builder: (context, snapshot) {
            final seconds = snapshot.data?.inSeconds ?? 0;
            return Text('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('صورة'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: const Text('ملف'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatus(String otherId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(otherId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('غير متصل', style: TextStyle(fontSize: 12, color: Colors.grey));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final lastActive = data?['lastActive'];
        if (lastActive == null) {
          return const Text('غير متصل', style: TextStyle(fontSize: 12, color: Colors.grey));
        }
        final lastActiveDate = lastActive is Timestamp ? lastActive.toDate() : DateTime.now();
        final diff = DateTime.now().difference(lastActiveDate).inMinutes;
        if (diff < 5) {
          return const Text('نشط الآن', style: TextStyle(fontSize: 12, color: Colors.green));
        } else {
          return Text('آخر ظهور ${timeago.format(lastActiveDate, locale: "ar")}', style: const TextStyle(fontSize: 11, color: Colors.grey));
        }
      },
    );
  }

  void _showContractBottomSheet(BuildContext context) {
    final detailsController = TextEditingController();
    final priceController = TextEditingController();
    final deadlineController = TextEditingController();
    final notesController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2332) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.handshake, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('إنشاء عقد اتفاق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('حدد تفاصيل العمل لحماية حقوق الطرفين', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
            ),
            const Divider(),
            // Form
            Expanded(
              child: ListView(controller: scrollController, padding: const EdgeInsets.all(20), children: [
                // Service Description
                _buildContractField(
                  label: 'وصف الخدمة المطلوبة *',
                  icon: Icons.description,
                  child: TextField(
                    controller: detailsController,
                    maxLines: 4,
                    decoration: _contractInputDecor('اكتب وصف تفصيلي للخدمة أو العمل المطلوب إنجازه...', isDark),
                  ),
                ),
                const SizedBox(height: 16),
                // Price
                _buildContractField(
                  label: 'المبلغ المتفق عليه *',
                  icon: Icons.payments,
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _contractInputDecor('0.00', isDark).copyWith(
                      suffixText: 'SDG',
                      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Deadline
                _buildContractField(
                  label: 'مدة التنفيذ المتوقعة',
                  icon: Icons.schedule,
                  child: TextField(
                    controller: deadlineController,
                    decoration: _contractInputDecor('مثال: 3 أيام، أسبوع، شهر...', isDark),
                  ),
                ),
                const SizedBox(height: 16),
                // Notes
                _buildContractField(
                  label: 'شروط وملاحظات إضافية',
                  icon: Icons.note_add,
                  child: TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: _contractInputDecor('أي شروط أو ملاحظات خاصة بالاتفاق...', isDark),
                  ),
                ),
                const SizedBox(height: 24),
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'سيتم إرسال العقد للطرف الآخر للموافقة عليه. بعد الموافقة سيتم تتبع سير العمل تلقائياً.',
                      style: TextStyle(fontSize: 12, color: Colors.blue, height: 1.5),
                    )),
                  ]),
                ),
                const SizedBox(height: 20),
                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final details = detailsController.text.trim();
                      final priceText = priceController.text.trim();
                      if (details.isEmpty || priceText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى ملء وصف الخدمة والمبلغ'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final price = double.tryParse(priceText);
                      if (price == null || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى إدخال مبلغ صحيح'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final auth = context.read<AuthProvider>();
                      final chatProv = context.read<ChatProvider>();
                      final user = auth.user;
                      if (user == null) return;
                      final otherId = widget.chat.getOtherParticipantId(user.id);
                      Navigator.pop(ctx);
                      final deadline = deadlineController.text.trim();
                      final notes = notesController.text.trim();
                      final fullDetails = '$details${deadline.isNotEmpty ? '\n⏰ المدة: $deadline' : ''}${notes.isNotEmpty ? '\n📝 ملاحظات: $notes' : ''}';
                      await chatProv.sendContractMessage(
                        senderId: user.id,
                        senderName: user.name,
                        receiverId: otherId,
                        contractDetails: fullDetails,
                        contractPrice: price,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.send, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('إرسال العقد', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildContractField({required String label, required IconData icon, required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
      const SizedBox(height: 8),
      child,
    ]);
  }

  InputDecoration _contractInputDecor(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final ChatModel chat;

  const MessageBubble({super.key, required this.message, required this.isMe, required this.chat});

  @override
  Widget build(BuildContext context) {
    final color = isMe ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200]);
    final textColor = isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? (isRtl ? 0 : 16) : (isRtl ? 16 : 0)),
      bottomRight: Radius.circular(isMe ? (isRtl ? 16 : 0) : (isRtl ? 0 : 16)),
    );

    return GestureDetector(
      onLongPress: () {
        if (!isMe) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isRtl ? 'خيارات الرسالة' : 'Message Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (message.type == MessageType.text)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditMessageDialog(context, isRtl);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(isRtl ? 'تعديل الرسالة' : 'Edit Message'),
                    style: ElevatedButton.styleFrom(
                      alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                    ),
                  ),
                if (message.type == MessageType.text)
                  const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    FirebaseFirestore.instance.collection('chats').doc(chat.id).collection('messages').doc(message.id).delete();
                  },
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: Text(isRtl ? 'حذف الرسالة' : 'Delete Message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
              ),
              child: _buildMessageContent(context, textColor),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeago.format(message.createdAt, locale: 'ar'),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  if (message.isEdited) ...[
                    const SizedBox(width: 4),
                    Text(
                      isRtl ? '(معدلة)' : '(edited)',
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMessageDialog(BuildContext context, bool isRtl) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRtl ? 'تعديل الرسالة' : 'Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: isRtl ? 'اكتب رسالتك هنا...' : 'Type your message...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isRtl ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && controller.text.trim() != message.content) {
                FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chat.id)
                    .collection('messages')
                    .doc(message.id)
                    .update({
                  'content': controller.text.trim(),
                  'isEdited': true,
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(isRtl ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color textColor) {
    switch (message.type) {
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.attachmentUrl ?? '',
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
                },
              ),
            ),
            if (message.content.isNotEmpty && message.content != '📷 صورة')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinkableText(text: message.content, style: TextStyle(color: textColor)),
              ),
          ],
        );
      case MessageType.audio:
        return VoiceMessageWidget(url: message.attachmentUrl ?? '', duration: message.duration ?? 0, isMe: isMe);
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white70),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.attachmentName ?? 'ملف',
                style: TextStyle(color: textColor, decoration: TextDecoration.underline),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.contract:
        return _buildContractContent(context, textColor);
      default:
        return LinkableText(
          text: message.content,
          style: TextStyle(color: textColor, fontSize: 15),
        );
    }
  }

  Widget _buildContractContent(BuildContext context, Color textColor) {
    IconData statusIcon = Icons.pending_actions;
    Color statusColor = Colors.orange;
    String statusText = 'قيد الانتظار';

    if (message.contractStatus == 'accepted') {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      statusText = 'مقبول';
    } else if (message.contractStatus == 'rejected') {
      statusIcon = Icons.cancel;
      statusColor = Colors.red;
      statusText = 'مرفوض';
    } else if (message.contractStatus == 'cancel_requested') {
      statusIcon = Icons.warning_amber_rounded;
      statusColor = Colors.deepOrange;
      statusText = 'طلب إلغاء';
    } else if (message.contractStatus == 'cancelled') {
      statusIcon = Icons.cancel_schedule_send;
      statusColor = Colors.grey;
      statusText = 'ملغى';
    }

    final currentUserId = context.read<AuthProvider>().user?.id;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text('عقد اتفاق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            ],
          ),
          const Divider(),
          LinkableText(text: 'الوصف: ${message.contractDetails}', style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 8),
          Text('السعر: ${message.contractPrice} SDG', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              if (!isMe && message.contractStatus == 'pending')
                ElevatedButton(
                  onPressed: () async {
                    // Show a simple loading indicator dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      // Extract details for the job
                      final freelancerId = message.senderId;
                      final freelancerName = chat.participantNames[freelancerId] ?? 'مستقل';
                      
                      final clientId = currentUserId ?? '';
                      final clientName = chat.participantNames[clientId] ?? 'عميل';
                      final clientImageUrl = chat.participantImages[clientId];

                      // 1. Start the Project
                      final jobId = await context.read<JobProvider>().startProject(
                        clientId: clientId,
                        clientName: clientName,
                        clientImageUrl: clientImageUrl,
                        title: 'عقد عمل مع $freelancerName',
                        description: message.contractDetails ?? 'تم إنشاء العقد عبر الدردشة',
                        price: message.contractPrice ?? 0.0,
                        freelancerId: freelancerId,
                        freelancerName: freelancerName,
                      );

                      if (jobId != null) {
                        // 2. Update the contract status with the new job ID
                        await context.read<ChatProvider>().updateContractStatus(message.id, 'accepted', jobId: jobId);
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم إنشاء المشروع بنجاح!'), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          Navigator.pop(context); // Close loading dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('حدث خطأ أثناء إنشاء المشروع'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) Navigator.pop(context); // Close loading dialog
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('موافقة', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
            ],
          ),
          // Additional Actions
          if (message.contractStatus == 'pending') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showEditContractDialog(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('طلب تعديل العقد', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
          if (message.contractStatus == 'accepted') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final jobId = message.jobId;
                  if (jobId != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveJobTrackingScreen(jobId: jobId),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لم يتم العثور على المشروع')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('إدارة المشروع', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
          if (message.contractStatus == 'cancel_requested' && message.cancelRequesterId != currentUserId) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<ChatProvider>().updateContractStatus(message.id, 'cancelled');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 30),
                ),
                child: const Text('الموافقة على الإلغاء', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _showEditContractDialog(BuildContext context) {
    final detailsController = TextEditingController(text: message.contractDetails);
    final priceController = TextEditingController(text: message.contractPrice?.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل العقد', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'وصف الخدمة المعدل', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'السعر المعدل (SDG)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final details = detailsController.text.trim();
              final priceStr = priceController.text.trim();
              if (details.isEmpty || priceStr.isEmpty) return;
              final price = double.tryParse(priceStr);
              if (price == null) return;
              
              Navigator.pop(ctx);
              
              await context.read<ChatProvider>().updateContractDetails(
                message.id,
                details,
                price,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('تحديث العقد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class VoiceMessageWidget extends StatefulWidget {
  final String url;
  final int duration;
  final bool isMe;

  const VoiceMessageWidget({super.key, required this.url, required this.duration, required this.isMe});

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.duration);
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
      if (s == PlayerState.completed) {
        setState(() => _position = Duration.zero);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isMe ? Colors.white : Colors.black87;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: textColor),
          onPressed: _togglePlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 150, // Fixed width instead of Expanded
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 2,
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              max: _totalDuration.inSeconds.toDouble() > 0 ? _totalDuration.inSeconds.toDouble() : 1,
              activeColor: textColor,
              inactiveColor: textColor.withValues(alpha: 0.3),
              onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
            ),
          ),
        ),
        Text(
          '${_position.inSeconds ~/ 60}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
          style: TextStyle(color: textColor, fontSize: 10),
        ),
      ],
    );
  }
}
