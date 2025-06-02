import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../pets/my_pets.dart';
import '../social/discover_screen.dart';
import '../social/feed_screen.dart';
import '../social/post_create_screen.dart';
import '../matches/match_screen.dart';
import '../social/profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../ai/ai_hub_screen.dart'; // NUEVO IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<Widget> _screens = [
    const FeedScreen(),         // 0: Inicio
    const DiscoverScreen(),     // 1: Explorar
    const ChatListScreen(),     // 2: Chats
    const MatchScreen(),        // 3: Matches
    const MyPetsScreen(),       // 4: Mascotas
    const ProfileScreen(),      // 5: Perfil
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _fabAnimationController.forward();

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  // Inicializar todos los providers necesarios
  Future<void> _initializeProviders() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      print('🚀 HomeScreen: Inicializando providers...');

      // Verificar que hay un usuario autenticado
      if (authProvider.currentUser != null) {
        final userId = authProvider.currentUser!.id;
        print('✅ Usuario autenticado: $userId');

        // 1. Cargar información del usuario actual en cache
        await userProvider.getUserById(userId);
        print('✅ Usuario actual cargado en cache');

        // 2. Cargar mascotas del usuario
        petProvider.loadUserPets(userId);
        print('✅ Cargando mascotas del usuario...');

        // 3. Cargar feed de posts
        await postProvider.loadFeedPosts(refresh: true);
        print('✅ Posts del feed cargados: ${postProvider.feedPosts.length}');

        // 4. Precargar información de usuarios de los posts
        final authorIds = postProvider.feedPosts
            .map((post) => post.authorId)
            .toSet()
            .toList();

        if (authorIds.isNotEmpty) {
          await userProvider.preloadUsersForFeed(authorIds);
          print('✅ Información de ${authorIds.length} autores cargada');
        }

        // 5. Cargar matches del usuario
        await matchProvider.loadUserMatches(userId);
        print('✅ Matches del usuario cargados: ${matchProvider.userMatches.length}');

        // 6. Cargar usuarios sugeridos para descubrir
        await userProvider.loadSuggestedUsers();
        print('✅ Usuarios sugeridos cargados: ${userProvider.suggestedUsers.length}');

        // 7. Cargar chats del usuario
        await chatProvider.loadUserChats(userId);
        print('✅ Chats del usuario cargados: ${chatProvider.userChats.length}');

        print('🎉 HomeScreen: Inicialización completa');
      } else {
        print('❌ No hay usuario autenticado');
      }
    } catch (e) {
      print('❌ Error inicializando providers: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(), // NUEVO: AppBar con botón AI
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _onTabChanged(index);
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _shouldShowFab() ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // NUEVO: AppBar con botón de IA
  PreferredSizeWidget? _buildAppBar() {
    // Solo mostrar AppBar en ciertas pestañas
    if (_currentIndex == 0 || _currentIndex == 4) { // Feed y Mascotas
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Botón de IA
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A7AA7),
                  const Color(0xFF6B9BD1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _openAIHub,
              icon: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Reconocimiento IA',
            ),
          ),
        ],
      );
    }
    return null;
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Inicio';
      case 4:
        return 'Mis Mascotas';
      default:
        return 'PetID';
    }
  }

  // NUEVO: Abrir AI Hub
  void _openAIHub() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AIHubScreen(),
      ),
    );
  }

  // Determinar si mostrar el FAB según la pestaña activa
  bool _shouldShowFab() {
    return _currentIndex == 0; // Solo mostrar en Feed (Inicio)
  }

  // Manejar cambios de pestaña para cargar datos específicos
  void _onTabChanged(int index) {
    switch (index) {
      case 0: // Feed (Inicio)
        _refreshFeedIfNeeded();
        break;
      case 1: // Explorar
        _loadSuggestedUsersIfNeeded();
        break;
      case 2: // Chats
        _refreshChatsIfNeeded();
        break;
      case 3: // Matches
        _loadMatchesIfNeeded();
        break;
      case 4: // Mascotas
        _refreshPetsIfNeeded();
        break;
      case 5: // Perfil
        _loadProfileStats();
        break;
    }
  }

  Future<void> _refreshFeedIfNeeded() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (postProvider.feedPosts.isEmpty) {
      await postProvider.loadFeedPosts(refresh: true);

      final authorIds = postProvider.feedPosts
          .map((post) => post.authorId)
          .toSet()
          .toList();

      if (authorIds.isNotEmpty) {
        await userProvider.preloadUsersForFeed(authorIds);
      }
    }
  }

  Future<void> _loadSuggestedUsersIfNeeded() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.suggestedUsers.isEmpty) {
      await userProvider.loadSuggestedUsers();
    }
  }

  Future<void> _refreshChatsIfNeeded() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser != null && chatProvider.userChats.isEmpty) {
      await chatProvider.refreshChats(authProvider.currentUser!.id);
    }
  }

  Future<void> _loadMatchesIfNeeded() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);

    if (authProvider.currentUser != null && matchProvider.userMatches.isEmpty) {
      await matchProvider.loadUserMatches(authProvider.currentUser!.id);
    }
  }

  void _refreshPetsIfNeeded() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petProvider = Provider.of<PetProvider>(context, listen: false);

    if (authProvider.currentUser != null && petProvider.userPets.isEmpty) {
      petProvider.loadUserPets(authProvider.currentUser!.id);
    }
  }

  Future<void> _loadProfileStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await userProvider.getUserStats(authProvider.currentUser!.id);
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Inicio'),
              _buildNavItem(1, Icons.explore, 'Explorar'),
              _buildNavItem(2, Icons.chat_bubble, 'Chats'),
              _buildNavItem(3, Icons.favorite, 'Matches'),
              _buildNavItem(4, Icons.pets, 'Mascotas'),
              _buildNavItem(5, Icons.person, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    Widget iconWidget = Icon(
      icon,
      color: isSelected
          ? const Color(0xFF4A7AA7)
          : Colors.grey.shade400,
      size: 24,
    );

    if (index == 2) { // Chats tab
      iconWidget = Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final unreadCount = chatProvider.totalUnreadCount;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF4A7AA7)
                    : Colors.grey.shade400,
                size: 24,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
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
                      unreadCount > 99 ? '99+' : '$unreadCount',
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
          );
        },
      );
    } else if (index == 3) { // Matches tab
      iconWidget = Consumer<MatchProvider>(
        builder: (context, matchProvider, child) {
          final hasPendingRequests = matchProvider.pendingMatches.isNotEmpty;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF4A7AA7)
                    : Colors.grey.shade400,
                size: 24,
              ),
              if (hasPendingRequests)
                Positioned(
                  right: -6,
                  top: -4,
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
                      '${matchProvider.pendingMatches.length}',
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
          );
        },
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4A7AA7)
                      : Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton.extended(
          onPressed: _createPost,
          backgroundColor: const Color(0xFF4A7AA7),
          elevation: 8,
          icon: const Icon(
            Icons.add,
            color: Colors.white,
            size: 24,
          ),
          label: const Text(
            'Publicar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();

    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _createPost() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PostCreateScreen(),
      ),
    ).then((_) {
      _refreshFeedAfterPost();
    });
  }

  Future<void> _refreshFeedAfterPost() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await postProvider.loadFeedPosts(refresh: true);

    final authorIds = postProvider.feedPosts
        .map((post) => post.authorId)
        .toSet()
        .toList();

    if (authorIds.isNotEmpty) {
      await userProvider.preloadUsersForFeed(authorIds);
    }

    print('🔄 Feed refrescado después de crear post');
  }
}