import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file, audio, contract }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final MessageType type;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? duration; // For audio messages (in seconds)
  final bool isRead;
  final bool isEdited;
  final DateTime createdAt;
  
  // Contract specific fields
  final String? contractDetails;
  final double? contractPrice;
  final String? contractStatus; // pending, accepted, rejected, cancel_requested, cancelled
  final String? cancelRequesterId; // ID of the user who requested cancellation
  final String? jobId; // Associated job ID when contract is accepted

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.attachmentUrl,
    this.attachmentName,
    this.duration,
    this.isRead = false,
    this.isEdited = false,
    required this.createdAt,
    this.contractDetails,
    this.contractPrice,
    this.contractStatus,
    this.cancelRequesterId,
    this.jobId,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      attachmentUrl: data['attachmentUrl'],
      attachmentName: data['attachmentName'],
      duration: data['duration'],
      isRead: data['isRead'] ?? false,
      isEdited: data['isEdited'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      contractDetails: data['contractDetails'],
      contractPrice: (data['contractPrice'] as num?)?.toDouble(),
      contractStatus: data['contractStatus'],
      cancelRequesterId: data['cancelRequesterId'],
      jobId: data['jobId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'duration': duration,
      'isRead': isRead,
      'isEdited': isEdited,
      'createdAt': Timestamp.fromDate(createdAt),
      if (contractDetails != null) 'contractDetails': contractDetails,
      if (contractPrice != null) 'contractPrice': contractPrice,
      if (contractStatus != null) 'contractStatus': contractStatus,
      if (cancelRequesterId != null) 'cancelRequesterId': cancelRequesterId,
      if (jobId != null) 'jobId': jobId,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? content,
    MessageType? type,
    String? attachmentUrl,
    String? attachmentName,
    int? duration,
    bool? isRead,
    bool? isEdited,
    DateTime? createdAt,
    String? contractDetails,
    double? contractPrice,
    String? contractStatus,
    String? cancelRequesterId,
    String? jobId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      duration: duration ?? this.duration,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      contractDetails: contractDetails ?? this.contractDetails,
      contractPrice: contractPrice ?? this.contractPrice,
      contractStatus: contractStatus ?? this.contractStatus,
      cancelRequesterId: cancelRequesterId ?? this.cancelRequesterId,
      jobId: jobId ?? this.jobId,
    );
  }

  bool get isTextMessage => type == MessageType.text;
  bool get isImageMessage => type == MessageType.image;
  bool get isFileMessage => type == MessageType.file;
  bool get isAudioMessage => type == MessageType.audio;
  bool get isContractMessage => type == MessageType.contract;
}

class ChatModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantImages;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final Map<String, int> unreadCount;
  final String? jobId;
  final String? jobTitle;
  final Map<String, bool> typingStatus; // userId -> isTyping
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantImages = const {},
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    this.unreadCount = const {},
    this.jobId,
    this.jobTitle,
    this.typingStatus = const {},
    required this.createdAt,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantImages: Map<String, String?>.from(data['participantImages'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      jobId: data['jobId'],
      jobTitle: data['jobTitle'],
      typingStatus: Map<String, bool>.from(data['typingStatus'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantImages': participantImages,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'typingStatus': typingStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? '';
  }

  String? getOtherParticipantImage(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantImages[otherId];
  }

  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool isTyping(String userId) {
    return typingStatus[userId] ?? false;
  }
}
