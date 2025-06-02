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
    Query query = _firestore
        .collection('pets')  // ← Usar _firestore directamente
        .where('type', isEqualTo: type.toString().split('.').last)
        .where('size', isEqualTo: size.toString().split('.').last);

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
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PetModel.fromFirestore(doc))
          .where((pet) => pet.id != petId) // Filtrar aquí en memoria
          .toList();
    });
  }
  Future<bool> hasExistingMatch(String fromPetId, String toPetId) async {
    try {
      // Buscar match en ambas direcciones
      final query1 = await _firestore
          .collection('matches')
          .where('fromPetId', isEqualTo: fromPetId)
          .where('toPetId', isEqualTo: toPetId)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      final query2 = await _firestore
          .collection('matches')
          .where('fromPetId', isEqualTo: toPetId)
          .where('toPetId', isEqualTo: fromPetId)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      return query1.docs.isNotEmpty || query2.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando match existente: $e');
      return false;
    }
  }
  // Obtener matches del usuario
  Stream<List<MatchModel>> getUserMatches(String userId) {
    return _firestore
        .collection('matches')
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
      // Validar que no es el mismo usuario
      if (fromUserId == toUserId) {
        throw Exception('No puedes hacer match contigo mismo');
      }

      // Si es match de mascotas, verificar que no existe ya
      if (fromPetId != null && toPetId != null) {
        final existingMatch = await hasExistingMatch(fromPetId, toPetId);
        if (existingMatch) {
          throw Exception('Ya existe una solicitud entre estas mascotas');
        }
      }

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

      await _firestore.collection('matches').doc(matchId).set(match.toFirestore());
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

      await _firestore.collection('matches').doc(matchId).update(updates);
    } catch (e) {
      throw Exception('Error respondiendo al match: $e');
    }
  }

  Future<List<UserModel>> findPotentialUserMatches({
    required String currentUserId,
    int? minAge,
    int? maxAge,
    double? maxDistance,
    List<String>? interests,
  }) async {
    try {
      Query query = _firestore
          .collection('users');
      // Nota: No usar isNotEqualTo en la consulta inicial

      // Obtener usuarios y filtrar en memoria para evitar problemas de índices
      final snapshot = await query.limit(100).get();

      List<UserModel> users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.id != currentUserId) // Filtrar usuario actual
          .toList();

      // Aplicar filtros adicionales en memoria
      if (minAge != null) {
        users = users.where((user) {
          final userAge = user.age; // Usa el getter age que calcula desde dateOfBirth
          return userAge != null && userAge >= minAge;
        }).toList();
      }

      if (maxAge != null) {
        users = users.where((user) {
          final userAge = user.age; // Usa el getter age que calcula desde dateOfBirth
          return userAge != null && userAge <= maxAge;
        }).toList();
      }

      if (interests != null && interests.isNotEmpty) {
        users = users.where((user) {
          return user.interests.any((interest) => interests.contains(interest));
        }).toList();
      }

      return users.take(50).toList(); // Limitar resultado final
    } catch (e) {
      throw Exception('Error buscando usuarios para match: $e');
    }
  }

  // Cancelar match
  Future<void> cancelMatch(String matchId) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
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


}