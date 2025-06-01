import 'package:apppetid/presentation/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/pet_model.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/match_repository.dart';
import 'auth_provider.dart';
import 'package:uuid/uuid.dart';

enum MatchState { idle, loading, loaded, error }

class MatchProvider extends ChangeNotifier {
  final MatchRepository _matchRepository = MatchRepository();
  final _uuid = const Uuid();
  BuildContext? _context;

  void initialize(BuildContext context) {
    _context = context;
  }

  MatchState _state = MatchState.idle;
  List<PetModel> _potentialMatches = [];
  List<MatchModel> _userMatches = [];
  List<MatchModel> _pendingMatches = [];
  List<MatchModel> _acceptedMatches = [];
  MatchModel? _selectedMatch;
  String? _errorMessage;

  // Getters
  MatchState get state => _state;
  List<PetModel> get potentialMatches => _potentialMatches;
  List<MatchModel> get userMatches => _userMatches;
  List<MatchModel> get pendingMatches => _pendingMatches;
  List<MatchModel> get acceptedMatches => _acceptedMatches;
  MatchModel? get selectedMatch => _selectedMatch;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == MatchState.loading;

  // Buscar matches potenciales para una mascota
  Future<void> findPotentialMatches({
    required String petId,
    required PetType type,
    required PetSize size,
    bool forMating = false,
    bool forAdoption = false,
    bool forPlaydate = false,
    double? maxDistance,
  }) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      _matchRepository.findPotentialMatches(
        petId: petId,
        type: type,
        size: size,
        forMating: forMating,
        forAdoption: forAdoption,
        forPlaydate: forPlaydate,
        maxDistance: maxDistance,
      ).listen((matches) {
        _potentialMatches = matches;
        _setState(MatchState.loaded);
      }, onError: (error) {
        _setError('Error buscando matches: $error');
      });
    } catch (e) {
      _setError('Error: $e');
    }
  }

  // Cargar matches del usuario
  Future<void> loadUserMatches(String userId) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      _matchRepository.getUserMatches(userId).listen((matches) {
        _userMatches = matches;
        _pendingMatches = matches.where((m) => m.status == MatchStatus.pending).toList();
        _acceptedMatches = matches.where((m) => m.status == MatchStatus.accepted).toList();
        _setState(MatchState.loaded);
      }, onError: (error) {
        _setError('Error cargando matches: $error');
      });
    } catch (e) {
      _setError('Error: $e');
    }
  }

  // Enviar solicitud de match
  Future<bool> sendMatchRequest({
    required String fromPetId,
    required String toPetId,
    required String fromUserId,
    required String toUserId,
    required MatchType type,
    String? message,
  }) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      final matchId = await _matchRepository.createMatchRequest(
        fromPetId: fromPetId,
        toPetId: toPetId,
        fromUserId: fromUserId, // AGREGAR
        toUserId: toUserId,     // AGREGAR
        type: type,
        message: message,
      );

      if (matchId.isNotEmpty) {
        // Recargar matches del usuario
        await _reloadCurrentUserMatches();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error enviando solicitud: $e');
      return false;
    }
  }

  // Responder a una solicitud de match
  Future<bool> respondToMatch({
    required String matchId,
    required bool accept,
    String? message,
  }) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      await _matchRepository.respondToMatch(
        matchId: matchId,
        accept: accept,
        message: message,
      );

      // Recargar matches
      await _reloadCurrentUserMatches();
      return true;
    } catch (e) {
      _setError('Error respondiendo al match: $e');
      return false;
    }
  }

  // Cancelar/rechazar match
  Future<bool> cancelMatch(String matchId) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      await _matchRepository.cancelMatch(matchId);

      // Remover de las listas locales
      _userMatches.removeWhere((m) => m.id == matchId);
      _pendingMatches.removeWhere((m) => m.id == matchId);
      _acceptedMatches.removeWhere((m) => m.id == matchId);

      _setState(MatchState.loaded);
      return true;
    } catch (e) {
      _setError('Error cancelando match: $e');
      return false;
    }
  }

  // Marcar match como completado
  Future<bool> completeMatch(String matchId) async {
    try {
      await _matchRepository.completeMatch(matchId);

      // Actualizar el match en las listas locales
      final matchIndex = _userMatches.indexWhere((m) => m.id == matchId);
      if (matchIndex != -1) {
        _userMatches[matchIndex] = _userMatches[matchIndex].copyWith(
          status: MatchStatus.completed,
        );
        _acceptedMatches.removeWhere((m) => m.id == matchId);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Error completando match: $e');
      return false;
    }
  }

  // Calificar experiencia del match
  Future<bool> rateMatch({
    required String matchId,
    required double rating,
    String? review,
  }) async {
    try {
      await _matchRepository.rateMatch(
        matchId: matchId,
        rating: rating,
        review: review,
      );
      return true;
    } catch (e) {
      _setError('Error calificando match: $e');
      return false;
    }
  }

  // Reportar problema con match
  Future<bool> reportMatch({
    required String matchId,
    required String reason,
    required String reporterId,
  }) async {
    try {
      await _matchRepository.reportMatch(
        matchId: matchId,
        reason: reason,
        reporterId: reporterId,
      );
      return true;
    } catch (e) {
      _setError('Error reportando match: $e');
      return false;
    }
  }
  Future<void> findPotentialUserMatches({
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? interests,
  }) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      if (_context == null) {
        throw Exception('Context no inicializado');
      }

      // Obtener usuarios del UserProvider
      final userProvider = Provider.of<UserProvider>(_context!, listen: false);
      await userProvider.loadSuggestedUsers();

      _setState(MatchState.loaded);
    } catch (e) {
      _setError('Error buscando usuarios: $e');
    }
  }

