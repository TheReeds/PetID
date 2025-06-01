import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/storage_service.dart';

enum ChatState { idle, loading, loaded, error }

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  ChatState _state = ChatState.idle;
  List<ChatModel> _userChats = [];
  ChatModel? _activeChat;
  List<MessageModel> _currentMessages = [];
  int _totalUnreadCount = 0;
  String? _errorMessage;

  // Paginación
  static const int _messagesPerPage = 20;
  bool _hasMoreMessages = true;
  bool _isLoadingMoreMessages = false;
  DocumentSnapshot? _lastMessageDoc;

  // Indicadores de escritura
  final Map<String, Set<String>> _typingUsers = {}; // chatId -> Set<userId>
  final Map<String, Timer> _typingTimers = {}; // userId -> Timer
  static const Duration _typingTimeout = Duration(seconds: 3);

  // Estados de entrega
  StreamSubscription? _deliveryStatusSubscription;

  // Getters
  ChatState get state => _state;
  List<ChatModel> get userChats => _userChats;
  ChatModel? get activeChat => _activeChat;
  List<MessageModel> get currentMessages => _currentMessages;
  int get totalUnreadCount => _totalUnreadCount;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ChatState.loading;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isLoadingMoreMessages => _isLoadingMoreMessages;

  // Getters para indicadores de escritura
  Set<String> getTypingUsers(String chatId) => _typingUsers[chatId] ?? {};
  bool isUserTyping(String chatId, String userId) =>
      _typingUsers[chatId]?.contains(userId) ?? false;

  // Cargar chats del usuario
  Future<void> loadUserChats(String userId) async {
    try {
      _setState(ChatState.loading);
      _clearError();

      _chatRepository.getUserChats(userId).listen((chats) {
        _userChats = chats;
        _updateTotalUnreadCount(userId);
        _setState(ChatState.loaded);
      }, onError: (error) {
        _setError('Error cargando chats: $error');
      });
    } catch (e) {
      _setError('Error: $e');
    }
  }

  // Actualizar conteo total de no leídos
  void _updateTotalUnreadCount(String userId) {
    _totalUnreadCount = _userChats.fold(0, (sum, chat) =>
    sum + chat.getUnreadCountForUser(userId));
    notifyListeners();
  }

  // Crear chat desde match
  Future<String?> createChatFromMatch({
    required String matchId,
    required String fromUserId,
    required String toUserId,
    String? initialMessage,
  }) async {
    try {
      _setState(ChatState.loading);
      _clearError();

      // Verificar si ya existe un chat para este match
      final existingChat = await _chatRepository.findExistingChat(
        participants: [fromUserId, toUserId],
        matchId: matchId,
      );

      if (existingChat != null) {
        return existingChat.id;
      }

      final chatId = await _chatRepository.createChatFromMatch(
        matchId: matchId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        initialMessage: initialMessage,
      );

      _setState(ChatState.loaded);
      return chatId;
    } catch (e) {
      _setError('Error creando chat desde match: $e');
      return null;
    }
  }

  // Crear chat desde post
  Future<String?> createChatFromPost({
    required String postId,
    required String fromUserId,
    required String toUserId,
    String? petId,
    String? initialMessage,
  }) async {
    try {
      _setState(ChatState.loading);
      _clearError();

      // Verificar si ya existe un chat para este post
      final existingChat = await _chatRepository.findExistingChat(
        participants: [fromUserId, toUserId],
        postId: postId,
      );

      if (existingChat != null) {
        return existingChat.id;
      }

      final chatId = await _chatRepository.createChatFromPost(
        postId: postId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        petId: petId,
        initialMessage: initialMessage,
      );

      _setState(ChatState.loaded);
      return chatId;
    } catch (e) {
      _setError('Error creando chat desde post: $e');
      return null;
    }
  }

  // Abrir chat específico con paginación
  Future<void> openChat(String chatId, String userId) async {
    try {
      _setState(ChatState.loading);
      _clearError();

      // Obtener chat
      final chat = await _chatRepository.getChatById(chatId);
      if (chat == null) {
        _setError('Chat no encontrado');
        return;
      }

      _activeChat = chat;
      _currentMessages.clear();
      _lastMessageDoc = null;
      _hasMoreMessages = true;

      // Cargar mensajes iniciales con paginación
      await _loadInitialMessages(chatId);

      // Configurar escucha de nuevos mensajes
      _setupRealtimeMessages(chatId);

      // Configurar escucha de indicadores de escritura
      _setupTypingIndicators(chatId);

      // Configurar escucha de estados de entrega
      _setupDeliveryStatusListener(chatId, userId);

      // Marcar como leído
      await _chatRepository.markMessagesAsRead(chatId, userId);

      _setState(ChatState.loaded);
    } catch (e) {
      _setError('Error abriendo chat: $e');
    }
  }

  // Cargar mensajes iniciales
  Future<void> _loadInitialMessages(String chatId) async {
    final messages = await _chatRepository.getChatMessagesPaginated(
      chatId,
      limit: _messagesPerPage,
    );

    if (messages.isNotEmpty) {
      _currentMessages = messages.map((data) => data['message'] as MessageModel).toList();
      _lastMessageDoc = messages.last['doc'] as DocumentSnapshot;
      _hasMoreMessages = messages.length == _messagesPerPage;
    } else {
      _hasMoreMessages = false;
    }
  }

  // Configurar escucha en tiempo real de nuevos mensajes
  void _setupRealtimeMessages(String chatId) {
    _chatRepository.getNewMessages(chatId, _lastMessageDoc).listen((newMessages) {
      if (newMessages.isNotEmpty) {
        // Insertar nuevos mensajes al inicio (más recientes)
        _currentMessages.insertAll(0, newMessages);
        notifyListeners();
      }
    });
  }

  // Cargar más mensajes antiguos (paginación)
  Future<void> loadMoreMessages() async {
    if (!_hasMoreMessages || _isLoadingMoreMessages || _activeChat == null) return;

    try {
      _isLoadingMoreMessages = true;
      notifyListeners();

      final moreMessages = await _chatRepository.getChatMessagesPaginated(
        _activeChat!.id,
        limit: _messagesPerPage,
        startAfter: _lastMessageDoc,
      );

      if (moreMessages.isNotEmpty) {
        final messagesToAdd = moreMessages.map((data) => data['message'] as MessageModel).toList();
        _currentMessages.addAll(messagesToAdd);
        _lastMessageDoc = moreMessages.last['doc'] as DocumentSnapshot;
        _hasMoreMessages = moreMessages.length == _messagesPerPage;
      } else {
        _hasMoreMessages = false;
      }

      _isLoadingMoreMessages = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMoreMessages = false;
      _setError('Error cargando más mensajes: $e');
    }
  }

  // Configurar indicadores de escritura
  void _setupTypingIndicators(String chatId) {
    _chatRepository.getTypingIndicators(chatId).listen((typingData) {
      _typingUsers[chatId] = Set<String>.from(typingData);
      notifyListeners();
    });
  }

  // Indicar que el usuario está escribiendo
  Future<void> setUserTyping(String chatId, String userId, bool isTyping) async {
    try {
      await _chatRepository.setTypingStatus(chatId, userId, isTyping);

      if (isTyping) {
        // Configurar timer para auto-stop
        _typingTimers[userId]?.cancel();
        _typingTimers[userId] = Timer(_typingTimeout, () {
          setUserTyping(chatId, userId, false);
        });
      } else {
        _typingTimers[userId]?.cancel();
        _typingTimers.remove(userId);
      }
    } catch (e) {
      print('Error actualizando estado de escritura: $e');
    }
  }

  // Configurar escucha de estados de entrega
  void _setupDeliveryStatusListener(String chatId, String userId) {
    _deliveryStatusSubscription?.cancel();
    _deliveryStatusSubscription = _chatRepository
        .getDeliveryStatusUpdates(chatId, userId)
        .listen((updates) {
      _updateMessageDeliveryStatus(updates);
    });
  }

  // Actualizar estados de entrega en mensajes locales
  void _updateMessageDeliveryStatus(Map<String, MessageStatus> updates) {
    bool hasChanges = false;

    for (int i = 0; i < _currentMessages.length; i++) {
      final messageId = _currentMessages[i].id;
      if (updates.containsKey(messageId)) {
        _currentMessages[i] = _currentMessages[i].copyWith(
          status: updates[messageId],
        );
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  // Enviar mensaje de texto con estado de entrega
  Future<bool> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? replyToId,
  }) async {
    try {
      final messageId = await _chatRepository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: MessageType.text,
        replyToId: replyToId,
      );

      // Iniciar seguimiento de entrega
      _trackMessageDelivery(chatId, messageId, senderId);

      return true;
    } catch (e) {
      _setError('Error enviando mensaje: $e');
      return false;
    }
  }

  // Seguimiento de entrega de mensaje
  void _trackMessageDelivery(String chatId, String messageId, String senderId) {
    // Marcar como entregado cuando otros usuarios lean el chat
    Timer(const Duration(seconds: 1), () async {
      await _chatRepository.updateMessageStatus(chatId, messageId, MessageStatus.delivered);
    });
  }

  // Enviar mensaje con imagen
  Future<bool> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      _setState(ChatState.loading);

      // Subir imagen
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final imageUrls = await StorageService.uploadPostPhotos(
        postId: 'chat_$chatId',
        imageFiles: [imageFile],
      );

      if (imageUrls.isEmpty) {
        throw Exception('Error subiendo imagen');
      }

      // Enviar mensaje con la imagen
      final messageId = await _chatRepository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: caption ?? '',
        type: MessageType.image,
        attachments: imageUrls,
      );

      // Iniciar seguimiento de entrega
      _trackMessageDelivery(chatId, messageId, senderId);

      _setState(ChatState.loaded);
      return true;
    } catch (e) {
      _setError('Error enviando imagen: $e');
      return false;
    }
  }

  // Enviar mensaje de ubicación
  Future<bool> sendLocationMessage({
    required String chatId,
    required String senderId,
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      final messageId = await _chatRepository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: locationName ?? 'Ubicación compartida',
        type: MessageType.location,
        locationLat: latitude.toString(),
        locationLng: longitude.toString(),
        locationName: locationName,
      );

      _trackMessageDelivery(chatId, messageId, senderId);
      return true;
    } catch (e) {
      _setError('Error enviando ubicación: $e');
      return false;
    }
  }

  // Enviar información de mascota
  Future<bool> sendPetInfoMessage({
    required String chatId,
    required String senderId,
    required String petId,
    required String petName,
  }) async {
    try {
      final messageId = await _chatRepository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        content: 'Información de $petName',
        type: MessageType.petInfo,
        metadata: {'petId': petId, 'petName': petName},
      );

      _trackMessageDelivery(chatId, messageId, senderId);
      return true;
    } catch (e) {
      _setError('Error enviando información de mascota: $e');
      return false;
    }
  }

  // Marcar mensaje como leído (para estados de entrega)
  Future<void> markMessageAsRead(String chatId, String messageId, String userId) async {
    try {
      await _chatRepository.updateMessageStatus(chatId, messageId, MessageStatus.read);
      await _chatRepository.markMessagesAsRead(chatId, userId);
    } catch (e) {
      print('Error marcando mensaje como leído: $e');
    }
  }

  // Buscar mensajes en el chat activo
  Future<List<MessageModel>> searchInCurrentChat(String query) async {
    if (_activeChat == null) return [];

    try {
      return await _chatRepository.searchMessages(_activeChat!.id, query);
    } catch (e) {
      _setError('Error buscando mensajes: $e');
      return [];
    }
  }

  // Eliminar chat
  Future<bool> deleteChat(String chatId) async {
    try {
      await _chatRepository.deleteChat(chatId);

      // Remover de la lista local
      _userChats.removeWhere((chat) => chat.id == chatId);

      // Si es el chat activo, cerrarlo
      if (_activeChat?.id == chatId) {
        closeActiveChat();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error eliminando chat: $e');
      return false;
    }
  }

  // Cerrar chat activo
  void closeActiveChat() {
    // Cancelar indicadores de escritura
    if (_activeChat != null) {
      final chatId = _activeChat!.id;
      _typingUsers.remove(chatId);
      _typingTimers.values.forEach((timer) => timer.cancel());
      _typingTimers.clear();
    }

    // Cancelar suscripciones
    _deliveryStatusSubscription?.cancel();

    _activeChat = null;
    _currentMessages.clear();
    _lastMessageDoc = null;
    _hasMoreMessages = true;
    _setState(ChatState.idle);
  }

  // Marcar mensajes como leídos
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await _chatRepository.markMessagesAsRead(chatId, userId);

      // Actualizar el chat local
      final chatIndex = _userChats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        final updatedUnreadCount = Map<String, int>.from(_userChats[chatIndex].unreadCount);
        updatedUnreadCount[userId] = 0;

        _userChats[chatIndex] = _userChats[chatIndex].copyWith(
          unreadCount: updatedUnreadCount,
        );

        _updateTotalUnreadCount(userId);
      }
    } catch (e) {
      _setError('Error marcando mensajes como leídos: $e');
    }
  }

  // Obtener chat específico
  Future<ChatModel?> getChat(String chatId) async {
    try {
      return await _chatRepository.getChatById(chatId);
    } catch (e) {
      _setError('Error obteniendo chat: $e');
      return null;
    }
  }

  // Verificar si existe chat entre usuarios
  Future<ChatModel?> findExistingChatBetweenUsers(
      List<String> participants, {
        String? matchId,
        String? postId,
      }) async {
    try {
      return await _chatRepository.findExistingChat(
        participants: participants,
        matchId: matchId,
        postId: postId,
      );
    } catch (e) {
      _setError('Error buscando chat existente: $e');
      return null;
    }
  }

  // Crear chat directo
  Future<String?> createDirectChat({
    required String fromUserId,
    required String toUserId,
    String? initialMessage,
  }) async {
    try {
      _setState(ChatState.loading);
      _clearError();

      // Verificar si ya existe un chat directo
      final existingChat = await _chatRepository.findExistingChat(
        participants: [fromUserId, toUserId],
      );

      if (existingChat != null) {
        return existingChat.id;
      }

      final chatId = await _chatRepository.createChat(
        participants: [fromUserId, toUserId],
        createdBy: fromUserId,
        type: ChatType.direct,
        chatName: 'Chat directo',
        initialMessage: initialMessage,
      );

      _setState(ChatState.loaded);
      return chatId;
    } catch (e) {
      _setError('Error creando chat directo: $e');
      return null;
    }
  }

  // Métodos de utilidad privados
  void _setState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = ChatState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Limpiar provider
  @override
  void dispose() {
    // Cancelar timers y suscripciones
    _typingTimers.values.forEach((timer) => timer.cancel());
    _deliveryStatusSubscription?.cancel();

    _userChats.clear();
    _currentMessages.clear();
    _activeChat = null;
    _totalUnreadCount = 0;
    _errorMessage = null;
    _typingUsers.clear();
    _typingTimers.clear();

    super.dispose();
  }

  // Refrescar chats
  Future<void> refreshChats(String userId) async {
    await loadUserChats(userId);
  }

  // Obtener último mensaje de un chat
  Future<MessageModel?> getLastMessage(String chatId) async {
    try {
      return await _chatRepository.getLastMessage(chatId);
    } catch (e) {
      _setError('Error obteniendo último mensaje: $e');
      return null;
    }
  }

  // Reset paginación (útil para refrescar completamente el chat)
  void resetPagination() {
    _currentMessages.clear();
    _lastMessageDoc = null;
    _hasMoreMessages = true;
    _isLoadingMoreMessages = false;
  }
}