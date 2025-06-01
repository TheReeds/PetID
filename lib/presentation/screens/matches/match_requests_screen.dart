import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/pet_provider.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/pet_model.dart';

class MatchRequestsScreen extends StatefulWidget {
  final List<MatchModel> pendingMatches;

  const MatchRequestsScreen({
    super.key,
    required this.pendingMatches,
  });

  @override
  State<MatchRequestsScreen> createState() => _MatchRequestsScreenState();
}

class _MatchRequestsScreenState extends State<MatchRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.pendingMatches.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.pendingMatches.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(widget.pendingMatches[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4A7AA7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 60,
                color: const Color(0xFF4A7AA7).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes solicitudes pendientes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Las solicitudes aparecerán aquí cuando otros usuarios estén interesados en conectar contigo o con tus mascotas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Consejos para recibir más solicitudes:',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTipRow(Icons.pets, 'Marca tus mascotas como disponibles para playdate'),
                      _buildTipRow(Icons.people, 'Mantén tu perfil actualizado y completo'),
                      _buildTipRow(Icons.explore, 'Explora usuarios y mascotas en la pestaña de descubrimiento'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(MatchModel match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRequestHeader(match),
          _buildRequestContent(match),
          _buildRequestActions(match),
        ],
      ),
    );
  }

  Widget _buildRequestHeader(MatchModel match) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getMatchTypeColor(match.type).withOpacity(0.1),
            _getMatchTypeColor(match.type).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getMatchTypeColor(match.type),
                  _getMatchTypeColor(match.type).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: _getMatchTypeColor(match.type).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getMatchTypeIcon(match.type),
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _getMatchTypeText(match.type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'PENDIENTE',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(match.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestContent(MatchModel match) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del solicitante
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.getUserForPost(match.fromUserId);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7AA7).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4A7AA7).withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, color: Color(0xFF4A7AA7), size: 28)
                              : null,
                        ),
                        if (user?.isVerified == true)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                size: 16,
                                color: Color(0xFF4A7AA7),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? user?.fullName ?? 'Usuario',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quiere hacer ${_getMatchTypeText(match.type).toLowerCase()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (user?.address != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14,
                                    color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    user!.address!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // CONDICIÓN: Mostrar mascotas solo si es match de mascotas
          if (match.isPetMatch) ...[
            // Información de las mascotas con diseño mejorado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.pets, color: Colors.grey.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mascotas involucradas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildPetInfoCard(match.fromPetId!, 'Su mascota', true)),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getMatchTypeColor(match.type),
                              _getMatchTypeColor(match.type).withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getMatchTypeColor(match.type).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getMatchTypeIcon(match.type),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Expanded(child: _buildPetInfoCard(match.toPetId!, 'Tu mascota', false)),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (match.isUserMatch) ...[
            // NUEVO: Información específica para matches de usuarios
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.purple.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Solicitud de conexión entre usuarios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Información específica del tipo de match de usuario
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getMatchTypeColor(match.type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getMatchTypeIcon(match.type),
                            color: _getMatchTypeColor(match.type),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getMatchTypeText(match.type),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getMatchTypeDescription(match.type),
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
                ],
              ),
            ),
          ],

          // Mensaje si existe
          if (match.message != null && match.message!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade25,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.message, size: 18, color: Colors.blue.shade700),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mensaje incluido:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      match.message!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPetInfoCard(String? petId, String label, bool isRequester) {
    // AGREGAR verificación de null
    if (petId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(
              Icons.help_outline,
              size: 32,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin mascota',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        // En una implementación real, obtendrías la mascota por ID desde el provider
        // Por ahora, usamos información básica
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRequester
                ? Colors.orange.withOpacity(0.05)
                : const Color(0xFF4A7AA7).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRequester
                  ? Colors.orange.withOpacity(0.2)
                  : const Color(0xFF4A7AA7).withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isRequester
                        ? Colors.orange.withOpacity(0.1)
                        : const Color(0xFF4A7AA7).withOpacity(0.1),
                    child: Icon(
                      Icons.pets,
                      color: isRequester ? Colors.orange : const Color(0xFF4A7AA7),
                      size: 32,
                    ),
                  ),
                  if (isRequester)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Mascota ${petId.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRequester
                      ? Colors.orange.withOpacity(0.2)
                      : const Color(0xFF4A7AA7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isRequester ? Colors.orange.shade800 : const Color(0xFF4A7AA7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              // Información adicional de la mascota
              Column(
                children: [
                  _buildPetDetailRow(Icons.cake, 'Edad', '2 años'),
                  _buildPetDetailRow(Icons.straighten, 'Tamaño', 'Mediano'),
                  _buildPetDetailRow(Icons.pets, 'Raza', 'Labrador'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildPetDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getMatchTypeDescription(MatchType type) {
    switch (type) {
      case MatchType.mating:
        return 'Para apareamiento entre mascotas';
      case MatchType.playdate:
        return 'Organizar una cita de juego para mascotas';
      case MatchType.adoption:
        return 'Interés en adopción';
      case MatchType.friendship:
        return 'Amistad entre mascotas';
      case MatchType.petOwnerFriendship:
        return 'Conocerse como amigos dueños de mascotas';
      case MatchType.petActivity:
        return 'Organizar actividades juntos con las mascotas';
      case MatchType.petCare:
        return 'Ayudarse mutuamente con el cuidado de mascotas';
      case MatchType.socialMeet:
        return 'Conocerse en un ambiente social casual';
    }
  }

  Widget _buildRequestActions(MatchModel match) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Botón Rechazar
              Expanded(
                child: Container(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(match),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Botón Aceptar
              Expanded(
                flex: 2,
                child: Container(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAcceptDialog(match),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.green.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Botón de información adicional
          TextButton.icon(
            onPressed: () => _showMatchDetails(match),
            icon: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
            label: Text(
              'Ver detalles completos',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchTypeColor(MatchType type) {
    switch (type) {
      case MatchType.mating:
        return Colors.pink.shade400;
      case MatchType.playdate:
        return Colors.orange.shade400;
      case MatchType.adoption:
        return Colors.green.shade400;
      case MatchType.friendship:
        return Colors.blue.shade400;
    // NUEVOS TIPOS:
      case MatchType.petOwnerFriendship:
        return Colors.blue.shade400;
      case MatchType.petActivity:
        return Colors.orange.shade400;
      case MatchType.petCare:
        return Colors.green.shade400;
      case MatchType.socialMeet:
        return Colors.purple.shade400;
    }
  }

  IconData _getMatchTypeIcon(MatchType type) {
    switch (type) {
      case MatchType.mating:
        return Icons.favorite;
      case MatchType.playdate:
        return Icons.sports_tennis;
      case MatchType.adoption:
        return Icons.home_filled;
      case MatchType.friendship:
        return Icons.people;
    // NUEVOS ICONOS:
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
      case MatchType.petOwnerFriendship:
        return 'Amistad';
      case MatchType.petActivity:
        return 'Actividades';
      case MatchType.petCare:
        return 'Cuidado';
      case MatchType.socialMeet:
        return 'Encuentro';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showAcceptDialog(MatchModel match) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green.shade600),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Aceptar solicitud',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres aceptar esta solicitud de ${_getMatchTypeText(match.type).toLowerCase()}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mensaje de respuesta (opcional):',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje para el otro usuario...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => _acceptMatch(match, messageController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(MatchModel match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Rechazar solicitud',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres rechazar esta solicitud de ${_getMatchTypeText(match.type).toLowerCase()}?\n\nEsta acción no se puede deshacer.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => _rejectMatch(match),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showMatchDetails(MatchModel match) {
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Detalles de la solicitud',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Información detallada de la solicitud próximamente...'),
                          // Aquí puedes agregar más detalles
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _acceptMatch(MatchModel match, String message) async {
    Navigator.pop(context); // Cerrar dialog

    final matchProvider = Provider.of<MatchProvider>(context, listen: false);

    HapticFeedback.mediumImpact();

    final success = await matchProvider.respondToMatch(
      matchId: match.id,
      accept: true,
      message: message.isNotEmpty ? message : null,
    );

    if (success) {
      _showSuccessSnackBar('¡Match aceptado! 🎉 Ahora pueden coordinar su encuentro.');
    } else {
      _showErrorSnackBar('Error al aceptar el match. Inténtalo de nuevo.');
    }
  }

  Future<void> _rejectMatch(MatchModel match) async {
    Navigator.pop(context); // Cerrar dialog

    final matchProvider = Provider.of<MatchProvider>(context, listen: false);

    HapticFeedback.lightImpact();

    final success = await matchProvider.respondToMatch(
      matchId: match.id,
      accept: false,
    );

    if (success) {
      _showSuccessSnackBar('Solicitud rechazada correctamente.');
    } else {
      _showErrorSnackBar('Error al rechazar el match. Inténtalo de nuevo.');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error, color: Colors.red, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 8,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: () {
            // Aquí podrías implementar lógica de reintento
          },
        ),
      ),
    );
  }
}

// Extensión para Colors.shade25 (que no existe por defecto)
extension ColorShade on Color {
  Color get shade25 => Color.lerp(this, Colors.white, 0.95)!;
}