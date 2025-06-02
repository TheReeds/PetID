import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventModel _currentEvent;
  UserModel? _creator;
  List<UserModel> _participants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      // Recargar evento actualizado
      final updatedEvent = await eventProvider.getEventById(_currentEvent.id);
      if (updatedEvent != null) {
        _currentEvent = updatedEvent;
      }

      // Cargar información del creador
      _creator = await userProvider.getUserById(_currentEvent.creatorId);

      // Cargar algunos participantes
      if (_currentEvent.participants.isNotEmpty) {
        final participantIds = _currentEvent.participants.take(10).toList();
        for (String userId in participantIds) {
          final user = await userProvider.getUserById(userId);
          if (user != null) {
            _participants.add(user);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos del evento: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventHeader(),
                _buildEventDetails(),
                _buildEventDescription(),
                if (_currentEvent.requirements != null) _buildRequirements(),
                _buildCreatorInfo(),
                _buildParticipants(),
                if (_currentEvent.tags.isNotEmpty) _buildTags(),
                _buildLocationSection(),
                const SizedBox(height: 100), // Espacio para el botón flotante
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: _currentEvent.imageUrl != null ? 300 : 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4A7AA7),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: _currentEvent.imageUrl != null
            ? Stack(
          children: [
            Image.network(
              _currentEvent.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF4A7AA7),
                child: const Icon(Icons.event, size: 80, color: Colors.white),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        )
            : Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A7AA7), Color(0xFF6B9BD1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.event, size: 80, color: Colors.white),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareEvent,
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Reportar evento'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'report') {
              _reportEvent();
            }
          },
        ),
      ],
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo y estado
          Row(
            children: [
              _buildEventTypeChip(_currentEvent.type),
              const Spacer(),
              if (_currentEvent.isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'GRATIS',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Título
          Text(
            _currentEvent.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),

          const SizedBox(height: 16),

          // Estadísticas rápidas
          Row(
            children: [
              _buildStatItem(Icons.people, '${_currentEvent.participants.length}', 'Participantes'),
              const SizedBox(width: 24),
              _buildStatItem(Icons.schedule, _currentEvent.displayDuration, 'Duración'),
              if (!_currentEvent.isFree) ...[
                const SizedBox(width: 24),
                _buildStatItem(Icons.attach_money, _currentEvent.displayPrice, 'Precio'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Detalles del evento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),

          // Fecha y hora
          _buildDetailRow(
            Icons.schedule,
            'Fecha y hora',
            _formatEventDateTime(_currentEvent),
          ),

          const SizedBox(height: 12),

          // Ubicación
          _buildDetailRow(
            Icons.location_on,
            'Ubicación',
            _currentEvent.displayLocation,
          ),

          if (_currentEvent.maxParticipants > 0) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.people,
              'Capacidad',
              '${_currentEvent.participants.length}/${_currentEvent.maxParticipants} participantes',
            ),
          ],

          if (_currentEvent.isPetFriendly) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.pets,
              'Pet-friendly',
              _currentEvent.allowedPetTypes.isNotEmpty
                  ? _currentEvent.allowedPetTypes.join(', ')
                  : 'Todas las mascotas bienvenidas',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Descripción',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentEvent.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirements() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Requisitos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentEvent.requirements!,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorInfo() {
    if (_creator == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Organizador',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: _creator!.photoURL != null
                    ? NetworkImage(_creator!.photoURL!)
                    : null,
                backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                child: _creator!.photoURL == null
                    ? Text(
                  _creator!.displayName.isNotEmpty
                      ? _creator!.displayName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Color(0xFF4A7AA7),
                    fontWeight: FontWeight.bold,
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
                        Text(
                          _creator!.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_creator!.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xFF4A7AA7),
                          ),
                        ],
                      ],
                    ),
                    if (_creator!.fullName != null && _creator!.fullName != _creator!.displayName)
                      Text(
                        _creator!.fullName!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _contactCreator(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7AA7),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('Contactar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipants() {
    if (_participants.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Text(
                'Participantes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              if (_currentEvent.participants.length > _participants.length)
                Text(
                  '+${_currentEvent.participants.length - _participants.length} más',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: participant.photoURL != null
                            ? NetworkImage(participant.photoURL!)
                            : null,
                        backgroundColor: const Color(0xFF4A7AA7).withOpacity(0.1),
                        child: participant.photoURL == null
                            ? Text(
                          participant.displayName.isNotEmpty
                              ? participant.displayName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Color(0xFF4A7AA7),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 40,
                        child: Text(
                          participant.displayName,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _currentEvent.tags.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4A7AA7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '#$tag',
            style: const TextStyle(
              color: Color(0xFF4A7AA7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Text(
            'Ubicación',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    _currentEvent.displayLocation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _openInMaps,
            icon: const Icon(Icons.directions),
            label: const Text('Abrir en mapas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7AA7),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userId = authProvider.currentUser?.id ?? '';
        final isParticipating = _currentEvent.isUserParticipating(userId);
        final isCreator = _currentEvent.isUserCreator(userId);

        if (isCreator) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editEvent,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A7AA7),
                      side: const BorderSide(color: Color(0xFF4A7AA7)),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _manageEvent,
                    icon: const Icon(Icons.settings),
                    label: const Text('Gestionar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7AA7),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _toggleParticipation(userId),
            icon: Icon(isParticipating ? Icons.check : Icons.add),
            label: Text(
              isParticipating ? 'Participando' :
              (_currentEvent.isFullyBooked ? 'Lista de espera' : 'Unirse al evento'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isParticipating
                  ? Colors.grey.shade300
                  : const Color(0xFF4A7AA7),
              foregroundColor: isParticipating
                  ? Colors.grey.shade700
                  : Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        );
      },
    );
  }

  // Widgets auxiliares
  Widget _buildEventTypeChip(EventType type) {
    final typeData = _getEventTypeData(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: typeData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            typeData['icon'],
            size: 16,
            color: typeData['color'],
          ),
          const SizedBox(width: 6),
          Text(
            typeData['label'],
            style: TextStyle(
              color: typeData['color'],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4A7AA7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4A7AA7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Métodos de utilidad
  Map<String, dynamic> _getEventTypeData(EventType type) {
    switch (type) {
      case EventType.meetup:
        return {
          'label': 'Encuentro',
          'icon': Icons.people,
          'color': const Color(0xFF3498DB),
        };
      case EventType.training:
        return {
          'label': 'Entrenamiento',
          'icon': Icons.school,
          'color': const Color(0xFF9B59B6),
        };
      case EventType.veterinary:
        return {
          'label': 'Veterinario',
          'icon': Icons.medical_services,
          'color': const Color(0xFF27AE60),
        };
      case EventType.adoption:
        return {
          'label': 'Adopción',
          'icon': Icons.favorite,
          'color': const Color(0xFFE67E22),
        };
      case EventType.contest:
        return {
          'label': 'Concurso',
          'icon': Icons.emoji_events,
          'color': const Color(0xFFF39C12),
        };
      case EventType.social:
        return {
          'label': 'Social',
          'icon': Icons.celebration,
          'color': const Color(0xFFE74C3C),
        };
      case EventType.other:
        return {
          'label': 'Otro',
          'icon': Icons.event,
          'color': const Color(0xFF95A5A6),
        };
    }
  }

  String _formatEventDateTime(EventModel event) {
    try {
      // Usar formato básico sin localización específica
      final dateFormat = DateFormat('dd/MM/yyyy');
      final timeFormat = DateFormat('HH:mm');

      final date = dateFormat.format(event.startDate);
      final startTime = timeFormat.format(event.startDate);
      final endTime = timeFormat.format(event.endDate);

      if (_isSameDay(event.startDate, event.endDate)) {
        return '$date\n$startTime - $endTime';
      } else {
        final endDate = dateFormat.format(event.endDate);
        return '$date $startTime\n$endDate $endTime';
      }
    } catch (e) {
      // Fallback en caso de error
      return '${event.startDate.day}/${event.startDate.month}/${event.startDate.year} ${event.startDate.hour}:${event.startDate.minute.toString().padLeft(2, '0')}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Métodos de acciones
  Future<void> _toggleParticipation(String userId) async {
    if (userId.isEmpty) return;

    HapticFeedback.lightImpact();
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    bool success;
    if (_currentEvent.isUserParticipating(userId)) {
      success = await eventProvider.leaveEvent(_currentEvent.id, userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Has salido del evento')),
        );
        // Actualizar evento local
        final updatedEvent = await eventProvider.getEventById(_currentEvent.id);
        if (updatedEvent != null) {
          setState(() {
            _currentEvent = updatedEvent;
          });
        }
      }
    } else {
      success = await eventProvider.joinEvent(_currentEvent.id, userId);
      if (success) {
        if (_currentEvent.isFullyBooked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Te has unido a la lista de espera')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Te has unido al evento')),
          );
        }
        // Actualizar evento local
        final updatedEvent = await eventProvider.getEventById(_currentEvent.id);
        if (updatedEvent != null) {
          setState(() {
            _currentEvent = updatedEvent;
          });
        }
      }
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar la solicitud')),
      );
    }
  }

  void _shareEvent() {
    HapticFeedback.lightImpact();
    // Implementar compartir evento
    final shareText = '''
🎉 ${_currentEvent.title}

📅 ${_formatEventDateTime(_currentEvent)}
📍 ${_currentEvent.displayLocation}

${_currentEvent.description}

¡Únete desde la app PetID!
''';

    // Aquí usarías share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de compartir próximamente')),
    );
  }

  void _reportEvent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar evento'),
        content: const Text('¿Por qué quieres reportar este evento?'),
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

  void _contactCreator() {
    if (_creator == null) return;

    HapticFeedback.lightImpact();
    // Navegar al chat con el creador
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de chat próximamente')),
    );
  }

  void _openInMaps() async {
    final location = _currentEvent.location;
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'No se puede abrir el mapa';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al abrir el mapa')),
      );
    }
  }

  void _editEvent() {
    HapticFeedback.lightImpact();
    // Navegar a editar evento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de editar próximamente')),
    );
  }

  void _manageEvent() {
    HapticFeedback.lightImpact();
    // Navegar a gestionar evento (participantes, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de gestión próximamente')),
    );
  }
}