// Enviar solicitud de match a usuario
  Future<bool> sendUserMatchRequest({
    required String fromUserId, // AGREGAR ESTE PARÁMETRO
    required String toUserId,
    required MatchType type,
    String? message,
  }) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      final matchId = await _matchRepository.createMatchRequest(
        fromUserId: fromUserId,
        toUserId: toUserId,
        type: type,
        message: message,
      );

      if (matchId.isNotEmpty) {
        await _reloadCurrentUserMatches();
        _setState(MatchState.loaded);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error enviando solicitud: $e');
      return false;
    }
  }

  // Recargar matches del usuario actual
  Future<void> _reloadCurrentUserMatches() async {
    if (_context == null) return;

    try {
      // Obtener el userId actual del AuthProvider
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      final currentUserId = authProvider.currentUser?.id;

      if (currentUserId != null) {
        await loadUserMatches(currentUserId);
      }
    } catch (e) {
      print('Error recargando matches del usuario: $e');
    }
  }
  Future<void> findPotentialUsersForMatch({
    required String currentUserId,
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? interests,
  }) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      final users = await _matchRepository.findPotentialUserMatches(
        currentUserId: currentUserId,
        minAge: minAge,
        maxAge: maxAge,
        maxDistance: maxDistance,
        interests: interests,
      );

      // Convertir UserModel a PetModel o crear una nueva lista para usuarios
      // O agregar una nueva variable de estado para usuarios potenciales

      _setState(MatchState.loaded);
    } catch (e) {
      _setError('Error buscando usuarios potenciales: $e');
    }
  }

  // Métodos privados de estado
  void _setState(MatchState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = MatchState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() => _clearError();

  Color getMatchTypeColor(MatchType type) {
    switch (type) {
      case MatchType.mating:
        return Colors.pink;
      case MatchType.playdate:
        return Colors.orange;
      case MatchType.adoption:
        return Colors.green;
      case MatchType.friendship:
        return Colors.blue;
    // NUEVOS TIPOS PARA USUARIOS:
      case MatchType.petOwnerFriendship:
        return Colors.blue;
      case MatchType.petActivity:
        return Colors.orange;
      case MatchType.petCare:
        return Colors.green;
      case MatchType.socialMeet:
        return Colors.purple;
    }
  }

  String getMatchTypeText(MatchType type) {
    switch (type) {
      case MatchType.mating:
        return 'Reproducción';
      case MatchType.playdate:
        return 'Playdate';
      case MatchType.adoption:
        return 'Adopción';
      case MatchType.friendship:
        return 'Amistad';
    // NUEVOS TIPOS PARA USUARIOS:
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
}