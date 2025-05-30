import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/lost_pet_model.dart';
import '../services/firebase_service.dart';

class LostPetRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _uuid = const Uuid();

  // Obtener todas las mascotas perdidas activas
  Stream<List<LostPetModel>> getActiveLostPets({int limit = 50}) {
    return FirebaseService.lostPets
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => LostPetModel.fromFirestore(doc))
        .toList());
  }

  // Obtener mascotas perdidas cerca de una ubicación
  Future<List<LostPetModel>> getLostPetsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Firestore no soporta queries geoespaciales complejas nativamente
      // Por ahora obtenemos todas las activas y filtramos en memoria
      final snapshot = await FirebaseService.lostPets
          .where('status', isEqualTo: 'active')
          .get();

      final lostPets = snapshot.docs
          .map((doc) => LostPetModel.fromFirestore(doc))
          .toList();

      // Filtrar por distancia (implementación básica)
      return lostPets.where((pet) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          pet.lastSeenLocation.latitude,
          pet.lastSeenLocation.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      print('Error getting nearby lost pets: $e');
      return [];
    }
  }

  // Reportar mascota perdida
  Future<String> reportLostPet(LostPetModel lostPet) async {
    try {
      final reportId = _uuid.v4();
      await FirebaseService.lostPets.doc(reportId).set(lostPet.toFirestore());

      // Marcar la mascota como perdida en su perfil
      await FirebaseService.pets.doc(lostPet.petId).update({
        'isLost': true,
        'updatedAt': Timestamp.now(),
      });

      return reportId;
    } catch (e) {
      throw Exception('Error reportando mascota perdida: $e');
    }
  }

  // Actualizar reporte de mascota perdida
  Future<void> updateLostPetReport(LostPetModel lostPet) async {
    try {
      await FirebaseService.lostPets.doc(lostPet.id).update(lostPet.toFirestore());
    } catch (e) {
      throw Exception('Error actualizando reporte: $e');
    }
  }

  // Marcar mascota como encontrada
  Future<void> markPetAsFound(String reportId, String petId) async {
    try {
      // Actualizar el reporte
      await FirebaseService.lostPets.doc(reportId).update({
        'status': 'found',
        'updatedAt': Timestamp.now(),
      });

      // Actualizar el perfil de la mascota
      await FirebaseService.pets.doc(petId).update({
        'isLost': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error marcando como encontrada: $e');
    }
  }

  // Obtener reportes de un usuario
  Stream<List<LostPetModel>> getUserLostPetReports(String userId) {
    return FirebaseService.lostPets
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => LostPetModel.fromFirestore(doc))
        .toList());
  }

  // Obtener reporte por ID
  Future<LostPetModel?> getLostPetReportById(String reportId) async {
    try {
      final doc = await FirebaseService.lostPets.doc(reportId).get();
      if (doc.exists) {
        return LostPetModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting lost pet report: $e');
      return null;
    }
  }

  // Calcular distancia entre dos puntos (fórmula de Haversine simplificada)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radio de la Tierra en km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}