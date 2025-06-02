import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../services/firebase_service.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _uuid = const Uuid();

  // Obtener chats del usuario
  Stream<List<ChatModel>> getUserChats(String userId) {
    return FirebaseService.firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatModel.fromFirestore(doc))
        .toList());
  }

  // Obtener un chat específico
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .get();

      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error obteniendo chat: $e');
      return null;
    }
  }

  // Buscar chat existente entre usuarios
  Future<ChatModel?> findExistingChat({
    required List<String> participants,
    String? matchId,
    String? postId,
  }) async {
    try {
      Query query = FirebaseService.firestore
          .collection('chats')
          .where('participants', isEqualTo: participants)
          .where('isActive', isEqualTo: true);

      if (matchId != null) {
        query = query.where('matchId', isEqualTo: matchId);
      }
      if (postId != null) {
        query = query.where('postId', isEqualTo: postId);
      }

      final snapshot = await query.limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        return ChatModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error buscando chat existente: $e');
      return null;
    }
  }

  // Crear nuevo chat
  Future<String> createChat({
    required List<String> participants,
    required String createdBy,
    required ChatType type,
    String? chatName,
    String? matchId,
    String? postId,
    String? petId,
    String? initialMessage,
  }) async {
    try {
      final chatId = _uuid.v4();

      // Generar nombre automático si no se proporciona
      String finalChatName = chatName ?? 'Chat ${DateTime.now().millisecondsSinceEpoch}';

      final chat = ChatModel(
        id: chatId,
        chatName: finalChatName,
        participants: participants,
        type: type,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        matchId: matchId,
        postId: postId,
        petId: petId,
        unreadCount: {
          for (String userId in participants)
            if (userId != createdBy) userId: 0
        },
      );

      await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .set(chat.toFirestore());

      // Enviar mensaje inicial si se proporciona
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await sendMessage(
          chatId: chatId,
          senderId: createdBy,
          content: initialMessage,
          type: MessageType.text,
        );
      }

      return chatId;
    } catch (e) {
      print('Error creando chat: $e');
      throw Exception('Error creando chat: $e');
    }
  }

  // Crear chat desde match
  Future<String> createChatFromMatch({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    String? initialMessage,
  }) async {
    return await createChat(
      participants: [fromUserId, toUserId],
      createdBy: fromUserId,
      type: ChatType.match,
      chatName: 'Chat de Match',
      matchId: matchId,
      initialMessage: initialMessage,
    );
  }

  // Crear chat desde post
  Future<String> createChatFromPost({
    required String postId,
    required String fromUserId,
    required String toUserId,
    String? petId,
    String? initialMessage,
  }) async {
    return await createChat(
      participants: [fromUserId, toUserId],
      createdBy: fromUserId,
      type: ChatType.postInquiry,
      chatName: 'Consulta sobre publicación',
      postId: postId,
      petId: petId,
      initialMessage: initialMessage,
    );
  }

  // Enviar mensaje
  Future<String> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    required MessageType type,
    String? replyToId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    String? locationLat,
    String? locationLng,
    String? locationName,
  }) async {
    try {
      final messageId = _uuid.v4();

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        replyToId: replyToId,
        attachments: attachments ?? [],
        metadata: metadata ?? {},
        locationLat: locationLat,
        locationLng: locationLng,
        locationName: locationName,
      );

      // Guardar mensaje
      await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toFirestore());

      // Actualizar último mensaje y contadores del chat
      await _updateChatAfterMessage(chatId, message);

      return messageId;
    } catch (e) {
      print('Error enviando mensaje: $e');
      throw Exception('Error enviando mensaje: $e');
    }
  }

  // Actualizar chat después de enviar mensaje
  Future<void> _updateChatAfterMessage(String chatId, MessageModel message) async {
    try {
      final chatDoc = await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) return;

      final chat = ChatModel.fromFirestore(chatDoc);

      // Actualizar contadores de no leídos
      Map<String, int> newUnreadCount = Map.from(chat.unreadCount);
      for (String userId in chat.participants) {
        if (userId != message.senderId) {
          newUnreadCount[userId] = (newUnreadCount[userId] ?? 0) + 1;
        }
      }

      // Actualizar chat
      await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .update({
        'lastMessage': message.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'unreadCount': newUnreadCount,
      });
    } catch (e) {
      print('Error actualizando chat: $e');
    }
  }

  // Obtener mensajes de un chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return FirebaseService.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList());
  }

  // Marcar mensajes como leídos
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .update({
        'unreadCount.$userId': 0,
        'lastReadBy.$userId': Timestamp.now(),
      });
    } catch (e) {
      print('Error marcando mensajes como leídos: $e');
    }
  }

  // Eliminar chat (marcar como inactivo)
  Future<void> deleteChat(String chatId) async {
    try {
      await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error eliminando chat: $e');
      throw Exception('Error eliminando chat: $e');
    }
  }

  // Actualizar estado del mensaje
  Future<void> updateMessageStatus(
      String chatId,
      String messageId,
      MessageStatus status
      ) async {
    try {
      await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error actualizando estado del mensaje: $e');
    }
  }

  // Buscar mensajes en un chat
  Future<List<MessageModel>> searchMessages(
      String chatId,
      String query
      ) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy('content')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error buscando mensajes: $e');
      return [];
    }
  }

  // Obtener conteo total de mensajes no leídos para un usuario
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final chat = ChatModel.fromFirestore(doc);
        totalUnread += chat.getUnreadCountForUser(userId);
      }

      return totalUnread;
    } catch (e) {
      print('Error obteniendo conteo de no leídos: $e');
      return 0;
    }
  }

  // Obtener chats con mensajes no leídos
  Stream<List<ChatModel>> getChatsWithUnreadMessages(String userId) {
    return getUserChats(userId).map((chats) =>
        chats.where((chat) => chat.hasUnreadMessages(userId)).toList()
    );
  }

  // Obtener último mensaje de un chat
  Future<MessageModel?> getLastMessage(String chatId) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MessageModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error obteniendo último mensaje: $e');
      return null;
    }
  }
  Future<List<Map<String, dynamic>>> getChatMessagesPaginated(
      String chatId, {
        required int limit,
        DocumentSnapshot? startAfter,
      }) async {
    try {
      Query query = FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => {
        'message': MessageModel.fromFirestore(doc),
        'doc': doc,
      }).toList();
    } catch (e) {
      print('Error obteniendo mensajes paginados: $e');
      return [];
    }
  }

