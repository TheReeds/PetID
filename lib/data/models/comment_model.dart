import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final List<String> likes;
  final String? replyToId; // Para respuestas a comentarios
  final List<String> replies; // IDs de respuestas
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final bool isDeleted;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.likes = const [],
    this.replyToId,
    this.replies = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
    this.isDeleted = false,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CommentModel(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      replyToId: data['replyToId'],
      replies: List<String>.from(data['replies'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isEdited: data['isEdited'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'content': content,
      'likes': likes,
      'replyToId': replyToId,
      'replies': replies,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
    };
  }

  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }

  bool get isReply => replyToId != null;
  bool get hasReplies => replies.isNotEmpty;
  int get repliesCount => replies.length;

  CommentModel copyWith({
    String? content,
    List<String>? likes,
    List<String>? replies,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      authorId: authorId,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      replyToId: replyToId,
      replies: replies ?? this.replies,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Factory method para crear un nuevo comentario
  factory CommentModel.create({
    required String postId,
    required String authorId,
    required String content,
    String? replyToId,
  }) {
    final now = DateTime.now();
    return CommentModel(
      id: '', // Se asignará en el repository
      postId: postId,
      authorId: authorId,
      content: content,
      replyToId: replyToId,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, authorId: $authorId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}