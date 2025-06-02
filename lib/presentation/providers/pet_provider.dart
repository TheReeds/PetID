import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../data/models/pet_model.dart';
import '../../data/repositories/pet_repository.dart';
import '../../data/services/storage_service.dart';

enum PetState { idle, loading, loaded, error }

class PetProvider extends ChangeNotifier {
  final PetRepository _petRepository = PetRepository();

  PetState _state = PetState.idle;
  List<PetModel> _userPets = [];
  List<PetModel> _matchPets = [];
  PetModel? _selectedPet;
  String? _errorMessage;

  // NUEVO: Cache para mascotas de otros usuarios
  final Map<String, List<PetModel>> _otherUserPetsCache = {};

  // NUEVO: Cache para una sola mascota
  final Map<String, PetModel> _petCache = {};

  // Getters
  PetState get state => _state;
  List<PetModel> get userPets => _userPets;
  List<PetModel> get matchPets => _matchPets;
  PetModel? get selectedPet => _selectedPet;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == PetState.loading;

  // NUEVO: Obtener mascotas de otro usuario
  List<PetModel>? getUserPetsByOwnerId(String ownerId) {
    return _otherUserPetsCache[ownerId];
  }

  // NUEVO: Cargar mascotas de otro usuario
  Future<List<PetModel>> loadOtherUserPets(String ownerId) async {
    try {
      print('🐕 Cargando mascotas del usuario: $ownerId');

      // Verificar cache primero
      if (_otherUserPetsCache.containsKey(ownerId)) {
        print('✅ Mascotas encontradas en cache');
        return _otherUserPetsCache[ownerId]!;
      }

      _setState(PetState.loading);

      final pets = await _petRepository.getUserPetsList(ownerId);

      // Guardar en cache
      _otherUserPetsCache[ownerId] = pets;

      print('✅ ${pets.length} mascotas cargadas para usuario $ownerId');

      _setState(PetState.loaded);
      notifyListeners();

      return pets;
    } catch (e) {
      print('❌ Error cargando mascotas de otro usuario: $e');
      _setError('Error cargando mascotas: $e');
      return [];
    }
  }

  // NUEVO: Obtener una mascota específica por ID
  Future<PetModel?> getPetById(String petId) async {
    try {
      // Verificar cache primero
      if (_petCache.containsKey(petId)) {
        return _petCache[petId];
      }

      print('🔍 Obteniendo mascota: $petId');

      final pet = await _petRepository.getPetById(petId);

      if (pet != null) {
        _petCache[petId] = pet;
        print('✅ Mascota encontrada: ${pet.name}');
      }

      return pet;
    } catch (e) {
      print('❌ Error obteniendo mascota: $e');
      _setError('Error obteniendo mascota: $e');
      return null;
    }
  }

  // NUEVO: Precargar mascotas populares/recientes
  Future<List<PetModel>> getPopularPets({int limit = 10}) async {
    try {
      print('🌟 Cargando mascotas populares...');

      final pets = await _petRepository.getPopularPets(limit: limit);

      // Actualizar cache
      for (var pet in pets) {
        _petCache[pet.id] = pet;
      }

      print('✅ ${pets.length} mascotas populares cargadas');

      return pets;
    } catch (e) {
      print('❌ Error cargando mascotas populares: $e');
      return [];
    }
  }

  // NUEVO: Buscar mascotas públicas
  Future<List<PetModel>> searchPublicPets({
    String? query,
    PetType? type,
    PetSize? size,
    String? location,
    int limit = 20,
  }) async {
    try {
      print('🔍 Buscando mascotas públicas...');

      final pets = await _petRepository.searchPublicPets(
        query: query,
        type: type,
        size: size,
        location: location,
        limit: limit,
      );

      // Actualizar cache
      for (var pet in pets) {
        _petCache[pet.id] = pet;
      }

      print('✅ ${pets.length} mascotas encontradas');

      return pets;
    } catch (e) {
      print('❌ Error buscando mascotas: $e');
      return [];
    }
  }

  // Cargar mascotas del usuario (método existente mejorado)
  void loadUserPets(String userId) {
    print('🐾 Cargando mascotas del usuario: $userId');

    _petRepository.getUserPets(userId).listen((pets) {
      _userPets = pets;

      // Actualizar cache
      for (var pet in pets) {
        _petCache[pet.id] = pet;
      }

      print('✅ ${pets.length} mascotas del usuario cargadas');
      _setState(PetState.loaded);
    }, onError: (error) {
      print('❌ Error cargando mascotas del usuario: $error');
      _setError('Error cargando mascotas: $error');
    });
  }

