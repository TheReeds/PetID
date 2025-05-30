import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { photo, video, story, announcement }

class PostModel {
  final String id;
  final String authorId;
  final String? petId;
  final PostType type;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
  final List<String> hashtags;
  final List<String> likes;
  final int commentsCount;
  final GeoPoint? location;
  final String? locationName;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.authorId,
    this.petId,
    required this.type,
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
    this.hashtags = const [],
    this.likes = const [],
    this.commentsCount = 0,
    this.location,
    this.locationName,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      petId: data['petId'],
      type: PostType.values.firstWhere(
            (e) => e.toString() == 'PostType.${data['type']}',
        orElse: () => PostType.photo,
      ),
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      hashtags: List<String>.from(data['hashtags'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
      location: data['location'],
      locationName: data['locationName'],
      isPublic: data['isPublic'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'petId': petId,
      'type': type.toString().split('.').last,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'hashtags': hashtags,
      'likes': likes,
      'commentsCount': commentsCount,
      'location': location,
      'locationName': locationName,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }

  PostModel copyWith({
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    List<String>? hashtags,
    List<String>? likes,
    int? commentsCount,
    bool? isPublic,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      petId: petId,
      type: type,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      hashtags: hashtags ?? this.hashtags,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      location: location,
      locationName: locationName,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}