// Obtener nuevos mensajes en tiempo real (desde el último documento)
  Stream<List<MessageModel>> getNewMessages(String chatId, DocumentSnapshot? lastDoc) {
    Query query = FirebaseService.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    if (lastDoc != null) {
      query = query.endBeforeDocument(lastDoc);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docChanges.isEmpty) return [];

      return snapshot.docChanges
          .where((change) => change.type == DocumentChangeType.added)
          .map((change) => MessageModel.fromFirestore(change.doc))
          .toList();
    });
  }

// Indicadores de escritura - establecer estado
  Future<void> setTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      final typingRef = FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId);

      if (isTyping) {
        await typingRef.set({
          'userId': userId,
          'isTyping': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await typingRef.delete();
      }
    } catch (e) {
      print('Error actualizando estado de escritura: $e');
    }
  }

// Indicadores de escritura - escuchar cambios
  Stream<List<String>> getTypingIndicators(String chatId) {
    return FirebaseService.firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      // Filtrar usuarios que estén escribiendo en los últimos 5 segundos
      final now = DateTime.now();
      return snapshot.docs
          .where((doc) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        return timestamp != null &&
            now.difference(timestamp).inSeconds < 5 &&
            data['isTyping'] == true;
      })
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    });
  }

// Estados de entrega - escuchar actualizaciones
  Stream<Map<String, MessageStatus>> getDeliveryStatusUpdates(String chatId, String userId) {
    return FirebaseService.firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      Map<String, MessageStatus> statusUpdates = {};

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final message = MessageModel.fromFirestore(change.doc);
          statusUpdates[message.id] = message.status;
        }
      }

      return statusUpdates;
    });
  }

// Limpiar indicadores de escritura antiguos (llamar periódicamente)
  Future<void> cleanupOldTypingIndicators(String chatId) async {
    try {
      final cutoffTime = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(seconds: 10))
      );

      final oldTypingDocs = await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .where('timestamp', isLessThan: cutoffTime)
          .get();

      for (var doc in oldTypingDocs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error limpiando indicadores antiguos: $e');
    }
  }

// Marcar mensaje como entregado cuando el destinatario está online
  Future<void> markMessageAsDelivered(String chatId, String messageId) async {
    try {
      await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': MessageStatus.delivered.toString().split('.').last,
      });
    } catch (e) {
      print('Error marcando mensaje como entregado: $e');
    }
  }

// Marcar todos los mensajes de un usuario como leídos en un chat
  Future<void> markAllMessagesAsRead(String chatId, String otherUserId) async {
    try {
      final unreadMessages = await FirebaseService.firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();

      final batch = FirebaseService.firestore.batch();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.read.toString().split('.').last,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error marcando todos los mensajes como leídos: $e');
    }
  }
}