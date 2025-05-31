import 'package:flutter/foundation.dart';
import '../../data/models/pet_model.dart';
import '../../data/models/match_model.dart';
import '../../data/repositories/match_repository.dart';

enum MatchState { idle, loading, loaded, error }

class MatchProvider extends ChangeNotifier {
  final MatchRepository _matchRepository = MatchRepository();

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
    required MatchType type,
    String? message,
  }) async {
    try {
      _setState(MatchState.loading);
      _clearError();

      final matchId = await _matchRepository.createMatchRequest(
        fromPetId: fromPetId,
        toPetId: toPetId,
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