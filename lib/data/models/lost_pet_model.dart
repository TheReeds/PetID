import 'package:cloud_firestore/cloud_firestore.dart';

enum LostPetStatus { active, found, closed }

class LostPetModel {
  final String id;
  final String petId;
  final String reporterId;
  final String petName;
  final String description;
  final List<String> photos;
  final GeoPoint lastSeenLocation;
  final String lastSeenLocationName;
  final DateTime lastSeenDate;
  final String contactPhone;
  final String contactEmail;
  final String? reward;
  final LostPetStatus status;
  final List<String> helpfulUsers; // Usuarios que ayudaron
  final DateTime createdAt;
  final DateTime updatedAt;

  LostPetModel({
    required this.id,
    required this.petId,
    required this.reporterId,
    required this.petName,
    required this.description,
    this.photos = const [],
    required this.lastSeenLocation,
    required this.lastSeenLocationName,
    required this.lastSeenDate,
    required this.contactPhone,
    required this.contactEmail,
    this.reward,
    this.status = LostPetStatus.active,
    this.helpfulUsers = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory LostPetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return LostPetModel(
      id: doc.id,
      petId: data['petId'] ?? '',
      reporterId: data['reporterId'] ?? '',
      petName: data['petName'] ?? '',
      description: data['description'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      lastSeenLocation: data['lastSeenLocation'] ?? const GeoPoint(0, 0),
      lastSeenLocationName: data['lastSeenLocationName'] ?? '',
      lastSeenDate: (data['lastSeenDate'] as Timestamp).toDate(),
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      reward: data['reward'],
      status: LostPetStatus.values.firstWhere(
            (e) => e.toString() == 'LostPetStatus.${data['status']}',
        orElse: () => LostPetStatus.active,
      ),
      helpfulUsers: List<String>.from(data['helpfulUsers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'petId': petId,
      'reporterId': reporterId,
      'petName': petName,
      'description': description,
      'photos': photos,
      'lastSeenLocation': lastSeenLocation,
      'lastSeenLocationName': lastSeenLocationName,
      'lastSeenDate': Timestamp.fromDate(lastSeenDate),
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'reward': reward,
      'status': status.toString().split('.').last,
      'helpfulUsers': helpfulUsers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get statusText {
    switch (status) {
      case LostPetStatus.active:
        return 'Perdido';
      case LostPetStatus.found:
        return 'Encontrado';
      case LostPetStatus.closed:
        return 'Cerrado';
    }
  }

  bool get isActive => status == LostPetStatus.active;

  LostPetModel copyWith({
    String? description,
    List<String>? photos,
    String? contactPhone,
    String? contactEmail,
    String? reward,
    LostPetStatus? status,
    List<String>? helpfulUsers,
  }) {
    return LostPetModel(
      id: id,
      petId: petId,
      reporterId: reporterId,
      petName: petName,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      lastSeenLocation: lastSeenLocation,
      lastSeenLocationName: lastSeenLocationName,
      lastSeenDate: lastSeenDate,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      reward: reward ?? this.reward,
      status: status ?? this.status,
      helpfulUsers: helpfulUsers ?? this.helpfulUsers,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}