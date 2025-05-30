import 'package:cloud_firestore/cloud_firestore.dart';

enum PetType { dog, cat, bird, rabbit, fish, other }
enum PetGender { male, female, unknown }
enum PetSize { small, medium, large }

class PetModel {
  final String id;
  final String name;
  final String ownerId;
  final PetType type;
  final String breed;
  final PetGender gender;
  final PetSize size;
  final int ageMonths;
  final String color;
  final String description;
  final List<String> photos;
  final String? profilePhoto;
  final String qrCode;
  final Map<String, dynamic> aiFeatures; // Características IA
  final bool isLost;
  final bool isForAdoption;
  final bool isForMating;
  final Map<String, dynamic> healthInfo;
  final List<String> vaccinations;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.type,
    required this.breed,
    required this.gender,
    required this.size,
    required this.ageMonths,
    required this.color,
    this.description = '',
    this.photos = const [],
    this.profilePhoto,
    required this.qrCode,
    this.aiFeatures = const {},
    this.isLost = false,
    this.isForAdoption = false,
    this.isForMating = false,
    this.healthInfo = const {},
    this.vaccinations = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PetModel(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      type: PetType.values.firstWhere(
            (e) => e.toString() == 'PetType.${data['type']}',
        orElse: () => PetType.other,
      ),
      breed: data['breed'] ?? '',
      gender: PetGender.values.firstWhere(
            (e) => e.toString() == 'PetGender.${data['gender']}',
        orElse: () => PetGender.unknown,
      ),
      size: PetSize.values.firstWhere(
            (e) => e.toString() == 'PetSize.${data['size']}',
        orElse: () => PetSize.medium,
      ),
      ageMonths: data['ageMonths'] ?? 0,
      color: data['color'] ?? '',
      description: data['description'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      profilePhoto: data['profilePhoto'],
      qrCode: data['qrCode'] ?? '',
      aiFeatures: Map<String, dynamic>.from(data['aiFeatures'] ?? {}),
      isLost: data['isLost'] ?? false,
      isForAdoption: data['isForAdoption'] ?? false,
      isForMating: data['isForMating'] ?? false,
      healthInfo: Map<String, dynamic>.from(data['healthInfo'] ?? {}),
      vaccinations: List<String>.from(data['vaccinations'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'type': type.toString().split('.').last,
      'breed': breed,
      'gender': gender.toString().split('.').last,
      'size': size.toString().split('.').last,
      'ageMonths': ageMonths,
      'color': color,
      'description': description,
      'photos': photos,
      'profilePhoto': profilePhoto,
      'qrCode': qrCode,
      'aiFeatures': aiFeatures,
      'isLost': isLost,
      'isForAdoption': isForAdoption,
      'isForMating': isForMating,
      'healthInfo': healthInfo,
      'vaccinations': vaccinations,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get ageText {
    if (ageMonths < 12) {
      return '$ageMonths meses';
    } else {
      int years = ageMonths ~/ 12;
      int months = ageMonths % 12;
      if (months == 0) {
        return '$years años';
      } else {
        return '$years años, $months meses';
      }
    }
  }

  PetModel copyWith({
    String? name,
    String? breed,
    PetGender? gender,
    PetSize? size,
    int? ageMonths,
    String? color,
    String? description,
    List<String>? photos,
    String? profilePhoto,
    Map<String, dynamic>? aiFeatures,
    bool? isLost,
    bool? isForAdoption,
    bool? isForMating,
    Map<String, dynamic>? healthInfo,
    List<String>? vaccinations,
  }) {
    return PetModel(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      type: type,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      size: size ?? this.size,
      ageMonths: ageMonths ?? this.ageMonths,
      color: color ?? this.color,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      qrCode: qrCode,
      aiFeatures: aiFeatures ?? this.aiFeatures,
      isLost: isLost ?? this.isLost,
      isForAdoption: isForAdoption ?? this.isForAdoption,
      isForMating: isForMating ?? this.isForMating,
      healthInfo: healthInfo ?? this.healthInfo,
      vaccinations: vaccinations ?? this.vaccinations,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}