import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'firebase_service.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseService.storage;
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
}