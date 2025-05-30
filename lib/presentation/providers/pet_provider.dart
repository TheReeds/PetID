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

  // Getters
  PetState get state => _state;
  List<PetModel> get userPets => _userPets;
  List<PetModel> get matchPets => _matchPets;
  PetModel? get selectedPet => _selectedPet;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == PetState.loading;

  // Cargar mascotas del usuario
  void loadUserPets(String userId) {
    _petRepository.getUserPets(userId).listen((pets) {
      _userPets = pets;
      _setState(PetState.loaded);
    }, onError: (error) {
      _setError('Error cargando mascotas: $error');
    });
  }

  // Crear nueva mascota
  Future<bool> createPet({
    required PetModel pet,
    List<File>? photoFiles,
  }) async {
    try {
      _setState(PetState.loading);
      _clearError();

      // Subir fotos si existen
      List<String> photoUrls = [];
      if (photoFiles != null && photoFiles.isNotEmpty) {
        // Crear mascota primero para tener el ID
        final tempPetId = DateTime.now().millisecondsSinceEpoch.toString();
        photoUrls = await StorageService.uploadPetPhotos(
          petId: tempPetId,
          imageFiles: photoFiles,
        );
      }

      // Crear mascota con las fotos
      final petWithPhotos = pet.copyWith(
        photos: photoUrls,
        profilePhoto: photoUrls.isNotEmpty ? photoUrls.first : null,
      );

      await _petRepository.createPet(petWithPhotos);
      _setState(PetState.loaded);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Actualizar mascota
  Future<bool> updatePet({
    required PetModel pet,
    List<File>? newPhotoFiles,
  }) async {
    try {
      _setState(PetState.loading);
      _clearError();

      PetModel updatedPet = pet;

      // Subir nuevas fotos si existen
      if (newPhotoFiles != null && newPhotoFiles.isNotEmpty) {
        final newPhotoUrls = await StorageService.uploadPetPhotos(
          petId: pet.id,
          imageFiles: newPhotoFiles,
        );

        // Combinar fotos existentes con nuevas
        final allPhotos = [...pet.photos, ...newPhotoUrls];
        updatedPet = pet.copyWith(
          photos: allPhotos,
          profilePhoto: pet.profilePhoto ?? newPhotoUrls.first,
        );
      }

      await _petRepository.updatePet(updatedPet);
      _setState(PetState.loaded);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Eliminar mascota
  Future<bool> deletePet(String petId, String ownerId) async {
    try {
      _setState(PetState.loading);
      _clearError();

      await _petRepository.deletePet(petId, ownerId);
      _setState(PetState.loaded);
      return true;
    } catch (e) {
      _setError(e.toString());
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
  Future<bool> markPetAsLost(String petId) async {
    try {
      await _petRepository.markPetAsLost(petId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Marcar como encontrada
  Future<bool> markPetAsFound(String petId) async {
    try {
      await _petRepository.markPetAsFound(petId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
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
}