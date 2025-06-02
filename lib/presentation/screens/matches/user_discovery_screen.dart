import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/match_model.dart';
import 'dart:math' as math;

class UserDiscoveryScreen extends StatefulWidget {
  const UserDiscoveryScreen({super.key});

  @override
  State<UserDiscoveryScreen> createState() => _UserDiscoveryScreenState();
}

class _UserDiscoveryScreenState extends State<UserDiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  List<UserModel> _potentialMatches = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPotentialMatches();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPotentialMatches() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Cargar usuarios sugeridos
    await userProvider.loadSuggestedUsers();

    setState(() {
      _potentialMatches = userProvider.suggestedUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_potentialMatches.isEmpty) {
      return _buildNoMoreUsersState();
    }

    return Stack(
      children: [
        // Cards de usuarios
        for (int i = math.min(_currentIndex + 2, _potentialMatches.length - 1);
        i >= _currentIndex;
        i--)
          _buildUserCard(
            _potentialMatches[i],
            i - _currentIndex,
            i == _currentIndex,
          ),

        // Indicadores de acción
        if (_isDragging) _buildActionIndicators(),

        // Botones de acción
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildUserCard(UserModel user, int stackIndex, bool isActive) {
    final scale = 1.0 - (stackIndex * 0.05);
    final yOffset = stackIndex * 10.0;

    Widget card = Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20 + yOffset,
        bottom: 100,
      ),
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Imagen de fondo del usuario
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: user.photoURL != null
                      ? Image.network(
                    user.photoURL!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(user),
                  )
                      : _buildPlaceholderImage(user),
                ),

                // Gradient overlay
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),

                // Información del usuario
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildUserInfo(user),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isActive) {
      return GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
          _animationController.forward();
        },
        onPanUpdate: (details) {
          setState(() {
            _dragOffset += details.delta;
          });
        },
        onPanEnd: (details) {
          _isDragging = false;
          _animationController.reverse();

          const threshold = 100.0;
          if (_dragOffset.dx.abs() > threshold) {
            if (_dragOffset.dx > 0) {
              _handleLike(user);
            } else {
              _handlePass(user);
            }
          } else {
            setState(() {
              _dragOffset = Offset.zero;
            });
          }
        },
        child: Transform.translate(
          offset: _dragOffset,
          child: Transform.rotate(
            angle: _dragOffset.dx * 0.001,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: card,
                );
              },
            ),
          ),
        ),
      );
    }

    return card;
  }

  Widget _buildPlaceholderImage(UserModel user) {
    return Container(
      color: const Color(0xFF4A7AA7).withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 80,
                color: const Color(0xFF4A7AA7).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A7AA7).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(UserModel user) {
    final age = user.dateOfBirth != null
        ? DateTime.now().year - user.dateOfBirth!.year
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ],
                      ],
                    ),
                    if (age != null)
                      Text(
                        '$age años',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
              if (user.gender != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getGenderColor(user.gender!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.gender!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          if (user.address != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user.address!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Información de mascotas
          if (user.pets.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${user.pets.length} mascota${user.pets.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Intereses (si existen en el modelo extendido)
          // if (user.interests.isNotEmpty) ...[
          //   Wrap(
          //     spacing: 8,
          //     runSpacing: 8,
          //     children: user.interests.take(3).map((interest) =>
          //       _buildInfoTag(Icons.favorite, interest)
          //     ).toList(),
          //   ),
          //   const SizedBox(height: 12),
          // ],

          // Botón para ver más información
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Ver más detalles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIndicators() {
    final opacity = (_dragOffset.dx.abs() / 100).clamp(0.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Stack(
            children: [
              // Like indicator (derecha)
              if (_dragOffset.dx > 20)
                Positioned(
                  top: 100,
                  right: 20,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Text(
                        'LIKE',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              // Pass indicator (izquierda)
              if (_dragOffset.dx < -20)
                Positioned(
                  top: 100,
                  left: 20,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: const Text(
                        'PASS',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Botón Pass
          GestureDetector(
            onTap: () => _handlePass(_getCurrentUser()),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 30,
              ),
            ),
          ),

          // Botón Info
          GestureDetector(
            onTap: () => _showUserDetails(_getCurrentUser()),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF4A7AA7),
                size: 24,
              ),
            ),
          ),

          // Botón Like
          GestureDetector(
            onTap: () => _handleLike(_getCurrentUser()),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.green,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMoreUsersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No hay más usuarios',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Has visto todos los usuarios disponibles en tu área. ¡Vuelve más tarde!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadPotentialMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Buscar de nuevo'),
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

  UserModel _getCurrentUser() {
    return _potentialMatches[_currentIndex];
  }

  Color _getGenderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'masculino':
      case 'hombre':
        return Colors.blue;
      case 'female':
      case 'femenino':
      case 'mujer':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }

  void _handleLike(UserModel user) {
    HapticFeedback.mediumImpact();
    _showUserMatchTypeDialog(user);
  }

  void _handlePass(UserModel user) {
    HapticFeedback.lightImpact();
    _nextUser();
  }

  void _nextUser() {
    setState(() {
      _dragOffset = Offset.zero;
      if (_currentIndex < _potentialMatches.length - 1) {
        _currentIndex++;
      }
    });
  }

  void _showUserMatchTypeDialog(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¿Cómo te gustaría conectar con ${user.displayName}?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _buildUserMatchTypeOption(
              icon: Icons.people,
              title: 'Amistad',
              description: 'Conocerse como amigos dueños de mascotas',
              color: Colors.blue,
              onTap: () => _sendUserMatchRequest(user, MatchType.petOwnerFriendship),
            ),

            _buildUserMatchTypeOption(
              icon: Icons.pets,
              title: 'Actividades con mascotas',
              description: 'Organizar actividades juntos con las mascotas',
              color: Colors.orange,
              onTap: () => _sendUserMatchRequest(user, MatchType.petActivity),
            ),

            _buildUserMatchTypeOption(
              icon: Icons.medical_services,
              title: 'Cuidado de mascotas',
              description: 'Ayudarse mutuamente con el cuidado',
              color: Colors.green,
              onTap: () => _sendUserMatchRequest(user, MatchType.petCare),
            ),

            _buildUserMatchTypeOption(
              icon: Icons.coffee,
              title: 'Encuentro social',
              description: 'Conocerse en un ambiente social',
              color: Colors.purple,
              onTap: () => _sendUserMatchRequest(user, MatchType.socialMeet),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMatchTypeOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendUserMatchRequest(UserModel user, MatchType type) async {
    Navigator.pop(context);

    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String? message = await _showMessageDialog(user, type);

    // ACTUALIZAR esta llamada agregando fromUserId:
    final success = await matchProvider.sendUserMatchRequest(
      fromUserId: authProvider.currentUser?.id ?? '',
      toUserId: user.id,
      type: type,
      message: message,
    );

    if (success) {
      _showSuccessMessage(user, type);
      _nextUser();
    } else {
      _showErrorMessage();
    }
  }

  Future<String?> _showMessageDialog(UserModel user, MatchType type) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mensaje para ${user.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Envía un mensaje opcional con tu solicitud de ${_getMatchTypeText(type).toLowerCase()}:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Sin mensaje'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  String _getMatchTypeText(MatchType type) {
    switch (type) {
      case MatchType.petOwnerFriendship:
        return 'Amistad';
      case MatchType.petActivity:
        return 'Actividades con mascotas';
      case MatchType.petCare:
        return 'Cuidado de mascotas';
      case MatchType.socialMeet:
        return 'Encuentro social';
      default:
        return 'Conexión';
    }
  }

  void _showSuccessMessage(UserModel user, MatchType type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Solicitud de ${_getMatchTypeText(type).toLowerCase()} enviada a ${user.displayName}!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error enviando la solicitud. Inténtalo de nuevo.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header con foto y nombre
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                          backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                          child: user.photoURL == null
                              ? const Icon(Icons.person, size: 40, color: Color(0xFF4A7AA7))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.displayName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user.isVerified) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.verified, color: Colors.blue),
                                  ],
                                ],
                              ),
                              if (user.dateOfBirth != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${DateTime.now().year - user.dateOfBirth!.year} años',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Información básica
                    if (user.address != null) ...[
                      _buildDetailRow(Icons.location_on, 'Ubicación', user.address!),
                      const SizedBox(height: 12),
                    ],

                    if (user.pets.isNotEmpty) ...[
                      _buildDetailRow(Icons.pets, 'Mascotas', '${user.pets.length} mascota${user.pets.length == 1 ? '' : 's'}'),
                      const SizedBox(height: 12),
                    ],

                    _buildDetailRow(Icons.calendar_today, 'Miembro desde',
                        '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _handlePass(user);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Pasar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleLike(user);
                            },
                            icon: const Icon(Icons.favorite),
                            label: const Text('Me gusta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}