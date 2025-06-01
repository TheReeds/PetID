import 'package:apppetid/presentation/screens/matches/user_discovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/pet_model.dart';
import 'pet_discovery_screen.dart';
import 'match_requests_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await matchProvider.loadUserMatches(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAppBar(),
              _buildTabBar(),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPetDiscoveryTab(),      // 0: Mascotas
              _buildUserDiscoveryTab(),     // 1: Usuarios (NUEVO)
              _buildMatchesTab(),           // 2: Matches
              _buildRequestsTab(),          // 3: Solicitudes
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A7AA7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite,
                color: Color(0xFF4A7AA7),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'PetMatch',
              style: TextStyle(
                color: Color(0xFF4A7AA7),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: Color(0xFF4A7AA7)),
          onPressed: _showFilterOptions,
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF4A7AA7)),
          onPressed: _showNotifications,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A7AA7),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4A7AA7),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Mascotas'),
            Tab(text: 'Usuarios'),
            Tab(text: 'Matches'),
            Tab(text: 'Solicitudes'),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildPetDiscoveryTab() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        if (petProvider.userPets.isEmpty) {
          return _buildNoPetsState();
        }

        return Column(
          children: [
            _buildPetSelector(),
            Expanded(
              child: PetDiscoveryScreen(
                selectedPet: petProvider.userPets.first,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    return Consumer<MatchProvider>(
      builder: (context, matchProvider, child) {
        if (matchProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
          );
        }

        if (matchProvider.acceptedMatches.isEmpty) {
          return _buildNoMatchesState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matchProvider.acceptedMatches.length,
          itemBuilder: (context, index) {
            return _buildMatchCard(matchProvider.acceptedMatches[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<MatchProvider>(
      builder: (context, matchProvider, child) {
        if (matchProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
          );
        }

        return MatchRequestsScreen(
          pendingMatches: matchProvider.pendingMatches,
        );
      },
    );
  }

  Widget _buildPetSelector() {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        return Container(
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
              CircleAvatar(
                radius: 24,
                backgroundImage: petProvider.userPets.isNotEmpty &&
                    petProvider.userPets.first.profilePhoto != null
                    ? NetworkImage(petProvider.userPets.first.profilePhoto!)
                    : null,
                backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                child: petProvider.userPets.isEmpty ||
                    petProvider.userPets.first.profilePhoto == null
                    ? const Icon(Icons.pets, color: Color(0xFF4A7AA7))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petProvider.userPets.isNotEmpty
                          ? 'Buscando para ${petProvider.userPets.first.name}'
                          : 'Selecciona una mascota',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (petProvider.userPets.isNotEmpty)
                      Text(
                        '${petProvider.userPets.first.breed} • ${petProvider.userPets.first.displayAge}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (petProvider.userPets.length > 1)
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Color(0xFF4A7AA7)),
                  onPressed: _showPetSelector,
                ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildUserDiscoveryTab() {
    return const UserDiscoveryScreen();
  }
  Widget _buildMatchCard(MatchModel match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          _buildMatchHeader(match),
          _buildMatchContent(match),
          _buildMatchActions(match),
        ],
      ),
    );
  }

  Widget _buildMatchHeader(MatchModel match) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A7AA7).withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getMatchTypeColor(match.type),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getMatchTypeText(match.type),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _formatMatchDate(match.createdAt),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchContent(MatchModel match) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (match.isPetMatch) ...[
            // UI para matches de mascotas (código existente)
            Row(
              children: [
                _buildPetInfo(match.fromPetId!, isOwner: true),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                _buildPetInfo(match.toPetId!, isOwner: false),
              ],
            ),
          ] else if (match.isUserMatch) ...[
            // NUEVA UI para matches de usuarios
            _buildUserMatchInfo(match),
          ],

          if (match.message != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensaje:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match.message!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildUserMatchInfo(MatchModel match) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final fromUser = userProvider.getUserForPost(match.fromUserId);
        final toUser = userProvider.getUserForPost(match.toUserId);

        return Row(
          children: [
            Expanded(child: _buildUserInfoCard(fromUser, 'Solicitante')),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getMatchTypeColor(match.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getMatchTypeIcon(match.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            Expanded(child: _buildUserInfoCard(toUser, 'Destinatario')),
          ],
        );
      },
    );
  }
  Widget _buildUserInfoCard(dynamic user, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
            child: user?.photoURL == null
                ? const Icon(Icons.person, color: Color(0xFF4A7AA7))
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            user?.displayName ?? 'Usuario',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getMatchTypeIcon(MatchType type) {
    switch (type) {
      case MatchType.mating:
        return Icons.favorite;
      case MatchType.playdate:
        return Icons.sports_tennis;
      case MatchType.adoption:
        return Icons.home;
      case MatchType.friendship:
        return Icons.people;
    // NUEVOS ICONOS PARA USUARIOS:
      case MatchType.petOwnerFriendship:
        return Icons.people;
      case MatchType.petActivity:
        return Icons.pets;
      case MatchType.petCare:
        return Icons.medical_services;
      case MatchType.socialMeet:
        return Icons.coffee;
    }
  }

  Widget _buildPetInfo(String petId, {required bool isOwner}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
              child: const Icon(Icons.pets, color: Color(0xFF4A7AA7)),
            ),
            const SizedBox(height: 8),
            Text(
              'Mascota ${petId.substring(0, 8)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              isOwner ? 'Tu mascota' : 'Mascota match',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchActions(MatchModel match) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _chatWithMatch(match),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4A7AA7),
                side: const BorderSide(color: Color(0xFF4A7AA7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _viewMatchDetails(match),
              icon: const Icon(Icons.info_outline),
              label: const Text('Detalles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7AA7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPetsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Agrega tu primera mascota',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Necesitas registrar al menos una mascota para comenzar a hacer matches',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddPet,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Mascota'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7AA7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes matches',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Explora la pestaña "Descubrir" para encontrar mascotas compatibles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.explore),
              label: const Text('Explorar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7AA7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchTypeColor(MatchType type) {
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    return matchProvider.getMatchTypeColor(type);
  }

  String _getMatchTypeText(MatchType type) {
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    return matchProvider.getMatchTypeText(type);
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filtros de Búsqueda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Implementar filtros
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones próximamente')),
    );
  }

  void _showPetSelector() {
    // Implementar selector de mascotas
  }

  void _navigateToAddPet() {
    // Navegar a agregar mascota
    Navigator.of(context).pushNamed('/add-pet');
  }

  void _chatWithMatch(MatchModel match) {
    // Implementar chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat próximamente')),
    );
  }

  void _viewMatchDetails(MatchModel match) {
    // Implementar detalles del match
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detalles próximamente')),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}