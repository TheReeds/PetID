// lib/data/models/match_model.dart - Versión extendida
import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchType {
  // Para mascotas
  mating,
  playdate,
  adoption,
  friendship,

  // Para usuarios
  petOwnerFriendship,  // Amistad entre dueños
  petActivity,         // Actividades con mascotas
  petCare,            // Cuidado de mascotas
  socialMeet          // Encuentro social
}

enum MatchStatus { pending, accepted, rejected, cancelled, completed }

enum MatchEntityType { pet, user } // NUEVO: Tipo de entidad

class MatchModel {
  final String id;

  // Información de la solicitud
  final MatchEntityType entityType;     // NUEVO: Si es match de mascotas o usuarios
  final String fromUserId;
  final String toUserId;

  // Para matches de mascotas (pueden ser null si es match de usuarios)
  final String? fromPetId;
  final String? toPetId;

  final MatchType type;
  final MatchStatus status;
  final String? message;
  final String? responseMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;

  // Información adicional
  final Map<String, dynamic> additionalInfo;
  final List<String> participants;

  MatchModel({
    required this.id,
    required this.entityType,
    required this.fromUserId,
    required this.toUserId,
    this.fromPetId,
    this.toPetId,
    required this.type,
    required this.status,
    this.message,
    this.responseMessage,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
    this.completedAt,
    this.additionalInfo = const {},
    required this.participants,
  });

  // Getters de conveniencia
  bool get isPetMatch => entityType == MatchEntityType.pet;
  bool get isUserMatch => entityType == MatchEntityType.user;
  bool get isPending => status == MatchStatus.pending;
  bool get isAccepted => status == MatchStatus.accepted;
  bool get isCompleted => status == MatchStatus.completed;

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MatchModel(
      id: doc.id,
      entityType: MatchEntityType.values.firstWhere(
            (e) => e.toString().split('.').last == data['entityType'],
        orElse: () => MatchEntityType.pet, // Default por compatibilidad
      ),
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      fromPetId: data['fromPetId'],
      toPetId: data['toPetId'],
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
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      additionalInfo: Map<String, dynamic>.from(data['additionalInfo'] ?? {}),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'entityType': entityType.toString().split('.').last,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromPetId': fromPetId,
      'toPetId': toPetId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'message': message,
      'responseMessage': responseMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'additionalInfo': additionalInfo,
      'participants': participants,
    };
  }

  MatchModel copyWith({
    MatchEntityType? entityType,
    String? fromUserId,
    String? toUserId,
    String? fromPetId,
    String? toPetId,
    MatchType? type,
    MatchStatus? status,
    String? message,
    String? responseMessage,
    DateTime? respondedAt,
    DateTime? completedAt,
    Map<String, dynamic>? additionalInfo,
    List<String>? participants,
  }) {
    return MatchModel(
      id: id,
      entityType: entityType ?? this.entityType,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromPetId: fromPetId ?? this.fromPetId,
      toPetId: toPetId ?? this.toPetId,
      type: type ?? this.type,
      status: status ?? this.status,
      message: message ?? this.message,
      responseMessage: responseMessage ?? this.responseMessage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      respondedAt: respondedAt ?? this.respondedAt,
      completedAt: completedAt ?? this.completedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      participants: participants ?? this.participants,
    );
  }

  // Factory methods para crear matches específicos
  factory MatchModel.createPetMatch({
    required String id,
    required String fromUserId,
    required String toUserId,
    required String fromPetId,
    required String toPetId,
    required MatchType type,
    String? message,
  }) {
    return MatchModel(
      id: id,
      entityType: MatchEntityType.pet,
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromPetId: fromPetId,
      toPetId: toPetId,
      type: type,
      status: MatchStatus.pending,
      message: message,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      participants: [fromUserId, toUserId],
    );
  }

  factory MatchModel.createUserMatch({
    required String id,
    required String fromUserId,
    required String toUserId,
    required MatchType type,
    String? message,
    Map<String, dynamic>? additionalInfo,
  }) {
    return MatchModel(
      id: id,
      entityType: MatchEntityType.user,
      fromUserId: fromUserId,
      toUserId: toUserId,
      type: type,
      status: MatchStatus.pending,
      message: message,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      additionalInfo: additionalInfo ?? {},
      participants: [fromUserId, toUserId],
    );
  }
}