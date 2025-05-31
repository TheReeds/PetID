import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchType { mating, adoption, playdate, friendship }
enum MatchStatus { pending, accepted, rejected, cancelled, completed }

class MatchModel {
  final String id;
  final String fromPetId;
  final String toPetId;
  final String fromUserId;
  final String toUserId;
  final MatchType type;
  final MatchStatus status;
  final String? message;
  final String? responseMessage;
  final double? rating;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;
  final DateTime? ratedAt;

  MatchModel({
    required this.id,
    required this.fromPetId,
    required this.toPetId,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.status,
    this.message,
    this.responseMessage,
    this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
    this.completedAt,
    this.ratedAt,
  });

  List<String> get participants => [fromUserId, toUserId];

  bool isFromUser(String userId) => fromUserId == userId;
  bool isToUser(String userId) => toUserId == userId;
  bool get isPending => status == MatchStatus.pending;
  bool get isAccepted => status == MatchStatus.accepted;
  bool get isCompleted => status == MatchStatus.completed;

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MatchModel(
      id: doc.id,
      fromPetId: data['fromPetId'] ?? '',
      toPetId: data['toPetId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      type: MatchType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
        orElse: () => MatchType.friendship,
      ),
      status: MatchStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => MatchStatus.pending,
      ),
      message: data['message'],
      responseMessage: data['responseMessage'],
      rating: data['rating']?.toDouble(),
      review: data['review'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      ratedAt: data['ratedAt'] != null
          ? (data['ratedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromPetId': fromPetId,
      'toPetId': toPetId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'participants': participants,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'message': message,
      'responseMessage': responseMessage,
      'rating': rating,
      'review': review,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'ratedAt': ratedAt != null ? Timestamp.fromDate(ratedAt!) : null,
    };
  }

  MatchModel copyWith({
    MatchStatus? status,
    String? responseMessage,
    double? rating,
    String? review,
    DateTime? respondedAt,
    DateTime? completedAt,
    DateTime? ratedAt,
  }) {
    return MatchModel(
      id: id,
      fromPetId: fromPetId,
      toPetId: toPetId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      type: type,
      status: status ?? this.status,
      message: message,
      responseMessage: responseMessage ?? this.responseMessage,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
      ratedAt: ratedAt ?? this.ratedAt,
    );
  }
}