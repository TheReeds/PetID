// lib/presentation/screens/events/events_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/event_model.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    // Cargar eventos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    // Configurar paginación
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      if (eventProvider.hasMoreEvents && !eventProvider.isLoadingMore) {
        eventProvider.loadEvents(refresh: false);
      }
    }
  }

  Future<void> _loadInitialData() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await eventProvider.loadEvents(refresh: true);

    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;
      await eventProvider.loadUserEvents(userId);
      await eventProvider.loadUserParticipatingEvents(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(),
          _buildSearchAndFilters(),
          _buildTabBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEventsTab(),
            _buildMyEventsTab(),
            _buildParticipatingTab(),
          ],
        ),
      ),
      floatingActionButton: _buildCreateEventFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4A7AA7),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Eventos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A7AA7), Color(0xFF6B9BD1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFF4A7AA7),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            // Barra de búsqueda
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar eventos...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4A7AA7)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_list : Icons.tune,
                      color: const Color(0xFF4A7AA7),
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  // Implementar búsqueda
                },
              ),
            ),

            // Filtros
            if (_showFilters) ...[
              const SizedBox(height: 16),
              _buildFiltersSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<EventProvider>(
            builder: (context, eventProvider, child) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    'Solo gratis',
                    eventProvider.onlyFreeEvents,
                        (selected) => eventProvider.applyFilters(onlyFree: selected),
                  ),
                  _buildFilterChip(
                    'Pet-friendly',
                    eventProvider.onlyPetFriendly,
                        (selected) => eventProvider.applyFilters(onlyPetFriendly: selected),
                  ),
                  _buildFilterChip(
                    'Hoy',
                    eventProvider.dateFilter != null &&
                        _isSameDay(eventProvider.dateFilter!, DateTime.now()),
                        (selected) => eventProvider.applyFilters(
                      date: selected ? DateTime.now() : null,
                    ),
                  ),
                  _buildFilterChip(
                    'Esta semana',
                    eventProvider.dateFilter != null &&
                        _isThisWeek(eventProvider.dateFilter!),
                        (selected) => eventProvider.applyFilters(
                      date: selected ? _getStartOfWeek() : null,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              final eventProvider = Provider.of<EventProvider>(context, listen: false);
              eventProvider.clearFilters();
            },
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF4A7AA7).withOpacity(0.2),
      checkmarkColor: const Color(0xFF4A7AA7),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4A7AA7),
          labelColor: const Color(0xFF4A7AA7),
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Mis eventos'),
            Tab(text: 'Participo'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        if (eventProvider.isLoading && eventProvider.allEvents.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
          );
        }

        if (eventProvider.allEvents.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_available,
            title: 'No hay eventos disponibles',
            subtitle: 'Sé el primero en crear un evento',
          );
        }

        return RefreshIndicator(
          onRefresh: () => eventProvider.loadEvents(refresh: true),
          color: const Color(0xFF4A7AA7),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: eventProvider.allEvents.length + 1,
            itemBuilder: (context, index) {
              if (index < eventProvider.allEvents.length) {
                return _buildEventCard(eventProvider.allEvents[index]);
              }
              return _buildLoadMoreIndicator(eventProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyEventsTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        if (eventProvider.userEvents.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_note,
            title: 'No has creado eventos',
            subtitle: 'Crea tu primer evento y conecta con la comunidad',
            actionButton: ElevatedButton.icon(
              onPressed: _createEvent,
              icon: const Icon(Icons.add),
              label: const Text('Crear evento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7AA7),
                foregroundColor: Colors.white,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: eventProvider.userEvents.length,
          itemBuilder: (context, index) {
            return _buildEventCard(eventProvider.userEvents[index], isOwner: true);
          },
        );
      },
    );
  }

  Widget _buildParticipatingTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        if (eventProvider.userParticipatingEvents.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_seat,
            title: 'No participas en eventos',
            subtitle: 'Explora eventos y únete a actividades interesantes',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: eventProvider.userParticipatingEvents.length,
          itemBuilder: (context, index) {
            return _buildEventCard(eventProvider.userParticipatingEvents[index]);
          },
        );
      },
    );
  }

  Widget _buildEventCard(EventModel event, {bool isOwner = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewEventDetail(event),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del evento
            if (event.imageUrl != null) _buildEventImage(event),

            // Contenido del evento
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con tipo y estado
                  Row(
                    children: [
                      _buildEventTypeChip(event.type),
                      const Spacer(),
                      if (event.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'GRATIS',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isOwner) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A7AA7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TU EVENTO',
                            style: TextStyle(
                              color: Color(0xFF4A7AA7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Título
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Descripción
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Información del evento
                  _buildEventInfo(event),

                  const SizedBox(height: 16),

                  // Footer con participantes y botón
                  _buildEventFooter(event, isOwner),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(EventModel event) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Stack(
          children: [
            Image.network(
              event.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.event, size: 50, color: Colors.grey),
              ),
            ),
            // Overlay de gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeChip(EventType type) {
    final typeData = _getEventTypeData(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: typeData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            typeData['icon'],
            size: 14,
            color: typeData['color'],
          ),
          const SizedBox(width: 4),
          Text(
            typeData['label'],
            style: TextStyle(
              color: typeData['color'],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(EventModel event) {
    return Column(
      children: [
        // Fecha y hora
        Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatEventDateTime(event),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Ubicación
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.displayLocation,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        // Precio si no es gratis
        if (!event.isFree) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                event.displayPrice,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEventFooter(EventModel event, bool isOwner) {
    return Row(
      children: [
        // Participantes
        Expanded(
          child: Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '${event.participants.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (event.maxParticipants > 0) ...[
                Text(
                  '/${event.maxParticipants}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              if (event.isPetFriendly) ...[
                const SizedBox(width: 12),
                Icon(Icons.pets, size: 16, color: Colors.grey.shade600),
              ],
            ],
          ),
        ),

        // Botón de acción
        if (!isOwner)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final userId = authProvider.currentUser?.id ?? '';
              final isParticipating = event.isUserParticipating(userId);

              return ElevatedButton.icon(
                onPressed: () => _toggleParticipation(event, userId),
                icon: Icon(
                  isParticipating ? Icons.check : Icons.add,
                  size: 16,
                ),
                label: Text(
                  isParticipating ? 'Participando' : 'Unirse',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isParticipating
                      ? Colors.grey.shade200
                      : const Color(0xFF4A7AA7),
                  foregroundColor: isParticipating
                      ? Colors.grey.shade700
                      : Colors.white,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLoadMoreIndicator(EventProvider eventProvider) {
    if (eventProvider.isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A7AA7)),
        ),
      );
    } else if (!eventProvider.hasMoreEvents) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                '¡Has visto todos los eventos!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? actionButton,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateEventFAB() {
    return FloatingActionButton.extended(
      onPressed: _createEvent,
      backgroundColor: const Color(0xFF4A7AA7),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Crear evento'),
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
      final dateFormat = DateFormat('dd/MM/yyyy');
      final timeFormat = DateFormat('HH:mm');

      final date = dateFormat.format(event.startDate);
      final startTime = timeFormat.format(event.startDate);
      final endTime = timeFormat.format(event.endDate);

      if (_isSameDay(event.startDate, event.endDate)) {
        return '$date • $startTime - $endTime';
      } else {
        final endDate = dateFormat.format(event.endDate);
        return '$date $startTime - $endDate $endTime';
      }
    } catch (e) {
      // Fallback simple
      return '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek();
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  DateTime _getStartOfWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  }

  // Métodos de navegación y acciones
  void _viewEventDetail(EventModel event) {
    // Verificar que el contexto esté montado
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  void _createEvent() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    ).then((_) {
      // Refrescar eventos después de crear
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.loadEvents(refresh: true);
    });
  }

  Future<void> _toggleParticipation(EventModel event, String userId) async {
    if (userId.isEmpty) return;

    HapticFeedback.lightImpact();
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    bool success;
    if (event.isUserParticipating(userId)) {
      success = await eventProvider.leaveEvent(event.id, userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Has salido del evento')),
        );
      }
    } else {
      success = await eventProvider.joinEvent(event.id, userId);
      if (success) {
        if (event.isFullyBooked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Te has unido a la lista de espera')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Te has unido al evento')),
          );
        }
      }
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar la solicitud')),
      );
    }
  }
}

// Delegate para el TabBar persistente
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}