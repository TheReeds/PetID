// lib/presentation/providers/post_provider.dart
import 'package:flutter/foundation.dart';
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
  int _currentPage = 0;

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
    if (_state == PostState.loading) return;

    try {
      if (refresh) {
        _currentPage = 0;
        _hasMorePosts = true;
        _feedPosts.clear();
      }

      _setState(PostState.loading);
      _clearError();

      final posts = await _postRepository.getFeedPosts(
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _feedPosts = posts;
      } else {
        _feedPosts.addAll(posts);
      }

      _hasMorePosts = posts.length == 10;
      _currentPage++;
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

      // Subir imágenes si existen
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        final postId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrls = await StorageService.uploadPostPhotos(
          postId: postId,
          imageFiles: imageFiles,
        );
      }

      // Crear post con las imágenes
      final postWithImages = post.copyWith(
        imageUrls: imageUrls,
      );

      await _postRepository.createPost(postWithImages);

      // Recargar feed
      await loadFeedPosts(refresh: true);

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
      return false;
    }
  }

  // Agregar comentario
  Future<bool> addComment(String postId, String comment, String userId) async {
    try {
      await _postRepository.addComment(postId, comment, userId);

      // Actualizar contador de comentarios localmente
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
    PostModel? post = _feedPosts.where((p) => p.id == postId).firstOrNull;
    if (post != null) return post;

    // Buscar en posts del usuario
    post = _userPosts.where((p) => p.id == postId).firstOrNull;
    if (post != null) return post;

    // Buscar en posts de mascota
    post = _petPosts.where((p) => p.id == postId).firstOrNull;
    return post;
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

  void clearError() => _clearError();
}

// Extensión para obtener el primer elemento o null
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}