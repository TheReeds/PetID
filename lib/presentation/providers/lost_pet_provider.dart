import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../data/models/lost_pet_model.dart';
import '../../data/repositories/lost_pet_repository.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/notification_service.dart';

enum LostPetState { idle, loading, loaded, error }

class LostPetProvider extends ChangeNotifier {
  final LostPetRepository _lostPetRepository = LostPetRepository();

  LostPetState _state = LostPetState.idle;
  List<LostPetModel> _activeLostPets = [];
  List<LostPetModel> _userReports = [];
  String? _errorMessage;

  // Getters
  LostPetState get state => _state;
  List<LostPetModel> get activeLostPets => _activeLostPets;
  List<LostPetModel> get userReports => _userReports;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LostPetState.loading;

  // Cargar mascotas perdidas activas
  void loadActiveLostPets({int limit = 50}) {
    _lostPetRepository.getActiveLostPets(limit: limit).listen((lostPets) {
      _activeLostPets = lostPets;
      _setState(LostPetState.loaded);
    }, onError: (error) {
      _setError('Error cargando mascotas perdidas: $error');
    });
  }

  // Cargar mascotas perdidas cerca de una ubicación
  Future<List<LostPetModel>> getLostPetsNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      return await _lostPetRepository.getLostPetsNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      _setError('Error buscando mascotas cercanas: $e');
      return [];
    }
  }

  // Reportar mascota perdida
  Future<bool> reportLostPet({
    required LostPetModel lostPet,
    List<File>? photoFiles,
  }) async {
    try {
      _setState(LostPetState.loading);
      _clearError();

      // Subir fotos si existen
      List<String> photoUrls = [];
      if (photoFiles != null && photoFiles.isNotEmpty) {
        photoUrls = await StorageService.uploadLostPetPhotos(
          reportId: DateTime.now().millisecondsSinceEpoch.toString(),
          imageFiles: photoFiles,
        );
      }

      // Crear reporte con las fotos
      final lostPetWithPhotos = lostPet.copyWith(photos: photoUrls);

      final reportId = await _lostPetRepository.reportLostPet(lostPetWithPhotos);

      // Enviar notificación push a todos los usuarios
      await NotificationService.sendLostPetNotification(lostPetWithPhotos);

      _setState(LostPetState.loaded);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Actualizar reporte de mascota perdida
  Future<bool> updateLostPetReport(LostPetModel lostPet) async {
    try {
      _setState(LostPetState.loading);
      _clearError();

      await _lostPetRepository.updateLostPetReport(lostPet);

      _setState(LostPetState.loaded);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Marcar mascota como encontrada
  Future<bool> markPetAsFound(String reportId, String petId) async {
    try {
      _setState(LostPetState.loading);
      _clearError();

      await _lostPetRepository.markPetAsFound(reportId, petId);

      // Enviar notificación de que fue encontrada
      await NotificationService.sendPetFoundNotification(reportId);

      _setState(LostPetState.loaded);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Cargar reportes del usuario
  void loadUserReports(String userId) {
    _lostPetRepository.getUserLostPetReports(userId).listen((reports) {
      _userReports = reports;
      _setState(LostPetState.loaded);
    }, onError: (error) {
      _setError('Error cargando reportes del usuario: $error');
    });
  }

  // Obtener reporte por ID
  Future<LostPetModel?> getLostPetReportById(String reportId) async {
    try {
      return await _lostPetRepository.getLostPetReportById(reportId);
    } catch (e) {
      _setError('Error obteniendo reporte: $e');
      return null;
    }
  }

  // Agregar usuario que ayudó
  Future<bool> addHelpfulUser(String reportId, String userId) async {
    try {
      final report = await getLostPetReportById(reportId);
      if (report != null && !report.helpfulUsers.contains(userId)) {
        final updatedReport = report.copyWith(
          helpfulUsers: [...report.helpfulUsers, userId],
        );
        return await updateLostPetReport(updatedReport);
      }
      return false;
    } catch (e) {
      _setError('Error agregando usuario: $e');
      return false;
    }
  }

  // Cerrar reporte
  Future<bool> closeLostPetReport(String reportId) async {
    try {
      final report = await getLostPetReportById(reportId);
      if (report != null) {
        final updatedReport = report.copyWith(status: LostPetStatus.closed);
        return await updateLostPetReport(updatedReport);
      }
      return false;
    } catch (e) {
      _setError('Error cerrando reporte: $e');
      return false;
    }
  }

  // Métodos privados
  void _setState(LostPetState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = LostPetState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() => _clearError();
}