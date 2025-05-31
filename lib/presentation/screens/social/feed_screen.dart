// lib/presentation/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/pet_provider.dart';

import '../../../data/models/post_model.dart';
import '../../providers/auth_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  // Datos de ejemplo para el feed
  final List<PostModel> _posts = [
    PostModel(
      id: '1',
      authorId: 'user1',
      petId: 'pet1',
      type: PostType.photo,
      content: '¡Firulais disfrutando del parque! 🐕 #VivaLosDogs #ParqueDiversión',
      imageUrls: ['https://placedog.net/600/400?id=1'],
      hashtags: ['VivaLosDogs', 'ParqueDiversión'],
      likes: ['user2', 'user3', 'user4'],
      commentsCount: 12,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PostModel(
      id: '2',
      authorId: 'user2',
      petId: 'pet2',
      type: PostType.photo,
      content: 'Michi encontró su lugar favorito para dormir 😸 #GatoVida #Siesta',
      imageUrls: ['https://placedog.net/600/400?id=2'],
      hashtags: ['GatoVida', 'Siesta'],
      likes: ['user1', 'user3'],
      commentsCount: 8,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PostModel(
      id: '3',
      authorId: 'user3',
      type: PostType.announcement,
      content: '🚨 MASCOTA PERDIDA 🚨\n\nSe perdió Max, un Golden Retriever de 3 años en el distrito de Miraflores. Si lo ves, por favor contacta conmigo. #MascotaPerdida #Ayuda',
      likes: ['user1', 'user2', 'user4', 'user5'],
      commentsCount: 25,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
  ];

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

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      postProvider.loadFeedPosts(refresh: true);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<PostProvider>(
          builder: (context, postProvider, child) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(),
                _buildStoriesSection(),
                _buildQuickActions(),
                if (postProvider.isLoading && postProvider.feedPosts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
                    ),
                  )
                else if (postProvider.feedPosts.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        if (index < postProvider.feedPosts.length) {
                          return _buildPostCard(postProvider.feedPosts[index]);
                        }
                        return _buildLoadMoreCard();
                      },
                      childCount: postProvider.feedPosts.length + 1,
                    ),
                  ),
              ],
            );
          },
        ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
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
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF4A7AA7)),
                onPressed: () => _showMessages(),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://placedog.net/80/80?id=${post.authorId}'),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuario ${post.authorId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatTime(post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
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
  }

  Widget _buildPostContent(PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        post.content,
        style: const TextStyle(
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildPostImage(PostModel post) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          post.imageUrls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildPostActions(PostModel post) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleLike(post),
            child: Row(
              children: [
                Icon(
                  post.isLikedBy('currentUserId') ? Icons.favorite : Icons.favorite_border,
                  color: post.isLikedBy('currentUserId') ? Colors.red : Colors.grey,
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
          const Spacer(),
          GestureDetector(
            onTap: () => _savePost(post),
            child: Icon(Icons.bookmark_border, color: Colors.grey.shade600, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreCard() {
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones próximamente')),
    );
  }

  void _showMessages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensajes próximamente')),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comentarios próximamente')),
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
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Reportar'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquear usuario'),
              onTap: () => Navigator.pop(context),
            ),
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
}