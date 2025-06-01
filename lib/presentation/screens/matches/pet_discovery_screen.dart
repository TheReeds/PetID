import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/match_model.dart';
import 'dart:math' as math;

class PetDiscoveryScreen extends StatefulWidget {
  final PetModel selectedPet;

  const PetDiscoveryScreen({
    super.key,
    required this.selectedPet,
  });

  @override
  State<PetDiscoveryScreen> createState() => _PetDiscoveryScreenState();
}

class _PetDiscoveryScreenState extends State<PetDiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

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

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
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
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);

    await matchProvider.findPotentialMatches(
      petId: widget.selectedPet.id,
      type: widget.selectedPet.type,
      size: widget.selectedPet.size,
      forMating: widget.selectedPet.isForMating,
      forPlaydate: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, matchProvider, child) {
        if (matchProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
          );
        }

        if (matchProvider.potentialMatches.isEmpty) {
          return _buildNoMorePetsState();
        }

        return Stack(
          children: [
            // Cards de mascotas
            for (int i = math.min(_currentIndex + 2, matchProvider.potentialMatches.length - 1);
            i >= _currentIndex;
            i--)
              _buildPetCard(
                matchProvider.potentialMatches[i],
                i - _currentIndex,
                i == _currentIndex,
              ),

            // Indicadores de acción
            if (_isDragging) _buildActionIndicators(),

            // Botones de acción
            _buildActionButtons(),
          ],
        );
      },
    );
  }

  Widget _buildPetCard(PetModel pet, int stackIndex, bool isActive) {
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
                // Imagen de fondo
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey.shade200,
                  child: pet.photos.isNotEmpty
                      ? Image.network(
                    pet.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(pet),
                  )
                      : _buildPlaceholderImage(pet),
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

                // Información de la mascota
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildPetInfo(pet),
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
              _handleLike(pet);
            } else {
              _handlePass(pet);
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

  Widget _buildPlaceholderImage(PetModel pet) {
    return Container(
      color: const Color(0xFF4A7AA7).withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: const Color(0xFF4A7AA7).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              pet.name,
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

  Widget _buildPetInfo(PetModel pet) {
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
                    Text(
                      pet.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${pet.displayAge} • ${pet.breed}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGenderColor(pet.sex),  // ← Cambiar pet.gender por pet.sex
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pet.sex.toString().split('.').last.toUpperCase(),  // ← Cambiar pet.gender por pet.sex
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tags de características
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoTag(Icons.straighten, '${pet.size.toString().split('.').last}'),
              if (pet.isVaccinated) _buildInfoTag(Icons.medical_services, 'Vacunado'),
              if (pet.isNeutered) _buildInfoTag(Icons.healing, 'Esterilizado'),
              if (pet.isForMating) _buildInfoTag(Icons.favorite, 'Reproducción'),
              if (pet.isForAdoption) _buildInfoTag(Icons.home, 'Adopción'),
            ],
          ),

          if (pet.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              pet.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Información del dueño
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final owner = userProvider.getUserForPost(pet.ownerId);
              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: owner?.photoURL != null
                        ? NetworkImage(owner!.photoURL!)
                        : null,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: owner?.photoURL == null
                        ? const Icon(Icons.person, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dueño: ${owner?.displayName ?? "Usuario"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (pet.location != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '2.5 km', // Calcular distancia real
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
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
    final screenWidth = MediaQuery.of(context).size.width;
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
            onTap: () => _handlePass(_getCurrentPet()),
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
            onTap: () => _showPetDetails(_getCurrentPet()),
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
            onTap: () => _handleLike(_getCurrentPet()),
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

  Widget _buildNoMorePetsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No hay más mascotas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Has visto todas las mascotas disponibles en tu área. ¡Vuelve más tarde!',
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

  PetModel _getCurrentPet() {
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    return matchProvider.potentialMatches[_currentIndex];
  }

  Color _getGenderColor(PetSex sex) {
    switch (sex) {
      case PetSex.male:
        return Colors.blue;
      case PetSex.female:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  void _handleLike(PetModel pet) {
    HapticFeedback.mediumImpact();
    _showMatchTypeDialog(pet);
  }

  void _handlePass(PetModel pet) {
    HapticFeedback.lightImpact();
    _nextPet();
  }

  void _nextPet() {
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);

    setState(() {
      _dragOffset = Offset.zero;
      if (_currentIndex < matchProvider.potentialMatches.length - 1) {
        _currentIndex++;
      }
    });
  }

  void _showMatchTypeDialog(PetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
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
              '¿Qué tipo de match quieres con ${pet.name}?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _buildMatchTypeOption(
              icon: Icons.pets,
              title: 'Playdate',
              description: 'Organizar una cita de juego',
              color: Colors.orange,
              onTap: () => _sendMatchRequest(pet, MatchType.playdate),
            ),

            if (pet.isForMating && widget.selectedPet.isForMating)
              _buildMatchTypeOption(
                icon: Icons.favorite,
                title: 'Reproducción',
                description: 'Para apareamiento',
                color: Colors.pink,
                onTap: () => _sendMatchRequest(pet, MatchType.mating),
              ),

            if (pet.isForAdoption)
              _buildMatchTypeOption(
                icon: Icons.home,
                title: 'Adopción',
                description: 'Interesado en adoptar',
                color: Colors.green,
                onTap: () => _sendMatchRequest(pet, MatchType.adoption),
              ),

            _buildMatchTypeOption(
              icon: Icons.people,
              title: 'Amistad',
              description: 'Conocer al dueño también',
              color: Colors.blue,
              onTap: () => _sendMatchRequest(pet, MatchType.friendship),
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

  Widget _buildMatchTypeOption({
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

  Future<void> _sendMatchRequest(PetModel pet, MatchType type) async {
    Navigator.pop(context); // Cerrar modal

    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Mostrar dialog de mensaje opcional
    String? message = await _showMessageDialog(pet, type);

    final success = await matchProvider.sendMatchRequest(
      fromPetId: widget.selectedPet.id,
      toPetId: pet.id,
      type: type,
      message: message,
    );

    if (success) {
      _showSuccessMessage(pet, type);
      _nextPet();
    } else {
      _showErrorMessage();
    }
  }

  Future<String?> _showMessageDialog(PetModel pet, MatchType type) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mensaje para ${pet.name}'),
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
      case MatchType.mating:
        return 'Reproducción';
      case MatchType.playdate:
        return 'Playdate';
      case MatchType.adoption:
        return 'Adopción';
      case MatchType.friendship:
        return 'Amistad';
    }
  }

  void _showSuccessMessage(PetModel pet, MatchType type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Solicitud de ${_getMatchTypeText(type).toLowerCase()} enviada a ${pet.name}!'),
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

  void _showPetDetails(PetModel pet) {
    // Implementar detalles completos de la mascota
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
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
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
                    Text(
                      'Detalles de ${pet.name}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Aquí agregarías todos los detalles de la mascota
                    Text('Información completa próximamente...'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}