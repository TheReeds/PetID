import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType {
  match,        // Chat originado por un match
  postInquiry,  // Chat originado por consulta en un post
  direct        // Chat directo entre usuarios
}

enum MessageType {
  text,
  image,
  location,
  petInfo,     // Información de mascota compartida
  matchInfo    // Información de match compartida
}

enum MessageStatus { sent, delivered, read }

class ChatModel {
  final String id;
  final String chatName;
  final List<String> participants;
  final ChatType type;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MessageModel? lastMessage;
  final Map<String, DateTime> lastReadBy; // userId -> timestamp
  final Map<String, int> unreadCount;     // userId -> count
  final bool isActive;

  // Información adicional según el tipo
  final String? matchId;    // Si viene de un match
  final String? postId;     // Si viene de un post
  final String? petId;      // Si está relacionado con una mascota

  // Metadatos
  final Map<String, dynamic> metadata;

  ChatModel({
    required this.id,
    required this.chatName,
    required this.participants,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastReadBy = const {},
    this.unreadCount = const {},
    this.isActive = true,
    this.matchId,
    this.postId,
    this.petId,
    this.metadata = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      chatName: data['chatName'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      type: ChatType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
        orElse: () => ChatType.direct,
      ),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastMessage: data['lastMessage'] != null
          ? MessageModel.fromMap(data['lastMessage'])
          : null,
      lastReadBy: Map<String, DateTime>.from(
        (data['lastReadBy'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as Timestamp).toDate()),
        ) ?? {},
      ),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      isActive: data['isActive'] ?? true,
      matchId: data['matchId'],
      postId: data['postId'],
      petId: data['petId'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatName': chatName,
      'participants': participants,
      'type': type.toString().split('.').last,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage?.toMap(),
      'lastReadBy': lastReadBy.map(
            (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'matchId': matchId,
      'postId': postId,
      'petId': petId,
      'metadata': metadata,
    };
  }

  ChatModel copyWith({
    String? chatName,
    List<String>? participants,
    ChatType? type,
    DateTime? updatedAt,
    MessageModel? lastMessage,
    Map<String, DateTime>? lastReadBy,
    Map<String, int>? unreadCount,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return ChatModel(
      id: id,
      chatName: chatName ?? this.chatName,
      participants: participants ?? this.participants,
      type: type ?? this.type,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastMessage: lastMessage ?? this.lastMessage,
      lastReadBy: lastReadBy ?? this.lastReadBy,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      matchId: matchId,
      postId: postId,
      petId: petId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Métodos de conveniencia
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCountForUser(userId) > 0;
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyToId;
  final List<String> attachments;
  final Map<String, dynamic> metadata;

  // Para mensajes especiales
  final String? locationLat;
  final String? locationLng;
  final String? locationName;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.replyToId,
    this.attachments = const [],
    this.metadata = const {},
    this.locationLat,
    this.locationLng,
    this.locationName,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap(data, doc.id);
  }

  factory MessageModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    return MessageModel(
      id: docId ?? data['id'] ?? '',
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: MessageStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      replyToId: data['replyToId'],
      attachments: List<String>.from(data['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      locationLat: data['locationLat'],
      locationLng: data['locationLng'],
      locationName: data['locationName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.toString().split('.').last,
      'replyToId': replyToId,
      'attachments': attachments,
      'metadata': metadata,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'locationName': locationName,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  MessageModel copyWith({
    String? content,
    MessageType? type,
    MessageStatus? status,
    String? replyToId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp,
      status: status ?? this.status,
      replyToId: replyToId ?? this.replyToId,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      locationLat: locationLat,
      locationLng: locationLng,
      locationName: locationName,
    );
  }

  // Factory methods para tipos específicos de mensajes
  factory MessageModel.textMessage({
    required String id,
    required String chatId,
    required String senderId,
    required String content,
    String? replyToId,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
      replyToId: replyToId,
    );
  }

  factory MessageModel.imageMessage({
    required String id,
    required String chatId,
    required String senderId,
    required String imageUrl,
    String? caption,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: caption ?? '',
      type: MessageType.image,
      timestamp: DateTime.now(),
      attachments: [imageUrl],
    );
  }

  factory MessageModel.locationMessage({
    required String id,
    required String chatId,
    required String senderId,
    required String lat,
    required String lng,
    String? locationName,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: locationName ?? 'Ubicación compartida',
      type: MessageType.location,
      timestamp: DateTime.now(),
      locationLat: lat,
      locationLng: lng,
      locationName: locationName,
    );
  }

  factory MessageModel.petInfoMessage({
    required String id,
    required String chatId,
    required String senderId,
    required String petId,
    required String petName,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: 'Información de $petName',
      type: MessageType.petInfo,
      timestamp: DateTime.now(),
      metadata: {'petId': petId, 'petName': petName},
    );
  }

  // Getters de conveniencia
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isLocation => type == MessageType.location;
  bool get isPetInfo => type == MessageType.petInfo;
  bool get isMatchInfo => type == MessageType.matchInfo;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isReply => replyToId != null;
}