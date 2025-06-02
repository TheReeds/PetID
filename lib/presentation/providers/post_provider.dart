// lib/presentation/providers/post_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/services/storage_service.dart';

enum PostState { idle, loading, loaded, error }

class PostProvider extends ChangeNotifier {
  final PostRepository _postRepository = PostRepository();

  PostState _state = PostState.idle;
  List<PostModel> _feedPosts = [];
  List<PostModel> _userPosts = [];
  List<PostModel> _petPosts = [];
  PostModel? _selectedPost;
  String? _errorMessage;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;

  // Getters
  PostState get state => _state;
  List<PostModel> get feedPosts => _feedPosts;
  List<PostModel> get userPosts => _userPosts;
  List<PostModel> get petPosts => _petPosts;
  PostModel? get selectedPost => _selectedPost;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == PostState.loading;
  bool get hasMorePosts => _hasMorePosts;

  // Cargar feed principal
  Future<void> loadFeedPosts({bool refresh = false}) async {
    if (_state == PostState.loading && !refresh) return;

    try {
      if (refresh) {
        _lastDocument = null;
        _hasMorePosts = true;
        _feedPosts.clear();
      }

      _setState(PostState.loading);
      _clearError();

      final posts = await _postRepository.getFeedPosts(
        limit: 10,
        lastDocument: _lastDocument,
      );

      if (refresh) {
        _feedPosts = posts;
      } else {
        _feedPosts.addAll(posts);
      }

      _hasMorePosts = posts.length == 10;

      // Guardar el último documento para paginación
      if (posts.isNotEmpty) {
        // Necesitarías acceso al DocumentSnapshot desde el repository
        // Por ahora, usamos el approach básico
        _lastDocument = null;
      }

      _setState(PostState.loaded);
    } catch (e) {
      _setError('Error cargando publicaciones: $e');
    }
  }

  // Cargar posts del usuario
  Future<void> loadUserPosts(String userId) async {
    try {
      _setState(PostState.loading);
      _clearError();

      _postRepository.getUserPosts(userId).listen((posts) {
        _userPosts = posts;
        _setState(PostState.loaded);
      }, onError: (error) {
        _setError('Error cargando posts del usuario: $error');
      });
    } catch (e) {
      _setError('Error: $e');
    }
  }

  // Cargar posts de una mascota específica
  Future<void> loadPetPosts(String petId) async {
    try {
      _setState(PostState.loading);
      _clearError();

      _postRepository.getPetPosts(petId).listen((posts) {
        _petPosts = posts;
        _setState(PostState.loaded);
      }, onError: (error) {
        _setError('Error cargando posts de la mascota: $error');
      });
    } catch (e) {
      _setError('Error: $e');
    }
  }

