import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'firebase_service.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseService.storage;
  static const String _petsFolder = 'pets';
  static const String _lostPetsFolder = 'lost_pets';
  static const String _postsFolder = 'posts';
  static const String _profilesFolder = 'profiles';
  static const _uuid = Uuid();

  // Subir foto de perfil de usuario
  static Future<String> uploadUserProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('users/$userId/profile/$fileName');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error subiendo foto de perfil: $e');
    }
  }

  // Subir fotos de mascota
  static Future<List<String>> uploadPetPhotos({
    required String petId,
    required List<File> imageFiles,
  }) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final fileName = '${_uuid.v4()}_$i.jpg';
        final ref = _storage.ref().child('pets/$petId/photos/$fileName');

        final uploadTask = ref.putFile(imageFiles[i]);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Error subiendo fotos de mascota: $e');
    }
  }

  // Subir foto individual de mascota
  static Future<String> uploadPetPhoto({
    required String petId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('pets/$petId/photos/$fileName');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error subiendo foto de mascota: $e');
    }
  }

  // Subir fotos de posts
  static Future<List<String>> uploadPostPhotos({
    required String postId,
    required List<File> imageFiles,
  }) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final fileName = '${_uuid.v4()}_$i.jpg';
        final ref = _storage.ref().child('posts/$postId/photos/$fileName');

        final uploadTask = ref.putFile(imageFiles[i]);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Error subiendo fotos del post: $e');
    }
  }

  // Eliminar foto
  static Future<void> deletePhoto(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error eliminando foto: $e');
    }
  }

  // Eliminar múltiples fotos
  static Future<void> deletePhotos(List<String> downloadUrls) async {
    for (String url in downloadUrls) {
      await deletePhoto(url);
    }
  }
  static Future<List<String>> uploadLostPetPhotos({
    required String reportId,
    required List<File> imageFiles,
  }) async {
    try {
      List<String> downloadUrls = [];

      for (File file in imageFiles) {
        final fileName = '${_uuid.v4()}.jpg';
        final ref = _storage.ref().child('$_lostPetsFolder/$reportId/$fileName');

        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Error subiendo fotos de mascota perdida: $e');
    }
  }
  static Future<void> deleteLostPetPhotos(String reportId) async {
    try {
      final ref = _storage.ref().child('$_lostPetsFolder/$reportId');
      final listResult = await ref.listAll();

      for (Reference item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('Error eliminando fotos de reporte: $e');
    }
  }
  static Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error obteniendo URL de descarga: $e');
    }
  }
  static Future<String> uploadEventPhoto({
    required String eventId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('events/$eventId/photos/$fileName');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error subiendo foto del evento: $e');
    }
  }

// Subir múltiples fotos de evento
  static Future<List<String>> uploadEventPhotos({
    required String eventId,
    required List<File> imageFiles,
  }) async {
    try {
      List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final fileName = '${_uuid.v4()}_$i.jpg';
        final ref = _storage.ref().child('events/$eventId/photos/$fileName');

        final uploadTask = ref.putFile(imageFiles[i]);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Error subiendo fotos del evento: $e');
    }
  }

// Eliminar fotos de evento
  static Future<void> deleteEventPhotos(String eventId) async {
    try {
      final ref = _storage.ref().child('events/$eventId');
      final listResult = await ref.listAll();

      for (Reference item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('Error eliminando fotos del evento: $e');
    }
  }
}