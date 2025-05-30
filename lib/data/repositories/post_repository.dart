import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _uuid = const Uuid();

  // Obtener feed de posts (últimos posts públicos)
  Stream<List<PostModel>> getFeedPosts({int limit = 20}) {
    return FirebaseService.posts
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList());
  }

  // Obtener posts de un usuario específico
  Stream<List<PostModel>> getUserPosts(String userId) {
    return FirebaseService.posts
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList());
  }

  // Obtener posts de una mascota específica
  Stream<List<PostModel>> getPetPosts(String petId) {
    return FirebaseService.posts
        .where('petId', isEqualTo: petId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList());
  }

  // Crear nuevo post
  Future<String> createPost(PostModel post) async {
    try {
      final postId = _uuid.v4();
      await FirebaseService.posts.doc(postId).set(post.toFirestore());
      return postId;
    } catch (e) {
      throw Exception('Error creando post: $e');
    }
  }

  // Actualizar post
  Future<void> updatePost(PostModel post) async {
    try {
      await FirebaseService.posts.doc(post.id).update(post.toFirestore());
    } catch (e) {
      throw Exception('Error actualizando post: $e');
    }
  }

  // Eliminar post
  Future<void> deletePost(String postId) async {
    try {
      await FirebaseService.posts.doc(postId).delete();
    } catch (e) {
      throw Exception('Error eliminando post: $e');
    }
  }

  // Dar/quitar like a un post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final postRef = FirebaseService.posts.doc(postId);
      final doc = await postRef.get();

      if (doc.exists) {
        final post = PostModel.fromFirestore(doc);
        List<String> newLikes = List.from(post.likes);

        if (newLikes.contains(userId)) {
          newLikes.remove(userId);
        } else {
          newLikes.add(userId);
        }

        await postRef.update({
          'likes': newLikes,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Error toggle like: $e');
    }
  }

  // Buscar posts por hashtag
  Stream<List<PostModel>> searchPostsByHashtag(String hashtag) {
    return FirebaseService.posts
        .where('hashtags', arrayContains: hashtag.toLowerCase())
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList());
  }

  // Obtener post por ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final doc = await FirebaseService.posts.doc(postId).get();
      if (doc.exists) {
        return PostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }
}