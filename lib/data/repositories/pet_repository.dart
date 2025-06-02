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
  Future<List<PetModel>> getUserPetsList(String ownerId) async {
    try {
      final snapshot = await FirebaseService.pets
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => PetModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo lista de mascotas del usuario: $e');
      throw Exception('Error obteniendo mascotas: $e');
    }
  }

  Future<List<PetModel>> getPopularPets({int limit = 10}) async {
    try {
      // Obtener mascotas más recientes como "populares"
      final snapshot = await FirebaseService.pets
          .where('isLost', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => PetModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error obteniendo mascotas populares: $e');
      return [];
    }
  }

  Future<List<PetModel>> searchPublicPets({
    String? query,
    PetType? type,
    PetSize? size,
    String? location,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> petQuery = FirebaseService.pets as Query<Map<String, dynamic>>;

      // Agregar filtros según los parámetros
      if (type != null) {
        petQuery = petQuery.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (size != null) {
        petQuery = petQuery.where('size', isEqualTo: size.toString().split('.').last);
      }

      // Aplicar límite y ordenar
      petQuery = petQuery
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await petQuery.get();
      List<PetModel> pets = snapshot.docs.map((doc) => PetModel.fromFirestore(doc)).toList();

      // Filtrar por query de texto si se proporciona
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        pets = pets.where((pet) =>
        pet.name.toLowerCase().contains(lowerQuery) ||
            pet.breed.toLowerCase().contains(lowerQuery) ||
            pet.description.toLowerCase().contains(lowerQuery)
        ).toList();
      }

      return pets;
    } catch (e) {
      print('❌ Error buscando mascotas públicas: $e');
      return [];
    }
  }

  Future<PetModel?> getPetById(String petId) async {
    try {
      final doc = await FirebaseService.pets.doc(petId).get();

      if (doc.exists) {
        return PetModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('❌ Error obteniendo mascota por ID: $e');
      return null;
    }
  }
}