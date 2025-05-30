import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/pet_model.dart';
import '../services/firebase_service.dart';

class PetRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _uuid = const Uuid();

  // Obtener mascotas del usuario actual
  Stream<List<PetModel>> getUserPets(String userId) {
    return FirebaseService.pets
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PetModel.fromFirestore(doc))
        .toList());
  }

  // Obtener una mascota por ID
  Future<PetModel?> getPetById(String petId) async {
    try {
      final doc = await FirebaseService.pets.doc(petId).get();
      if (doc.exists) {
        return PetModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting pet: $e');
      return null;
    }
  }

  // Crear nueva mascota
  Future<String> createPet(PetModel pet) async {
    try {
      final petId = _uuid.v4();
      final qrCode = _generateQRCode(petId);

      final newPet = pet.copyWith().copyWith(); // Force update timestamp

      await FirebaseService.pets.doc(petId).set({
        ...newPet.toFirestore(),
        'qrCode': qrCode,
      });

      // Agregar mascota a la lista del usuario
      await _addPetToUser(pet.ownerId, petId);

      return petId;
    } catch (e) {
      throw Exception('Error creando mascota: $e');
    }
  }

  // Actualizar mascota
  Future<void> updatePet(PetModel pet) async {
    try {
      await FirebaseService.pets.doc(pet.id).update(pet.toFirestore());
    } catch (e) {
      throw Exception('Error actualizando mascota: $e');
    }
  }

  // Eliminar mascota
  Future<void> deletePet(String petId, String ownerId) async {
    try {
      await FirebaseService.pets.doc(petId).delete();
      await _removePetFromUser(ownerId, petId);
    } catch (e) {
      throw Exception('Error eliminando mascota: $e');
    }
  }

  // Buscar mascotas por tipo y ubicación para match
  Stream<List<PetModel>> searchPetsForMatch({
    required PetType type,
    required PetSize size,
    bool forMating = false,
    bool forAdoption = false,
  }) {
    Query query = FirebaseService.pets.where('type', isEqualTo: type.toString().split('.').last);

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
        .where((pet) => pet.size == size)
        .toList());
  }

  // Marcar mascota como perdida
  Future<void> markPetAsLost(String petId) async {
    try {
      await FirebaseService.pets.doc(petId).update({
        'isLost': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error marcando mascota como perdida: $e');
    }
  }

  // Marcar mascota como encontrada
  Future<void> markPetAsFound(String petId) async {
    try {
      await FirebaseService.pets.doc(petId).update({
        'isLost': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error marcando mascota como encontrada: $e');
    }
  }

  // Obtener mascota por código QR
  Future<PetModel?> getPetByQRCode(String qrCode) async {
    try {
      final querySnapshot = await FirebaseService.pets
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return PetModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting pet by QR: $e');
      return null;
    }
  }

  // Funciones privadas
  String _generateQRCode(String petId) {
    return 'petid://pet/$petId';
  }

  Future<void> _addPetToUser(String userId, String petId) async {
    await FirebaseService.users.doc(userId).update({
      'pets': FieldValue.arrayUnion([petId]),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> _removePetFromUser(String userId, String petId) async {
    await FirebaseService.users.doc(userId).update({
      'pets': FieldValue.arrayRemove([petId]),
      'updatedAt': Timestamp.now(),
    });
  }
}