  // MEJORADO: Crear nueva mascota con mejor manejo
  Future<bool> createPet({
    required PetModel pet,
    List<File>? photoFiles,
  }) async {
    try {
      _setState(PetState.loading);
      _clearError();

      print('🐕 Creando nueva mascota: ${pet.name}');

      // Subir fotos si existen
      List<String> photoUrls = [];
      if (photoFiles != null && photoFiles.isNotEmpty) {
        print('📷 Subiendo ${photoFiles.length} fotos...');

        // Crear ID temporal para la mascota
        final tempPetId = DateTime.now().millisecondsSinceEpoch.toString();

        photoUrls = await StorageService.uploadPetPhotos(
          petId: tempPetId,
          imageFiles: photoFiles,
        );

        print('✅ ${photoUrls.length} fotos subidas exitosamente');
      }

      // Crear mascota con las fotos
      final petWithPhotos = pet.copyWith(
        photos: photoUrls,
        profilePhoto: photoUrls.isNotEmpty ? photoUrls.first : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _petRepository.createPet(petWithPhotos);

      print('✅ Mascota ${pet.name} creada exitosamente');
      _setState(PetState.loaded);
      return true;
    } catch (e) {
      print('❌ Error creando mascota: $e');
      _setError('Error creando mascota: $e');
      return false;
    }
  }

  // MEJORADO: Actualizar mascota
  Future<bool> updatePet({
    required PetModel pet,
    List<File>? newPhotoFiles,
    List<String>? photosToDelete,
  }) async {
    try {
      _setState(PetState.loading);
      _clearError();

      print('📝 Actualizando mascota: ${pet.name}');

      PetModel updatedPet = pet.copyWith(updatedAt: DateTime.now());

      // Eliminar fotos si se especificaron
      if (photosToDelete != null && photosToDelete.isNotEmpty) {
        print('🗑️ Eliminando ${photosToDelete.length} fotos...');

        for (String photoUrl in photosToDelete) {
          try {
            await StorageService.deletePhoto(photoUrl);
          } catch (e) {
            print('⚠️ Error eliminando foto: $e');
          }
        }

        // Actualizar lista de fotos
        final remainingPhotos = pet.photos.where((photo) =>
        !photosToDelete.contains(photo)).toList();
        updatedPet = updatedPet.copyWith(photos: remainingPhotos);
      }

      // Subir nuevas fotos si existen
      if (newPhotoFiles != null && newPhotoFiles.isNotEmpty) {
        print('📷 Subiendo ${newPhotoFiles.length} fotos nuevas...');

        final newPhotoUrls = await StorageService.uploadPetPhotos(
          petId: pet.id,
          imageFiles: newPhotoFiles,
        );

        // Combinar fotos existentes con nuevas
        final allPhotos = [...updatedPet.photos, ...newPhotoUrls];
        updatedPet = updatedPet.copyWith(
          photos: allPhotos,
          profilePhoto: updatedPet.profilePhoto ?? newPhotoUrls.first,
        );

        print('✅ ${newPhotoUrls.length} fotos nuevas subidas');
      }

      await _petRepository.updatePet(updatedPet);

      // Actualizar cache
      _petCache[updatedPet.id] = updatedPet;

      // Actualizar en la lista de mascotas del usuario
      final index = _userPets.indexWhere((p) => p.id == updatedPet.id);
      if (index != -1) {
        _userPets[index] = updatedPet;
      }

      print('✅ Mascota ${pet.name} actualizada exitosamente');
      _setState(PetState.loaded);
      return true;
    } catch (e) {
      print('❌ Error actualizando mascota: $e');
      _setError('Error actualizando mascota: $e');
      return false;
    }
  }

  // MEJORADO: Eliminar mascota con limpieza completa
  Future<bool> deletePet(String petId, String ownerId) async {
    try {
      _setState(PetState.loading);
      _clearError();

      print('🗑️ Eliminando mascota: $petId');

      // Obtener datos de la mascota para limpiar fotos
      final pet = _petCache[petId] ?? await getPetById(petId);

      if (pet != null) {
        // Eliminar todas las fotos
        final photosToDelete = [...pet.photos];
        if (pet.profilePhoto != null && !photosToDelete.contains(pet.profilePhoto)) {
          photosToDelete.add(pet.profilePhoto!);
        }

        print('🗑️ Eliminando ${photosToDelete.length} fotos...');

        for (String photoUrl in photosToDelete) {
          try {
            await StorageService.deletePhoto(photoUrl);
          } catch (e) {
            print('⚠️ Error eliminando foto: $e');
          }
        }
      }

      await _petRepository.deletePet(petId, ownerId);

      // Limpiar cache
      _petCache.remove(petId);

      // Remover de la lista de mascotas del usuario
      _userPets.removeWhere((pet) => pet.id == petId);

      // Limpiar de cache de otros usuarios si existe
      _otherUserPetsCache.forEach((userId, pets) {
        pets.removeWhere((pet) => pet.id == petId);
      });

      print('✅ Mascota eliminada exitosamente');
      _setState(PetState.loaded);
      return true;
    } catch (e) {
      print('❌ Error eliminando mascota: $e');
      _setError('Error eliminando mascota: $e');
      return false;
    }
  }

  // Buscar mascotas para match
  void searchPetsForMatch({
    required PetType type,
    required PetSize size,
    bool forMating = false,
    bool forAdoption = false,
  }) {
    _petRepository.searchPetsForMatch(
      type: type,
      size: size,
      forMating: forMating,
      forAdoption: forAdoption,
    ).listen((pets) {
      _matchPets = pets;

      // Actualizar cache
      for (var pet in pets) {
        _petCache[pet.id] = pet;
      }

      _setState(PetState.loaded);
    }, onError: (error) {
      _setError('Error buscando mascotas: $error');
    });
  }

  // Seleccionar mascota
  void selectPet(PetModel pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  // Obtener mascota por QR
  Future<PetModel?> getPetByQRCode(String qrCode) async {
    try {
      return await _petRepository.getPetByQRCode(qrCode);
    } catch (e) {
      _setError('Error obteniendo mascota por QR: $e');
      return null;
    }
  }

  // Marcar como perdida
  Future<bool> markPetAsLost(String petId, {LocationInfo? lastKnownLocation}) async {
    try {
      final pet = _petCache[petId] ?? await getPetById(petId);
      if (pet == null) {
        throw Exception('Mascota no encontrada');
      }

      print('🚨 Marcando ${pet.name} como perdida...');

      final updatedPet = pet.copyWith(
        isLost: true,
        lastKnownLocation: lastKnownLocation ?? pet.lastKnownLocation,
        updatedAt: DateTime.now(),
      );

      await _petRepository.updatePet(updatedPet);

      // Actualizar cache
      _petCache[petId] = updatedPet;

      // Actualizar en lista de usuario
      final index = _userPets.indexWhere((p) => p.id == petId);
      if (index != -1) {
        _userPets[index] = updatedPet;
      }

      print('✅ ${pet.name} marcada como perdida');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error marcando mascota como perdida: $e');
      _setError('Error: $e');
      return false;
    }
  }

  // Marcar como encontrada
  Future<bool> markPetAsFound(String petId) async {
    try {
      final pet = _petCache[petId] ?? await getPetById(petId);
      if (pet == null) {
        throw Exception('Mascota no encontrada');
      }

      print('🏠 Marcando ${pet.name} como encontrada...');

      final updatedPet = pet.copyWith(
        isLost: false,
        updatedAt: DateTime.now(),
      );

      await _petRepository.updatePet(updatedPet);

      // Actualizar cache
      _petCache[petId] = updatedPet;

      // Actualizar en lista de usuario
      final index = _userPets.indexWhere((p) => p.id == petId);
      if (index != -1) {
        _userPets[index] = updatedPet;
      }

      print('✅ ${pet.name} marcada como encontrada');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error marcando mascota como encontrada: $e');
      _setError('Error: $e');
      return false;
    }
  }

  // NUEVO: Agregar fotos a una mascota existente
  Future<bool> addPhotos(String petId, List<File> photoFiles) async {
    try {
      final pet = _petCache[petId] ?? await getPetById(petId);
      if (pet == null) {
        throw Exception('Mascota no encontrada');
      }

      print('📷 Agregando ${photoFiles.length} fotos a ${pet.name}...');

      final newPhotoUrls = await StorageService.uploadPetPhotos(
        petId: petId,
        imageFiles: photoFiles,
      );

      final updatedPhotos = [...pet.photos, ...newPhotoUrls];
      final updatedPet = pet.copyWith(
        photos: updatedPhotos,
        profilePhoto: pet.profilePhoto ?? newPhotoUrls.first,
        updatedAt: DateTime.now(),
      );

      await _petRepository.updatePet(updatedPet);

      // Actualizar cache
      _petCache[petId] = updatedPet;

      print('✅ ${newPhotoUrls.length} fotos agregadas exitosamente');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error agregando fotos: $e');
      _setError('Error agregando fotos: $e');
      return false;
    }
  }

  // NUEVO: Actualizar información médica
  Future<bool> updateHealthInfo(String petId, HealthInfo healthInfo) async {
    try {
      final pet = _petCache[petId] ?? await getPetById(petId);
      if (pet == null) {
        throw Exception('Mascota no encontrada');
      }

      print('🏥 Actualizando información médica de ${pet.name}...');

      final updatedPet = pet.copyWith(
        healthInfo: healthInfo,
        updatedAt: DateTime.now(),
      );

      await _petRepository.updatePet(updatedPet);

      // Actualizar cache
      _petCache[petId] = updatedPet;

      print('✅ Información médica actualizada');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error actualizando información médica: $e');
      _setError('Error actualizando información médica: $e');
      return false;
    }
  }

  // NUEVO: Obtener estadísticas de mascotas del usuario
  Map<String, int> getUserPetStats(String userId) {
    final pets = userId == _getCurrentUserId() ? _userPets : (_otherUserPetsCache[userId] ?? []);

    return {
      'total': pets.length,
      'lost': pets.where((pet) => pet.isLost).length,
      'safe': pets.where((pet) => !pet.isLost).length,
      'forAdoption': pets.where((pet) => pet.isForAdoption).length,
      'forMating': pets.where((pet) => pet.isForMating).length,
      'vaccinated': pets.where((pet) => pet.isVaccinated).length,
      'microchipped': pets.where((pet) => pet.isMicrochipped).length,
    };
  }

  // NUEVO: Filtrar mascotas por criterios
  List<PetModel> filterPets({
    List<PetModel>? pets,
    PetType? type,
    PetSize? size,
    PetSex? sex,
    bool? isLost,
    bool? isForAdoption,
    bool? isForMating,
    String? searchQuery,
  }) {
    final petsToFilter = pets ?? _userPets;

    return petsToFilter.where((pet) {
      if (type != null && pet.type != type) return false;
      if (size != null && pet.size != size) return false;
      if (sex != null && pet.sex != sex) return false;
      if (isLost != null && pet.isLost != isLost) return false;
      if (isForAdoption != null && pet.isForAdoption != isForAdoption) return false;
      if (isForMating != null && pet.isForMating != isForMating) return false;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return pet.name.toLowerCase().contains(query) ||
            pet.breed.toLowerCase().contains(query) ||
            pet.description.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  // NUEVO: Limpiar cache específico
  void clearUserPetsCache(String userId) {
    _otherUserPetsCache.remove(userId);
    print('🧹 Cache de mascotas del usuario $userId limpiado');
  }

  // NUEVO: Limpiar todo el cache
  void clearAllCache() {
    _petCache.clear();
    _otherUserPetsCache.clear();
    print('🧹 Todo el cache de mascotas limpiado');
  }

  // NUEVO: Refrescar datos de una mascota específica
  Future<PetModel?> refreshPet(String petId) async {
    try {
      print('🔄 Refrescando datos de mascota: $petId');

      // Remover del cache para forzar recarga
      _petCache.remove(petId);

      // Obtener datos frescos
      final pet = await getPetById(petId);

      if (pet != null) {
        // Actualizar en lista de usuario si corresponde
        final index = _userPets.indexWhere((p) => p.id == petId);
        if (index != -1) {
          _userPets[index] = pet;
        }

        notifyListeners();
      }

      return pet;
    } catch (e) {
      print('❌ Error refrescando mascota: $e');
      return null;
    }
  }

  // Métodos helper privados
  String? _getCurrentUserId() {
    // Esta función debería obtener el ID del usuario actual
    // desde AuthProvider o donde esté almacenado
    return null; // Implementar según la arquitectura
  }

  // Métodos privados
  void _setState(PetState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = PetState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() => _clearError();

  @override
  void dispose() {
    clearAllCache();
    super.dispose();
  }
}