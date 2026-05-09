import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/locale_provider.dart';
import 'chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<ChatProvider>().fetchChats(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final user = context.watch<AuthProvider>().user;
    final chatProvider = context.watch<ChatProvider>();
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chats = chatProvider.chats;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ar' ? 'المحادثات' : 'Chats'),
        centerTitle: true,
      ),
      body: chatProvider.isLoading && chats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        locale == 'ar' ? 'لا توجد محادثات سابقة' : 'No previous chats',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        locale == 'ar' 
                            ? 'ابدأ محادثة من صفحة أي حرفي أو متجر'
                            : 'Start a chat from any freelancer or shop profile',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final otherName = chat.getOtherParticipantName(user.id);
                    final otherImage = chat.getOtherParticipantImage(user.id);
                    final unreadCount = chat.getUnreadCount(user.id);
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: unreadCount > 0
                            ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(chat: chat),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage: otherImage != null && otherImage.isNotEmpty
                                    ? NetworkImage(otherImage)
                                    : null,
                                child: otherImage == null || otherImage.isEmpty
                                    ? Text(
                                        otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),

                              // Name + Last message
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      otherName,
                                      style: TextStyle(
                                        fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      chat.lastMessage ?? (locale == 'ar' ? 'بدأت المحادثة' : 'Chat started'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: unreadCount > 0
                                            ? (isDark ? Colors.white70 : Colors.black87)
                                            : Colors.grey[500],
                                        fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Time + Unread badge
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (chat.lastMessageTime != null)
                                    Text(
                                      timeago.format(chat.lastMessageTime!, locale: locale),
                                      style: TextStyle(
                                        color: unreadCount > 0 ? AppColors.primary : Colors.grey[500],
                                        fontSize: 11,
                                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  if (unreadCount > 0) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        unreadCount.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
