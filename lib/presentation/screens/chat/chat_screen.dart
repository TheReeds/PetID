// lib/presentation/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  Timer? _typingTimer;
  bool _isComposing = false;
  bool _showScrollToBottom = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Abrir el chat al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openChat(widget.chatId, widget.currentUserId);
      _animationController.forward();
    });

    // Configurar scroll listener para paginación
    _scrollController.addListener(_onScroll);

    // Configurar listener para indicadores de escritura
    _messageController.addListener(_onTyping);

    // Configurar listener para mostrar botón de scroll
    _scrollController.addListener(_onScrollPositionChange);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Cargar más mensajes cuando esté cerca del final
      context.read<ChatProvider>().loadMoreMessages();
    }
  }

  void _onScrollPositionChange() {
    final showButton = _scrollController.hasClients &&
        _scrollController.offset > 300;

    if (showButton != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showButton;
      });
    }
  }

  void _onTyping() {
    final chatProvider = context.read<ChatProvider>();

    if (_messageController.text.isNotEmpty) {
      if (!_isComposing) {
        setState(() {
          _isComposing = true;
        });
      }

      // Indicar que está escribiendo
      chatProvider.setUserTyping(widget.chatId, widget.currentUserId, true);

      // Resetear timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        chatProvider.setUserTyping(widget.chatId, widget.currentUserId, false);
        if (mounted) {
          setState(() {
            _isComposing = false;
          });
        }
      });
    } else {
      // Parar indicador si no hay texto
      chatProvider.setUserTyping(widget.chatId, widget.currentUserId, false);
      _typingTimer?.cancel();
      if (_isComposing) {
        setState(() {
          _isComposing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _animationController.dispose();

    // Parar indicador de escritura al salir
    context.read<ChatProvider>().setUserTyping(
        widget.chatId,
        widget.currentUserId,
        false
    );

    // Cerrar chat activo
    context.read<ChatProvider>().closeActiveChat();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            if (chatProvider.isLoading && chatProvider.currentMessages.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
              );
            }

            if (chatProvider.errorMessage != null) {
              return _buildErrorState(chatProvider.errorMessage!);
            }

            return Column(
              children: [
                // Lista de mensajes con paginación
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chatProvider.currentMessages.length +
                            (chatProvider.isLoadingMoreMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Mostrar indicador de carga al final
                          if (index == chatProvider.currentMessages.length) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4A7AA7),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final message = chatProvider.currentMessages[index];
                          final isOwn = message.senderId == widget.currentUserId;

                          // Mostrar fecha si es necesario
                          final showDate = _shouldShowDate(index, chatProvider.currentMessages);

                          return Column(
                            children: [
                              if (showDate) _buildDateSeparator(message.timestamp),
                              _MessageBubble(
                                message: message,
                                isOwn: isOwn,
                                onTap: () => _markAsRead(message),
                                onLongPress: () => _showMessageOptions(message),
                              ),
                            ],
                          );
                        },
                      ),

                      // Botón para scroll hacia abajo
                      if (_showScrollToBottom)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            onPressed: _scrollToBottom,
                            backgroundColor: const Color(0xFF4A7AA7),
                            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),

                // Indicador de escritura de otros usuarios
                _TypingIndicator(
                  chatId: widget.chatId,
                  currentUserId: widget.currentUserId,
                ),

                // Input de mensaje
                _MessageInput(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  isComposing: _isComposing,
                  onSend: _sendMessage,
                  onImagePick: _sendImage,
                  onLocationShare: _shareLocation,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF4A7AA7)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Consumer2<ChatProvider, UserProvider>(
        builder: (context, chatProvider, userProvider, child) {
          final chat = chatProvider.activeChat;
          if (chat == null) return const Text('Chat');

          final otherUserId = chat.getOtherParticipant(widget.currentUserId);
          final otherUser = userProvider.getUserForPost(otherUserId);

          // Mostrar indicadores de escritura en el título
          final typingUsers = chatProvider.getTypingUsers(widget.chatId)
              .where((userId) => userId != widget.currentUserId)
              .toList();

          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: otherUser?.photoURL != null
                    ? NetworkImage(otherUser!.photoURL!)
                    : null,
                backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                child: otherUser?.photoURL == null
                    ? Text(
                  otherUser?.displayName.isNotEmpty == true
                      ? otherUser!.displayName.substring(0, 1).toUpperCase()
                      : otherUserId.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF4A7AA7),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getChatTitle(chat, otherUser, otherUserId),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (typingUsers.isNotEmpty)
                      Text(
                        'Escribiendo...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        _getLastSeenText(otherUser),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Color(0xFF4A7AA7)),
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Color(0xFF4A7AA7)),
          onPressed: _startVoiceCall,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF4A7AA7)),
          onPressed: _showChatOptions,
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el chat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.red.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ChatProvider>().openChat(widget.chatId, widget.currentUserId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  bool _shouldShowDate(int index, List<MessageModel> messages) {
    if (index == messages.length - 1) return true; // Primer mensaje

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );

    final nextDate = DateTime(
      nextMessage.timestamp.year,
      nextMessage.timestamp.month,
      nextMessage.timestamp.day,
    );

    return !currentDate.isAtSameMomentAs(nextDate);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'Hoy';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Ayer';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getChatTitle(ChatModel chat, UserModel? otherUser, String otherUserId) {
    if (chat.chatName.isNotEmpty &&
        chat.chatName != 'Chat de Match' &&
        chat.chatName != 'Consulta sobre publicación' &&
        chat.chatName != 'Chat directo') {
      return chat.chatName;
    }

    if (otherUser != null) {
      return otherUser.displayName.isNotEmpty
          ? otherUser.displayName
          : otherUser.fullName ?? 'Usuario';
    }

    return 'Usuario ${otherUserId.substring(0, 8)}';
  }

  String _getLastSeenText(UserModel? user) {
    // Aquí podrías implementar lógica de "última vez visto"
    return 'Activo ahora';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendTextMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      content: text,
    );

    _messageController.clear();

    // Parar indicador de escritura
    context.read<ChatProvider>().setUserTyping(
        widget.chatId,
        widget.currentUserId,
        false
    );

    // Scroll hacia abajo
    _scrollToBottom();
  }

  void _sendImage() async {
    // Implementar picker de imagen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selección de imagen próximamente')),
    );

    // Ejemplo de implementación:
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    //
    // if (image != null) {
    //   final file = File(image.path);
    //   context.read<ChatProvider>().sendImageMessage(
    //     chatId: widget.chatId,
    //     senderId: widget.currentUserId,
    //     imageFile: file,
    //   );
    // }
  }

  void _shareLocation() async {
    // Implementar compartir ubicación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartir ubicación próximamente')),
    );

    // Ejemplo de implementación:
    // final Position position = await Geolocator.getCurrentPosition();
    // context.read<ChatProvider>().sendLocationMessage(
    //   chatId: widget.chatId,
    //   senderId: widget.currentUserId,
    //   latitude: position.latitude,
    //   longitude: position.longitude,
    // );
  }

  void _markAsRead(MessageModel message) {
    if (message.senderId != widget.currentUserId &&
        message.status != MessageStatus.read) {
      context.read<ChatProvider>().markMessageAsRead(
        widget.chatId,
        message.id,
        widget.currentUserId,
      );
    }
  }

  void _showMessageOptions(MessageModel message) {
    final isOwn = message.senderId == widget.currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.text) ...[
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copiar'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mensaje copiado')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Responder'),
                onTap: () {
                  Navigator.pop(context);
                  _replyToMessage(message);
                },
              ),
            ],
            if (isOwn) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Reportar'),
                onTap: () {
                  Navigator.pop(context);
                  _reportMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _replyToMessage(MessageModel message) {
    // Implementar respuesta a mensaje
    _messageFocusNode.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Respuesta a mensaje próximamente')),
    );
  }

  void _editMessage(MessageModel message) {
    // Implementar edición de mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edición de mensaje próximamente')),
    );
  }

  void _deleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Estás seguro de que quieres eliminar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar eliminación
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Eliminación de mensaje próximamente')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _reportMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar mensaje'),
        content: const Text('¿Por qué quieres reportar este mensaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mensaje reportado exitosamente')),
              );
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Videollamada próximamente')),
    );
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Llamada de voz próximamente')),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Buscar en el chat'),
              onTap: () {
                Navigator.pop(context);
                _searchInChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Silenciar notificaciones'),
              onTap: () {
                Navigator.pop(context);
                _muteChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquear usuario'),
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteChat();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _searchInChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Búsqueda en chat próximamente')),
    );
  }

  void _muteChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat silenciado')),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuario'),
        content: const Text('¿Estás seguro de que quieres bloquear a este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario bloqueado')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
  }

  void _deleteChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar chat'),
        content: const Text('¿Estás seguro de que quieres eliminar esta conversación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ChatProvider>().deleteChat(widget.chatId);

              if (success && mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat eliminado exitosamente')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar indicadores de escritura
class _TypingIndicator extends StatelessWidget {
  final String chatId;
  final String currentUserId;

  const _TypingIndicator({
    required this.chatId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final typingUsers = chatProvider.getTypingUsers(chatId)
            .where((userId) => userId != currentUserId)
            .toList();

        if (typingUsers.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _TypingAnimation(),
              const SizedBox(width: 8),
              Text(
                typingUsers.length == 1
                    ? 'Escribiendo...'
                    : '${typingUsers.length} personas escribiendo...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Animación de puntos para indicador de escritura
class _TypingAnimation extends StatefulWidget {
  @override
  _TypingAnimationState createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<_TypingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 10,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final opacity = ((_controller.value + delay) % 1.0) > 0.5 ? 1.0 : 0.3;

              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Widget para el input de mensajes
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isComposing;
  final VoidCallback onSend;
  final VoidCallback onImagePick;
  final VoidCallback onLocationShare;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.isComposing,
    required this.onSend,
    required this.onImagePick,
    required this.onLocationShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botón de imagen
            IconButton(
              icon: Icon(
                Icons.photo_camera,
                color: Colors.grey.shade600,
              ),
              onPressed: onImagePick,
            ),

            // Botón de ubicación
            IconButton(
              icon: Icon(
                Icons.location_on,
                color: Colors.grey.shade600,
              ),
              onPressed: onLocationShare,
            ),

            // Campo de texto
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),

            const SizedBox(width: 8),

            // Botón de enviar con animación
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: isComposing
                    ? const Color(0xFF4A7AA7)
                    : Colors.grey.shade400,
                child: IconButton(
                  icon: Icon(
                    isComposing ? Icons.send : Icons.mic,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: isComposing ? onSend : _startVoiceMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startVoiceMessage() {
    // Implementar mensaje de voz
    print('Iniciando grabación de voz...');
  }
}

// Widget para mostrar cada mensaje
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwn;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: Row(
          mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isOwn) ...[
              _buildAvatar(),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: isOwn
                      ? const Color(0xFF4A7AA7)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isOwn ? 18 : 4),
                    bottomRight: Radius.circular(isOwn ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.replyToId != null) _buildReplyPreview(),
                    _buildMessageContent(),
                    const SizedBox(height: 4),
                    _buildMessageInfo(),
                  ],
                ),
              ),
            ),

            if (isOwn) ...[
              const SizedBox(width: 8),
              _buildDeliveryStatus(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey.shade400,
      child: const Icon(Icons.person, size: 12, color: Colors.white),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isOwn
            ? Colors.white.withOpacity(0.2)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isOwn ? Colors.white : const Color(0xFF4A7AA7),
            width: 3,
          ),
        ),
      ),
      child: Text(
        'Respondiendo a mensaje...',
        style: TextStyle(
          color: isOwn ? Colors.white70 : Colors.grey.shade600,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isOwn ? Colors.white : Colors.black87,
            fontSize: 16,
            height: 1.3,
          ),
        );

      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachments.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.attachments.first,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  color: isOwn ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        );

      case MessageType.location:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOwn
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: isOwn ? Colors.white : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.locationName ?? 'Ubicación compartida',
                      style: TextStyle(
                        color: isOwn ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.map, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca para ver en el mapa',
                style: TextStyle(
                  color: isOwn ? Colors.white70 : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      case MessageType.petInfo:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOwn
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pets,
                size: 24,
                color: isOwn ? Colors.white : const Color(0xFF4A7AA7),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isOwn ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Información de mascota',
                      style: TextStyle(
                        color: isOwn ? Colors.white70 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case MessageType.matchInfo:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOwn
                ? Colors.white.withOpacity(0.1)
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 24,
                color: isOwn ? Colors.white : Colors.red,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Es un Match!',
                      style: TextStyle(
                        color: isOwn ? Colors.white : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ahora pueden chatear',
                      style: TextStyle(
                        color: isOwn ? Colors.white70 : Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isOwn ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
    }
  }

  Widget _buildMessageInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            fontSize: 11,
            color: isOwn ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        if (isOwn) ...[
          const SizedBox(width: 4),
          _buildDeliveryStatusInline(),
        ],
      ],
    );
  }

  Widget _buildDeliveryStatus() {
    return Column(
      children: [
        _buildStatusIcon(),
        const SizedBox(height: 2),
        Text(
          _formatTime(message.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStatusInline() {
    return _buildStatusIcon();
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey.shade400;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey.shade400;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue.shade400;
        break;
    }

    return Icon(
      icon,
      size: 12,
      color: color,
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}