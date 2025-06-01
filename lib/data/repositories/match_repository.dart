import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/pet_model.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _uuid = const Uuid();

  // Buscar matches potenciales para una mascota
  Stream<List<PetModel>> findPotentialMatches({
    required String petId,
    required PetType type,
    required PetSize size,
    bool forMating = false,
    bool forAdoption = false,
    bool forPlaydate = false,
    double? maxDistance,
  }) {
    Query query = FirebaseService.pets
        .where('type', isEqualTo: type.toString().split('.').last)
        .where('size', isEqualTo: size.toString().split('.').last)
        .where('id', isNotEqualTo: petId);

    // Filtros adicionales
    if (forMating) {
      query = query.where('isForMating', isEqualTo: true);
    }
    if (forAdoption) {
      query = query.where('isForAdoption', isEqualTo: true);
    }

    return query
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PetModel.fromFirestore(doc))
        .toList());
  }

  // Obtener matches del usuario
  Stream<List<MatchModel>> getUserMatches(String userId) {
    return FirebaseService.matches
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MatchModel.fromFirestore(doc))
        .toList());
  }

  // Crear solicitud de match
  Future<String> createMatchRequest({
    String? fromPetId,
    String? toPetId,
    required String fromUserId,
    required String toUserId,
    required MatchType type,
    String? message,
  }) async {
    try {
      final matchId = _uuid.v4();

      MatchModel match;

      if (fromPetId != null && toPetId != null) {
        // Match de mascotas
        match = MatchModel.createPetMatch(
          id: matchId,
          fromUserId: fromUserId,
          toUserId: toUserId,
          fromPetId: fromPetId,
          toPetId: toPetId,
          type: type,
          message: message,
        );
      } else {
        // Match de usuarios
        match = MatchModel.createUserMatch(
          id: matchId,
          fromUserId: fromUserId,
          toUserId: toUserId,
          type: type,
          message: message,
        );
      }

      await FirebaseService.matches.doc(matchId).set(match.toFirestore());
      return matchId;
    } catch (e) {
      throw Exception('Error creando match: $e');
    }
  }

  // Responder a solicitud de match
  Future<void> respondToMatch({
    required String matchId,
    required bool accept,
    String? message,
  }) async {
    try {
      final updates = {
        'status': accept ? 'accepted' : 'rejected',
        'responseMessage': message,
        'respondedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseService.matches.doc(matchId).update(updates);
    } catch (e) {
      throw Exception('Error respondiendo al match: $e');
    }
  }

  // Cancelar match
  Future<void> cancelMatch(String matchId) async {
    try {
      await FirebaseService.matches.doc(matchId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error cancelando match: $e');
    }
  }

  // Completar match
  Future<void> completeMatch(String matchId) async {
    try {
      await FirebaseService.matches.doc(matchId).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error completando match: $e');
    }
  }

  // Calificar match
  Future<void> rateMatch({
    required String matchId,
    required double rating,
    String? review,
  }) async {
    try {
      await FirebaseService.matches.doc(matchId).update({
        'rating': rating,
        'review': review,
        'ratedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error calificando match: $e');
    }
  }

  // Reportar match
  Future<void> reportMatch({
    required String matchId,
    required String reason,
    required String reporterId,
  }) async {
    try {
      final reportId = _uuid.v4();
      await _firestore.collection('match_reports').doc(reportId).set({
        'id': reportId,
        'matchId': matchId,
        'reporterId': reporterId,
        'reason': reason,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error reportando match: $e');
    }
  }
  Future<String> createUserMatchRequest(MatchModel match) async {
    try {
      await FirebaseService.matches.doc(match.id).set(match.toFirestore());
      return match.id;
    } catch (e) {
      throw Exception('Error creando match de usuario: $e');
    }
  }

// Buscar usuarios potenciales para match
  Future<List<UserModel>> findPotentialUserMatches({
    required String currentUserId,
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? interests,
  }) async {
    try {
      Query query = FirebaseService.users
          .where('id', isNotEqualTo: currentUserId)
          .where('isOpenToMeetPetOwners', isEqualTo: true);

      // Filtros adicionales basados en preferencias
      if (interests != null && interests.isNotEmpty) {
        query = query.where('interests', arrayContainsAny: interests);
      }

      final snapshot = await query.limit(50).get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error buscando usuarios para match: $e');
    }
  }
}