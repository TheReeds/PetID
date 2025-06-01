// lib/presentation/screens/chat/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/models/chat_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true; // Mantener estado al cambiar de tab

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading && chatProvider.userChats.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
                    );
                  }

                  if (chatProvider.errorMessage != null) {
                    return _buildErrorState(chatProvider.errorMessage!);
                  }

                  if (chatProvider.userChats.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Filtrar chats por búsqueda
                  final filteredChats = _filterChats(chatProvider.userChats);

                  if (filteredChats.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshChats,
                    color: const Color(0xFF4A7AA7),
                    child: ListView.builder(
                      itemCount: filteredChats.length,
                      itemBuilder: (context, index) {
                        return _buildChatItem(filteredChats[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        backgroundColor: const Color(0xFF4A7AA7),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Chats',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A7AA7),
            ),
          ),
          const Spacer(),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final unreadCount = chatProvider.totalUnreadCount;

              if (unreadCount > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unreadCount nuevos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar conversaciones...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final currentUserId = authProvider.currentUser?.id ?? '';
        final otherUserId = chat.getOtherParticipant(currentUserId);
        final otherUser = userProvider.getUserForPost(otherUserId);
        final unreadCount = chat.getUnreadCountForUser(currentUserId);
        final hasUnread = unreadCount > 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
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
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _getChatTitle(chat, otherUser, otherUserId),
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (otherUser?.isVerified == true)
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: Color(0xFF4A7AA7),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _getLastMessageText(chat),
                  style: TextStyle(
                    color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildChatTypeIcon(chat),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(chat.updatedAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _openChat(chat),
            onLongPress: () => _showChatOptions(chat),
          ),
        );
      },
    );
  }

  Widget _buildChatTypeIcon(ChatModel chat) {
    IconData icon;
    Color color;

    switch (chat.type) {
      case ChatType.match:
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case ChatType.postInquiry:
        icon = Icons.post_add;
        color = Colors.blue;
        break;
      case ChatType.direct:
        icon = Icons.chat;
        color = Colors.grey;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Empieza a conversar!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conecta con otros dueños de mascotas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewChat,
            icon: const Icon(Icons.chat),
            label: const Text('Nuevo chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7AA7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
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
            'Error al cargar chats',
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
            onPressed: _refreshChats,
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

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No se encontraron chats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos de búsqueda',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  List<ChatModel> _filterChats(List<ChatModel> chats) {
    if (_searchQuery.isEmpty) return chats;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id ?? '';

    return chats.where((chat) {
      final otherUserId = chat.getOtherParticipant(currentUserId);
      final otherUser = userProvider.getUserForPost(otherUserId);

      // Buscar en nombre del chat
      if (chat.chatName.toLowerCase().contains(_searchQuery)) {
        return true;
      }

      // Buscar en nombre del otro usuario
      if (otherUser != null) {
        final displayName = otherUser.displayName.toLowerCase();
        final fullName = (otherUser.fullName ?? '').toLowerCase();

        if (displayName.contains(_searchQuery) || fullName.contains(_searchQuery)) {
          return true;
        }
      }

      // Buscar en el último mensaje
      if (chat.lastMessage?.content.toLowerCase().contains(_searchQuery) == true) {
        return true;
      }

      return false;
    }).toList();
  }

  String _getChatTitle(ChatModel chat, UserModel? otherUser, String otherUserId) {
    if (chat.chatName.isNotEmpty && chat.chatName != 'Chat de Match' &&
        chat.chatName != 'Consulta sobre publicación' && chat.chatName != 'Chat directo') {
      return chat.chatName;
    }

    if (otherUser != null) {
      return otherUser.displayName.isNotEmpty
          ? otherUser.displayName
          : otherUser.fullName ?? 'Usuario';
    }

    return 'Usuario ${otherUserId.substring(0, 8)}';
  }

  String _getLastMessageText(ChatModel chat) {
    if (chat.lastMessage == null) {
      return 'Sin mensajes';
    }

    final message = chat.lastMessage!;

    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return message.content.isEmpty ? '📷 Imagen' : '📷 ${message.content}';
      case MessageType.location:
        return '📍 Ubicación compartida';
      case MessageType.petInfo:
        return '🐾 Información de mascota';
      case MessageType.matchInfo:
        return '❤️ Información de match';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Future<void> _refreshChats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await chatProvider.refreshChats(authProvider.currentUser!.id);
    }
  }

  void _openChat(ChatModel chat) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      Navigator.of(context).pushNamed(
        '/chat',
        arguments: {
          'chatId': chat.id,
          'currentUserId': authProvider.currentUser!.id,
        },
      );
    }
  }

  void _showChatOptions(ChatModel chat) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id ?? '';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Marcar como leído'),
              onTap: () {
                Navigator.pop(context);
                _markAsRead(chat, currentUserId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Silenciar'),
              onTap: () {
                Navigator.pop(context);
                _muteChat(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteChat(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _markAsRead(ChatModel chat, String userId) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.markMessagesAsRead(chat.id, userId);
  }

  void _muteChat(ChatModel chat) {
    // Implementar funcionalidad de silenciar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de silenciar próximamente')),
    );
  }

  void _confirmDeleteChat(ChatModel chat) {
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
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(chat);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteChat(ChatModel chat) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.deleteChat(chat.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat eliminado exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el chat')),
      );
    }
  }

  void _startNewChat() {
    // Navegar a pantalla de usuarios para iniciar nuevo chat
    Navigator.of(context).pushNamed('/users');
  }
}