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

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFF4A7AA7), // Color original
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: Container(
                color: const Color(0xFFF8F9FA),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatsTab(),
                    _buildGroupsTab(),
                    _buildCommunitiesTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getFloatingActionButtonAction(),
        backgroundColor: const Color(0xFF4A7AA7), // Color original
        child: Icon(_getFloatingActionButtonIcon(), color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: const Color(0xFF4A7AA7), // Color original
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'PedID',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Implementar búsqueda
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              // Implementar menú
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF4A7AA7), // Color original
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('CHATS'),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final unreadCount = chatProvider.totalUnreadCount;
                    if (unreadCount > 0) {
                      return Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Color(0xFF4A7AA7), // Color original
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
          ),
          const Tab(text: 'GRUPOS'),
          const Tab(text: 'COMUNIDADES'),
        ],
      ),
    );
  }

  // Método para obtener la acción del FAB según el tab activo
  VoidCallback _getFloatingActionButtonAction() {
    switch (_tabController.index) {
      case 0: // CHATS
        return _startNewChat;
      case 1: // GRUPOS
        return _createNewGroup;
      case 2: // COMUNIDADES
        return _joinCommunity;
      default:
        return _startNewChat;
    }
  }

  // Método para obtener el ícono del FAB según el tab activo
  IconData _getFloatingActionButtonIcon() {
    switch (_tabController.index) {
      case 0: // CHATS
        return Icons.edit;
      case 1: // GRUPOS
        return Icons.group_add;
      case 2: // COMUNIDADES
        return Icons.add;
      default:
        return Icons.edit;
    }
  }

  Widget _buildChatsTab() {
    return Column(
      children: [
        _buildSearchBar('Buscar chats...'),
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.isLoading && chatProvider.userChats.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A7AA7)), // Color original
                );
              }

              if (chatProvider.errorMessage != null) {
                return _buildErrorState(chatProvider.errorMessage!);
              }

              if (chatProvider.userChats.isEmpty) {
                return _buildEmptyChatsState();
              }

              // Filtrar chats por búsqueda
              final filteredChats = _filterChats(chatProvider.userChats);

              if (filteredChats.isEmpty) {
                return _buildNoResultsState('No se encontraron chats');
              }

              return RefreshIndicator(
                onRefresh: _refreshChats,
                color: const Color(0xFF4A7AA7), // Color original
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
    );
  }

  Widget _buildGroupsTab() {
    return Column(
      children: [
        _buildSearchBar('Buscar grupos...'),
        Expanded(
          child: _buildGroupsList(),
        ),
      ],
    );
  }

  Widget _buildCommunitiesTab() {
    return Column(
      children: [
        _buildSearchBar('Buscar comunidades...'),
        Expanded(
          child: _buildCommunitiesList(),
        ),
      ],
    );
  }

  Widget _buildGroupsList() {
    // Lista de grupos (puedes reemplazar esto con datos reales de un provider)
    final groups = [
      {
        'name': 'Grupo Mascotas Perdidas',
        'lastMessage': 'Juan: ¿Alguien ha visto a mi perro?',
        'time': '14:30',
        'icon': Icons.pets,
        'unreadCount': 3,
        'hasUnread': true,
      },
      {
        'name': 'Veterinarios Locales',
        'lastMessage': 'Dr. Ana: Consultas disponibles esta semana',
        'time': '12:15',
        'icon': Icons.local_hospital,
        'unreadCount': 1,
        'hasUnread': false,
      },
      {
        'name': 'Cuidado de Cachorros',
        'lastMessage': 'María: Tips para entrenar a tu cachorro',
        'time': '10:45',
        'icon': Icons.pets,
        'unreadCount': 0,
        'hasUnread': false,
      },
    ];

    // Filtrar grupos por búsqueda
    final filteredGroups = groups.where((group) {
      if (_searchQuery.isEmpty) return true;
      return group['name'].toString().toLowerCase().contains(_searchQuery) ||
          group['lastMessage'].toString().toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredGroups.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsState('No se encontraron grupos');
    }

    if (filteredGroups.isEmpty) {
      return _buildEmptyGroupsState();
    }

    return ListView.builder(
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        return _buildGroupItem(
          group['name'] as String,
          group['lastMessage'] as String,
          group['time'] as String,
          group['icon'] as IconData,
          group['unreadCount'] as int,
          group['hasUnread'] as bool,
        );
      },
    );
  }

  Widget _buildCommunitiesList() {
    // Lista de comunidades (puedes reemplazar esto con datos reales de un provider)
    final communities = [
      {
        'name': 'Comunidad de Perros',
        'description': 'Tips y consejos para el cuidado de perros',
        'time': '16:45',
        'icon': Icons.pets,
        'memberCount': 12,
        'hasUnread': true,
      },
      {
        'name': 'Comunidad de Gatos',
        'description': 'Todo sobre el mundo felino',
        'time': '09:22',
        'icon': Icons.favorite,
        'memberCount': 5,
        'hasUnread': false,
      },
      {
        'name': 'Aves Exóticas',
        'description': 'Comunidad dedicada al cuidado de aves',
        'time': '07:15',
        'icon': Icons.flutter_dash,
        'memberCount': 8,
        'hasUnread': false,
      },
    ];

    // Filtrar comunidades por búsqueda
    final filteredCommunities = communities.where((community) {
      if (_searchQuery.isEmpty) return true;
      return community['name'].toString().toLowerCase().contains(_searchQuery) ||
          community['description'].toString().toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredCommunities.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoResultsState('No se encontraron comunidades');
    }

    if (filteredCommunities.isEmpty) {
      return _buildEmptyCommunitiesState();
    }

    return ListView.builder(
      itemCount: filteredCommunities.length,
      itemBuilder: (context, index) {
        final community = filteredCommunities[index];
        return _buildCommunityItem(
          community['name'] as String,
          community['description'] as String,
          community['time'] as String,
          community['icon'] as IconData,
          community['memberCount'] as int,
          community['hasUnread'] as bool,
        );
      },
    );
  }

  Widget _buildSearchBar(String hintText) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          icon: const Icon(Icons.search, color: Colors.grey),
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
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: otherUser?.photoURL != null
                  ? NetworkImage(otherUser!.photoURL!)
                  : null,
              backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1), // Color original
              child: otherUser?.photoURL == null
                  ? Text(
                otherUser?.displayName.isNotEmpty == true
                    ? otherUser!.displayName.substring(0, 1).toUpperCase()
                    : otherUserId.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF4A7AA7), // Color original
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _getChatTitle(chat, otherUser, otherUserId),
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTime(chat.updatedAt),
                  style: TextStyle(
                    color: hasUnread ? const Color(0xFF4A7AA7) : Colors.grey.shade500, // Color original
                    fontSize: 12,
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    _getLastMessageText(chat),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A7AA7), // Color original
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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

  Widget _buildEmptyChatsState() {
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
              backgroundColor: const Color(0xFF4A7AA7), // Color original
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

  Widget _buildEmptyGroupsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Únete a un grupo!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conecta con grupos de tu interés',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewGroup,
            icon: const Icon(Icons.group_add),
            label: const Text('Crear grupo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7AA7), // Color original
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

  Widget _buildEmptyCommunitiesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '¡Explora comunidades!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Encuentra comunidades que te interesen',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _joinCommunity,
            icon: const Icon(Icons.add),
            label: const Text('Explorar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7AA7), // Color original
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

  Widget _buildNoResultsState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
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
      return 'ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['dom', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb'];
      return days[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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

  void _createNewGroup() {
    // Navegar a pantalla de creación de grupos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de crear grupo próximamente')),
    );
  }

  void _joinCommunity() {
    // Navegar a pantalla de comunidades disponibles
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de comunidades próximamente')),
    );
  }

  Widget _buildGroupItem(String groupName, String lastMessage, String time,
      IconData icon, int unreadCount, bool hasUnread) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
          child: Icon(
            icon,
            color: const Color(0xFF4A7AA7),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                groupName,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: hasUnread ? const Color(0xFF4A7AA7) : Colors.grey.shade500,
                fontSize: 12,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF4A7AA7),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Navegar al grupo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Abriendo grupo: $groupName')),
          );
        },
        onLongPress: () {
          _showGroupOptions(groupName);
        },
      ),
    );
  }

  Widget _buildCommunityItem(String communityName, String description, String time,
      IconData icon, int memberCount, bool hasUnread) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
          child: Icon(
            icon,
            color: const Color(0xFF4A7AA7),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                communityName,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: hasUnread ? const Color(0xFF4A7AA7) : Colors.grey.shade500,
                fontSize: 12,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$memberCount miembros',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFF4A7AA7),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    memberCount > 9 ? '9+' : '$memberCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // Navegar a la comunidad
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Abriendo comunidad: $communityName')),
          );
        },
        onLongPress: () {
          _showCommunityOptions(communityName);
        },
      ),
    );
  }

  void _showGroupOptions(String groupName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Información del grupo'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Información de: $groupName')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Silenciar grupo'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Grupo silenciado')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Salir del grupo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmLeaveGroup(groupName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCommunityOptions(String communityName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Información de la comunidad'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Información de: $communityName')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Ver miembros'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lista de miembros')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Silenciar comunidad'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comunidad silenciada')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Salir de la comunidad', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmLeaveCommunity(communityName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveGroup(String groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: Text('¿Estás seguro de que quieres salir del grupo "$groupName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Has salido del grupo: $groupName')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveCommunity(String communityName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de la comunidad'),
        content: Text('¿Estás seguro de que quieres salir de la comunidad "$communityName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Has salido de la comunidad: $communityName')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}