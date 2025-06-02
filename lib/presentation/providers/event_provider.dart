import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/event_model.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/storage_service.dart';

enum EventState { initial, loading, loaded, error }

class EventProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Estado general
  EventState _state = EventState.initial;
  String? _errorMessage;

  // Listas de eventos
  List<EventModel> _allEvents = [];
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _userEvents = [];
  List<EventModel> _userParticipatingEvents = [];

  // Filtros y paginación
  String? _selectedCity;
  EventType? _selectedType;
  bool _onlyFreeEvents = false;
  bool _onlyPetFriendly = true;
  DateTime? _dateFilter;

  DocumentSnapshot? _lastDocument;
  bool _hasMoreEvents = true;
  bool _isLoadingMore = false;

  // Getters
  EventState get state => _state;
  String? get errorMessage => _errorMessage;
  List<EventModel> get allEvents => _allEvents;
  List<EventModel> get upcomingEvents => _upcomingEvents;
  List<EventModel> get userEvents => _userEvents;
  List<EventModel> get userParticipatingEvents => _userParticipatingEvents;
  bool get isLoading => _state == EventState.loading;
  bool get hasMoreEvents => _hasMoreEvents;
  bool get isLoadingMore => _isLoadingMore;

  // Filtros
  String? get selectedCity => _selectedCity;
  EventType? get selectedType => _selectedType;
  bool get onlyFreeEvents => _onlyFreeEvents;
  bool get onlyPetFriendly => _onlyPetFriendly;
  DateTime? get dateFilter => _dateFilter;

  // Cargar eventos públicos
  Future<void> loadEvents({bool refresh = false}) async {
    if (refresh) {
      _allEvents.clear();
      _lastDocument = null;
      _hasMoreEvents = true;
    }

    if (_isLoadingMore || !_hasMoreEvents) return;

    _setState(refresh ? EventState.loading : _state);
    _isLoadingMore = !refresh;

    try {
      Query query = _firestore
          .collection('events')
          .where('isPrivate', isEqualTo: false)
          .where('status', whereIn: ['upcoming', 'ongoing'])
          .orderBy('startDate', descending: false);

      // Aplicar filtros
      if (_selectedCity != null) {
        query = query.where('location.city', isEqualTo: _selectedCity);
      }

      if (_selectedType != null) {
        query = query.where('type', isEqualTo: _selectedType.toString().split('.').last);
      }

      if (_onlyFreeEvents) {
        query = query.where('price', isNull: true);
      }

      if (_onlyPetFriendly) {
        query = query.where('isPetFriendly', isEqualTo: true);
      }

      if (_dateFilter != null) {
        final startOfDay = DateTime(_dateFilter!.year, _dateFilter!.month, _dateFilter!.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('startDate', isLessThan: Timestamp.fromDate(endOfDay));
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(20);

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        final newEvents = querySnapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList();

        if (refresh) {
          _allEvents = newEvents;
        } else {
          _allEvents.addAll(newEvents);
        }

        _lastDocument = querySnapshot.docs.last;
        _hasMoreEvents = querySnapshot.docs.length == 20;
      } else {
        _hasMoreEvents = false;
      }

      // Actualizar eventos próximos
      _updateUpcomingEvents();

      _setState(EventState.loaded);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error cargando eventos: $e';
      _setState(EventState.error);
      debugPrint('Error en loadEvents: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  // Cargar eventos del usuario
  Future<void> loadUserEvents(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('creatorId', isEqualTo: userId)
          .orderBy('startDate', descending: true)
          .get();

      _userEvents = querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando eventos del usuario: $e');
    }
  }

  // Cargar eventos donde el usuario participa
  Future<void> loadUserParticipatingEvents(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('participants', arrayContains: userId)
          .orderBy('startDate', descending: false)
          .get();

      _userParticipatingEvents = querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando eventos donde participa: $e');
    }
  }

  // Crear evento
  Future<String?> createEvent({
    required String title,
    required String description,
    required EventType type,
    required String creatorId,
    required DateTime startDate,
    required DateTime endDate,
    required LocationData location,
    List<File>? imageFiles,
    int maxParticipants = 0,
    bool isPetFriendly = true,
    List<String> allowedPetTypes = const [],
    double? price,
    String? priceDescription,
    bool isPrivate = false,
    String? requirements,
    List<String> tags = const [],
    String? contactInfo,
    String? externalLink,
  }) async {
    try {
      final eventRef = _firestore.collection('events').doc();
      final eventId = eventRef.id;

      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        imageUrls = await _uploadEventImages(eventId, imageFiles);
      }

      final event = EventModel(
        id: eventId,
        title: title,
        description: description,
        type: type,
        creatorId: creatorId,
        startDate: startDate,
        endDate: endDate,
        imageUrls: imageUrls,
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
        location: location,
        maxParticipants: maxParticipants,
        isPetFriendly: isPetFriendly,
        allowedPetTypes: allowedPetTypes,
        price: price,
        priceDescription: priceDescription,
        isPrivate: isPrivate,
        requirements: requirements,
        tags: tags,
        contactInfo: contactInfo,
        externalLink: externalLink,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await eventRef.set(event.toFirestore());

      // NUEVO: Enviar notificación solo si el evento es público
      if (!isPrivate) {
        try {
          await NotificationService.sendNewEventNotification(event);
          debugPrint('✅ Notificación de nuevo evento enviada');
        } catch (e) {
          debugPrint('❌ Error enviando notificación: $e');
          // No interrumpir el flujo si falla la notificación
        }
      }

      // Agregar a lista local si no es privado
      if (!isPrivate) {
        _allEvents.insert(0, event);
        _updateUpcomingEvents();
      }

      // Agregar a eventos del usuario
      _userEvents.insert(0, event);

      notifyListeners();
      return eventId;
    } catch (e) {
      debugPrint('Error creando evento: $e');
      return null;
    }
  }

  // Participar en evento
  Future<bool> joinEvent(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) throw Exception('Evento no encontrado');

        final event = EventModel.fromFirestore(eventDoc);

        // Verificar si ya está participando
        if (event.isUserParticipating(userId)) {
          throw Exception('Ya estás participando en este evento');
        }

        List<String> newParticipants = [...event.participants];
        List<String> newWaitingList = [...event.waitingList];

        // Si hay cupo disponible
        if (!event.isFullyBooked) {
          newParticipants.add(userId);
          // Remover de lista de espera si estaba
          newWaitingList.remove(userId);
        } else {
          // Agregar a lista de espera
          if (!newWaitingList.contains(userId)) {
            newWaitingList.add(userId);
          }
        }

        transaction.update(eventRef, {
          'participants': newParticipants,
          'waitingList': newWaitingList,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // NUEVO: Enviar notificación al creador del evento
        try {
          // Obtener nombre del participante (esto deberías implementarlo según tu UserProvider)
          // final userName = await _getUserName(userId);
          await NotificationService.sendEventJoinNotification(
            event.copyWith(participants: newParticipants),
            'Un usuario', // Reemplazar con el nombre real del usuario
          );
        } catch (e) {
          debugPrint('Error enviando notificación de participación: $e');
        }
      });

      // Actualizar en listas locales
      _updateEventInLists(eventId, (event) => event.copyWith(
        participants: [...event.participants, userId],
      ));

      return true;
    } catch (e) {
      debugPrint('Error uniéndose al evento: $e');
      return false;
    }
  }

  // Salir de evento
  Future<bool> leaveEvent(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) throw Exception('Evento no encontrado');

        final event = EventModel.fromFirestore(eventDoc);

        List<String> newParticipants = [...event.participants];
        List<String> newWaitingList = [...event.waitingList];

        // Remover de participantes
        newParticipants.remove(userId);

        // Si hay gente en lista de espera, mover al primero
        if (newWaitingList.isNotEmpty && !event.isFullyBooked) {
          final nextUser = newWaitingList.removeAt(0);
          newParticipants.add(nextUser);
        }

        transaction.update(eventRef, {
          'participants': newParticipants,
          'waitingList': newWaitingList,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Actualizar en listas locales
      _updateEventInLists(eventId, (event) {
        final newParticipants = [...event.participants];
        newParticipants.remove(userId);
        return event.copyWith(participants: newParticipants);
      });

      return true;
    } catch (e) {
      debugPrint('Error saliendo del evento: $e');
      return false;
    }
  }

  // Obtener evento por ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo evento: $e');
      return null;
    }
  }

  // Aplicar filtros
  void applyFilters({
    String? city,
    EventType? type,
    bool? onlyFree,
    bool? onlyPetFriendly,
    DateTime? date,
  }) {
    _selectedCity = city;
    _selectedType = type;
    _onlyFreeEvents = onlyFree ?? _onlyFreeEvents;
    _onlyPetFriendly = onlyPetFriendly ?? _onlyPetFriendly;
    _dateFilter = date;

    loadEvents(refresh: true);
  }

  // Limpiar filtros
  void clearFilters() {
    _selectedCity = null;
    _selectedType = null;
    _onlyFreeEvents = false;
    _onlyPetFriendly = true;
    _dateFilter = null;

    loadEvents(refresh: true);
  }

  // Métodos privados
  void _setState(EventState newState) {
    _state = newState;
    notifyListeners();
  }

  void _updateUpcomingEvents() {
    final now = DateTime.now();
    _upcomingEvents = _allEvents
        .where((event) => event.startDate.isAfter(now))
        .take(10)
        .toList();
  }

  void _updateEventInLists(String eventId, EventModel Function(EventModel) updater) {
    // Actualizar en todas las listas
    _updateEventInList(_allEvents, eventId, updater);
    _updateEventInList(_upcomingEvents, eventId, updater);
    _updateEventInList(_userEvents, eventId, updater);
    _updateEventInList(_userParticipatingEvents, eventId, updater);

    notifyListeners();
  }

  void _updateEventInList(List<EventModel> list, String eventId, EventModel Function(EventModel) updater) {
    final index = list.indexWhere((event) => event.id == eventId);
    if (index != -1) {
      list[index] = updater(list[index]);
    }
  }

  Future<List<String>> _uploadEventImages(String eventId, List<File> imageFiles) async {
    try {
      final List<String> urls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final url = await StorageService.uploadEventPhoto(
          eventId: eventId,
          imageFile: imageFiles[i],
        );
        urls.add(url);
      }

      return urls;
    } catch (e) {
      debugPrint('Error subiendo imágenes del evento: $e');
      return [];
    }
  }
}