  // Crear nueva publicación
  Future<bool> createPost({
    required PostModel post,
    List<File>? imageFiles,
  }) async {
    try {
      _setState(PostState.loading);
      _clearError();

      String postId = '';
      List<String> imageUrls = [];

      // Generar ID temporal para subir imágenes
      if (imageFiles != null && imageFiles.isNotEmpty) {
        postId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrls = await StorageService.uploadPostPhotos(
          postId: postId,
          imageFiles: imageFiles,
        );
      }

      // Crear post con las imágenes
      final postWithImages = PostModel(
        id: '', // Se generará en el repository
        authorId: post.authorId,
        petId: post.petId,
        type: post.type,
        content: post.content,
        imageUrls: imageUrls,
        hashtags: post.hashtags,
        isPublic: post.isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdPostId = await _postRepository.createPost(postWithImages);

      // Agregar el nuevo post al inicio de la lista local
      final newPost = postWithImages.copyWith();
      // Actualizar con el ID real
      final finalPost = PostModel(
        id: createdPostId,
        authorId: newPost.authorId,
        petId: newPost.petId,
        type: newPost.type,
        content: newPost.content,
        imageUrls: newPost.imageUrls,
        hashtags: newPost.hashtags,
        isPublic: newPost.isPublic,
        createdAt: newPost.createdAt,
        updatedAt: newPost.updatedAt,
      );

      _feedPosts.insert(0, finalPost);
      _setState(PostState.loaded);

      return true;
    } catch (e) {
      _setError('Error creando publicación: $e');
      return false;
    }
  }

  // Actualizar publicación
  Future<bool> updatePost(PostModel post) async {
    try {
      _setState(PostState.loading);
      _clearError();

      await _postRepository.updatePost(post);

      // Actualizar en las listas locales
      _updatePostInLists(post);
      _setState(PostState.loaded);

      return true;
    } catch (e) {
      _setError('Error actualizando publicación: $e');
      return false;
    }
  }

  // Eliminar publicación
  Future<bool> deletePost(String postId, String authorId) async {
    try {
      _setState(PostState.loading);
      _clearError();

      await _postRepository.deletePost(postId, authorId);

      // Remover de las listas locales
      _removePostFromLists(postId);
      _setState(PostState.loaded);

      return true;
    } catch (e) {
      _setError('Error eliminando publicación: $e');
      return false;
    }
  }

  // Dar/quitar like a una publicación
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final post = _findPostById(postId);
      if (post == null) return false;

      final isLiked = post.isLikedBy(userId);
      List<String> newLikes = List.from(post.likes);

      if (isLiked) {
        newLikes.remove(userId);
      } else {
        newLikes.add(userId);
      }

      final updatedPost = post.copyWith(likes: newLikes);

      // Actualizar localmente primero (optimistic update)
      _updatePostInLists(updatedPost);
      notifyListeners();

      // Luego actualizar en el servidor
      await _postRepository.toggleLike(postId, userId);

      return true;
    } catch (e) {
      _setError('Error actualizando like: $e');
      // Revertir cambio local si falla
      final post = _findPostById(postId);
      if (post != null) {
        _updatePostInLists(post);
        notifyListeners();
      }
      return false;
    }
  }

  // Agregar comentario
  Future<bool> addComment(String postId, String comment, String userId) async {
    try {
      // Este metodo ahora delega al CommentProvider
      // pero aún actualiza el contador local para optimización
      final post = _findPostById(postId);
      if (post != null) {
        final updatedPost = post.copyWith(
          commentsCount: post.commentsCount + 1,
        );
        _updatePostInLists(updatedPost);
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Error agregando comentario: $e');
      return false;
    }
  }
  void updateCommentsCount(String postId, int newCount) {
    final post = _findPostById(postId);
    if (post != null) {
      final updatedPost = post.copyWith(commentsCount: newCount);
      _updatePostInLists(updatedPost);
      notifyListeners();
    }
  }

  // Buscar publicaciones
  Future<List<PostModel>> searchPosts({
    String? query,
    List<String>? hashtags,
    PostType? type,
    String? location,
  }) async {
    try {
      return await _postRepository.searchPosts(
        query: query,
        hashtags: hashtags,
        type: type,
        location: location,
      );
    } catch (e) {
      _setError('Error buscando publicaciones: $e');
      return [];
    }
  }

  // Obtener posts por hashtag
  Future<List<PostModel>> getPostsByHashtag(String hashtag) async {
    try {
      return await _postRepository.getPostsByHashtag(hashtag);
    } catch (e) {
      _setError('Error obteniendo posts por hashtag: $e');
      return [];
    }
  }

  // Reportar publicación
  Future<bool> reportPost(String postId, String reason, String reporterId) async {
    try {
      await _postRepository.reportPost(postId, reason, reporterId);
      return true;
    } catch (e) {
      _setError('Error reportando publicación: $e');
      return false;
    }
  }

  // Obtener publicaciones de mascotas perdidas
  Future<List<PostModel>> getLostPetPosts() async {
    try {
      return await _postRepository.getLostPetPosts();
    } catch (e) {
      _setError('Error obteniendo mascotas perdidas: $e');
      return [];
    }
  }

  // Seleccionar publicación
  void selectPost(PostModel post) {
    _selectedPost = post;
    notifyListeners();
  }

  // Obtener post por ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      return await _postRepository.getPostById(postId);
    } catch (e) {
      _setError('Error obteniendo publicación: $e');
      return null;
    }
  }

  // Refrescar post específico
  Future<void> refreshPost(String postId) async {
    try {
      final refreshedPost = await _postRepository.getPostById(postId);
      if (refreshedPost != null) {
        _updatePostInLists(refreshedPost);
        notifyListeners();
      }
    } catch (e) {
      print('Error refrescando post: $e');
    }
  }

  // Métodos helper privados
  void _updatePostInLists(PostModel updatedPost) {
    // Actualizar en feed
    final feedIndex = _feedPosts.indexWhere((p) => p.id == updatedPost.id);
    if (feedIndex != -1) {
      _feedPosts[feedIndex] = updatedPost;
    }

    // Actualizar en posts del usuario
    final userIndex = _userPosts.indexWhere((p) => p.id == updatedPost.id);
    if (userIndex != -1) {
      _userPosts[userIndex] = updatedPost;
    }

    // Actualizar en posts de mascota
    final petIndex = _petPosts.indexWhere((p) => p.id == updatedPost.id);
    if (petIndex != -1) {
      _petPosts[petIndex] = updatedPost;
    }

    // Actualizar post seleccionado
    if (_selectedPost?.id == updatedPost.id) {
      _selectedPost = updatedPost;
    }
  }

  void _removePostFromLists(String postId) {
    _feedPosts.removeWhere((p) => p.id == postId);
    _userPosts.removeWhere((p) => p.id == postId);
    _petPosts.removeWhere((p) => p.id == postId);

    if (_selectedPost?.id == postId) {
      _selectedPost = null;
    }
  }

  PostModel? _findPostById(String postId) {
    // Buscar en feed primero
    try {
      return _feedPosts.firstWhere((p) => p.id == postId);
    } catch (e) {
      // No encontrado en feed
    }

    // Buscar en posts del usuario
    try {
      return _userPosts.firstWhere((p) => p.id == postId);
    } catch (e) {
      // No encontrado en posts del usuario
    }

    // Buscar en posts de mascota
    try {
      return _petPosts.firstWhere((p) => p.id == postId);
    } catch (e) {
      // No encontrado
    }

    return null;
  }

  // Métodos de estado
  void _setState(PostState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _state = PostState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Limpiar datos (útil para logout)
  void clear() {
    _feedPosts.clear();
    _userPosts.clear();
    _petPosts.clear();
    _selectedPost = null;
    _lastDocument = null;
    _hasMorePosts = true;
    _state = PostState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}