// lib/presentation/screens/social/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart'; // Nuevo import
import '../../../data/models/post_model.dart';
import '../chat/chat_screen.dart';
import 'comments_screen.dart'; // Nuevo import

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Configurar scroll listener para paginación
    _scrollController.addListener(_onScroll);

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Cargar más posts cuando esté cerca del final
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      if (postProvider.hasMorePosts && !postProvider.isLoading) {
        postProvider.loadFeedPosts(refresh: false);
      }
    }
  }

  Future<void> _loadInitialData() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Cargar posts
    await postProvider.loadFeedPosts(refresh: true);

    // Precargar información de usuarios para los posts
    final authorIds = postProvider.feedPosts.map((post) => post.authorId).toList();
    if (authorIds.isNotEmpty) {
      await userProvider.preloadUsersForFeed(authorIds);
    }
  }

  Future<void> _refreshFeed() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Refrescar posts
      await postProvider.loadFeedPosts(refresh: true);

      // Precargar usuarios para los nuevos posts
      final authorIds = postProvider.feedPosts.map((post) => post.authorId).toList();
      if (authorIds.isNotEmpty) {
        await userProvider.preloadUsersForFeed(authorIds);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<PostProvider>(
          builder: (context, postProvider, child) {
            return RefreshIndicator(
              onRefresh: _refreshFeed,
              color: const Color(0xFF4A7AA7),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(),
                  _buildStoriesSection(),
                  _buildQuickActions(),

                  // Mostrar error si existe
                  if (postProvider.state == PostState.error)
                    SliverToBoxAdapter(
                      child: _buildErrorCard(postProvider.errorMessage ?? 'Error desconocido'),
                    ),

                  // Mostrar loading inicial
                  if (postProvider.isLoading && postProvider.feedPosts.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
                      ),
                    )
                  // Mostrar estado vacío
                  else if (postProvider.feedPosts.isEmpty && !postProvider.isLoading)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  // Mostrar posts
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          if (index < postProvider.feedPosts.length) {
                            return _buildPostCard(postProvider.feedPosts[index]);
                          }
                          // Mostrar loading para más posts o mensaje de fin
                          return _buildLoadMoreIndicator(postProvider);
                        },
                        childCount: postProvider.feedPosts.length + 1,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        return SliverAppBar(
          floating: true,
          backgroundColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              Text(
                'PetID',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A7AA7),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF4A7AA7)),
                onPressed: () => _showNotifications(),
              ),
              // NUEVO: Botón de mensajes con badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4A7AA7)),
                    onPressed: () => _showMessages(),
                  ),
                  if (chatProvider.totalUnreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          chatProvider.totalUnreadCount > 99
                              ? '99+'
                              : '${chatProvider.totalUnreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoriesSection() {
    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildAddStoryCard();
            }
            return _buildStoryCard(index);
          },
        ),
      ),
    );
  }

  Widget _buildAddStoryCard() {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7AA7).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4A7AA7),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.add,
              color: Color(0xFF4A7AA7),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu historia',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(int index) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4A7AA7),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                'https://placedog.net/120/120?id=${index + 10}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.pets, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mascota $index',
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                'Mascotas\nPerdidas',
                Icons.search,
                Colors.red,
                    () => _viewLostPets(),
              ),
            ),
            Expanded(
              child: _buildQuickAction(
                'Adopción',
                Icons.favorite,
                Colors.orange,
                    () => _viewAdoption(),
              ),
            ),
            Expanded(
              child: _buildQuickAction(
                'Veterinarios',
                Icons.medical_services,
                Colors.green,
                    () => _findVets(),
              ),
            ),
            Expanded(
              child: _buildQuickAction(
                'Eventos',
                Icons.event,
                Colors.blue,
                    () => _viewEvents(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(post),
          _buildPostContent(post),
          if (post.imageUrls.isNotEmpty) _buildPostImage(post),
          _buildPostActions(post),
        ],
      ),
    );
  }

  Widget _buildPostHeader(PostModel post) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.getUserForPost(post.authorId);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar del usuario - NUEVO: Clickeable para enviar mensaje
              GestureDetector(
                onTap: () => _showUserProfile(post.authorId, user),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                  child: user?.photoURL == null
                      ? Text(
                    user?.displayName.isNotEmpty == true
                        ? user!.displayName.substring(0, 1).toUpperCase()
                        : post.authorId.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF4A7AA7),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showUserProfile(post.authorId, user),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.displayName ?? user?.fullName ?? 'Usuario ${post.authorId.substring(0, 8)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user?.isVerified == true) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Color(0xFF4A7AA7),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            _formatTime(post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (post.petId != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Icon(
                              Icons.pets,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'con mascota',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          if (post.location != null) ...[
                            Text(
                              ' • ',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            if (post.locationName != null)
                              Flexible(
                                child: Text(
                                  post.locationName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (post.type == PostType.announcement)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'URGENTE',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () => _showPostOptions(post),
              ),
            ],
          ),
        );
      },
    );
  }

  // NUEVO: Metodo para mostrar perfil de usuario con opción de mensaje
  void _showUserProfile(String authorId, UserModel? user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id ?? '';

    // No mostrar opciones si es el mismo usuario
    if (authorId == currentUserId) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                    child: user?.photoURL == null
                        ? Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName.substring(0, 1).toUpperCase()
                          : authorId.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4A7AA7),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user?.displayName ?? user?.fullName ?? 'Usuario',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user?.isVerified == true) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: Color(0xFF4A7AA7),
                              ),
                            ],
                          ],
                        ),
                        if (user?.fullName != null && user!.fullName != user.displayName)
                          Text(
                            user.fullName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4A7AA7)),
              title: const Text('Enviar mensaje'),
              onTap: () {
                Navigator.pop(context);
                _sendMessageToUser(authorId, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF4A7AA7)),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context);
                _viewUserProfile(authorId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Reportar usuario'),
              onTap: () {
                Navigator.pop(context);
                _reportUser(authorId);
              },
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO: Metodo para enviar mensaje a usuario
  Future<void> _sendMessageToUser(String toUserId, UserModel? toUser) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    final currentUserId = authProvider.currentUser!.id;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
        ),
      );

      // Buscar chat existente o crear uno nuevo
      final existingChat = await chatProvider.findExistingChatBetweenUsers(
        [currentUserId, toUserId],
      );

      String chatId;
      if (existingChat != null) {
        chatId = existingChat.id;
      } else {
        final newChatId = await chatProvider.createDirectChat(
          fromUserId: currentUserId,
          toUserId: toUserId,
          initialMessage: '¡Hola! Vi tu publicación y me interesa conocer más.',
        );

        if (newChatId == null) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al crear la conversación')),
          );
          return;
        }
        chatId = newChatId;
      }

      Navigator.pop(context); // Cerrar loading

      // Navegar al chat usando argumentos
      Navigator.of(context).pushNamed(
        '/chat',
        arguments: {
          'chatId': chatId,
          'currentUserId': currentUserId,
        },
      );

    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _viewUserProfile(String userId) {
    // Navegar al perfil del usuario
    Navigator.of(context).pushNamed('/profile', arguments: userId);
  }

  void _reportUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar usuario'),
        content: const Text('¿Por qué quieres reportar a este usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporte enviado exitosamente')),
              );
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (post.hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: post.hashtags.map((hashtag) => GestureDetector(
                onTap: () => _searchHashtag(hashtag),
                child: Text(
                  '#$hashtag',
                  style: const TextStyle(
                    color: Color(0xFF4A7AA7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostImage(PostModel post) {
    if (post.imageUrls.length == 1) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            post.imageUrls.first,
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 250,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 250,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, size: 50, color: Colors.grey),
            ),
          ),
        ),
      );
    } else {
      // Múltiples imágenes - mostrar grid
      return Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: post.imageUrls.length >= 4 ? 2 : post.imageUrls.length,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: post.imageUrls.length > 4 ? 4 : post.imageUrls.length,
          itemBuilder: (context, index) {
            final isLastItem = index == 3 && post.imageUrls.length > 4;
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrls[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                if (isLastItem)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${post.imageUrls.length - 3}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }
  }

  Widget _buildPostActions(PostModel post) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.currentUser?.id ?? '';
        final isLiked = post.isLikedBy(currentUserId);
        final isOwnPost = currentUserId == post.authorId;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(post),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likes.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _showComments(post),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _sharePost(post),
                child: Icon(Icons.share_outlined, color: Colors.grey.shade600, size: 20),
              ),
              // NUEVO: Botón de mensaje directo si no es post propio
              if (!isOwnPost) ...[
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => _sendMessageFromPost(post),
                  child: Icon(Icons.send_outlined, color: Colors.grey.shade600, size: 20),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => _savePost(post),
                child: Icon(Icons.bookmark_border, color: Colors.grey.shade600, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  // NUEVO: Método para enviar mensaje desde post
  Future<void> _sendMessageFromPost(PostModel post) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    final user = userProvider.getUserForPost(post.authorId);
    await _sendMessageToUser(post.authorId, user);
  }

  Widget _buildLoadMoreIndicator(PostProvider postProvider) {
    if (postProvider.isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
        ),
      );
    } else if (!postProvider.hasMorePosts) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.pets, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                '¡Has visto todas las publicaciones!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vuelve más tarde para ver más contenido',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar publicaciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '¡Bienvenido a PetID!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sé el primero en compartir algo con la comunidad',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navegar a crear post
              Navigator.of(context).pushNamed('/create-post');
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear primera publicación'),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _searchHashtag(String hashtag) {
    // Implementar búsqueda por hashtag
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buscando posts con #$hashtag...')),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones próximamente')),
    );
  }

  // MODIFICADO: Navegar a la pestaña de chats
  void _showMessages() {
    // Navegar directamente a la lista de chats
    Navigator.of(context).pushNamed('/chat-list');
  }

  void _viewLostPets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mascotas perdidas próximamente')),
    );
  }

  void _viewAdoption() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adopción próximamente')),
    );
  }

  void _findVets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veterinarios próximamente')),
    );
  }

  void _viewEvents() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eventos próximamente')),
    );
  }

  void _toggleLike(PostModel post) {
    HapticFeedback.lightImpact();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      postProvider.toggleLike(post.id, authProvider.currentUser!.id);
    }
  }

  void _showComments(PostModel post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommentsScreen(post: post),
      ),
    );
  }

  void _sharePost(PostModel post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartir próximamente')),
    );
  }

  void _savePost(PostModel post) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardado próximamente')),
    );
  }

  void _showPostOptions(PostModel post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnPost = authProvider.currentUser?.id == post.authorId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnPost) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar edición
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(post);
                },
              ),
            ] else ...[
              // NUEVO: Opción de enviar mensaje al autor
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4A7AA7)),
                title: const Text('Enviar mensaje'),
                onTap: () {
                  Navigator.pop(context);
                  _sendMessageFromPost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Reportar'),
                onTap: () {
                  Navigator.pop(context);
                  _reportPost(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Bloquear usuario'),
                onTap: () => Navigator.pop(context),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.not_interested),
              title: const Text('No me interesa'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePost(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final postProvider = Provider.of<PostProvider>(context, listen: false);

              if (authProvider.currentUser != null) {
                final success = await postProvider.deletePost(post.id, authProvider.currentUser!.id);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publicación eliminada exitosamente')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _reportPost(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar publicación'),
        content: const Text('¿Por qué quieres reportar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final postProvider = Provider.of<PostProvider>(context, listen: false);

              if (authProvider.currentUser != null) {
                final success = await postProvider.reportPost(
                    post.id,
                    'Contenido inapropiado',
                    authProvider.currentUser!.id
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporte enviado exitosamente')),
                  );
                }
              }
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }
}