import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? fullName;
  final String? photoURL;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? gender;
  final GeoPoint? location;
  final List<String> pets;
  final List<String> followers;
  final List<String> following;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final List<String> interests;           // Intereses del usuario
  final List<String> petPreferences;     // Preferencias de mascotas
  final AgeRange? ageRange;              // Rango de edad preferido
  final double? maxDistance;             // Distancia máxima para matches
  final bool isOpenToMeetPetOwners;      // Disponible para conocer dueños
  final List<String> hobbies;            // Hobbies/actividades
  final String? lifestyle;               // Estilo de vida (activo, relajado, etc.)
  final List<String> languages;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.fullName,
    this.photoURL,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.gender,
    this.location,
    this.pets = const [],
    this.followers = const [],
    this.following = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.interests = const [],
    this.petPreferences = const [],
    this.ageRange,
    this.maxDistance = 50.0,
    this.isOpenToMeetPetOwners = false,
    this.hobbies = const [],
    this.lifestyle,
    this.languages = const [],
  });

  // Convertir desde Firebase DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      fullName: data['fullName'],
      photoURL: data['photoURL'],
      phone: data['phone'],
      address: data['address'],
      dateOfBirth: data['dateOfBirth'] != null ? (data['dateOfBirth'] as Timestamp).toDate() : null,
      gender: data['gender'],
      location: data['location'],
      pets: List<String>.from(data['pets'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      interests: List<String>.from(data['interests'] ?? []),
      petPreferences: List<String>.from(data['petPreferences'] ?? []),
      ageRange: data['ageRange'] != null ? AgeRange.fromMap(data['ageRange']) : null,
      maxDistance: (data['maxDistance'] ?? 50.0).toDouble(),
      isOpenToMeetPetOwners: data['isOpenToMeetPetOwners'] ?? false,
      hobbies: List<String>.from(data['hobbies'] ?? []),
      lifestyle: data['lifestyle'],
      languages: List<String>.from(data['languages'] ?? []),
    );
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'fullName': fullName,
      'photoURL': photoURL,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'location': location,
      'pets': pets,
      'followers': followers,
      'following': following,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'interests': interests,
      'petPreferences': petPreferences,
      'ageRange': ageRange?.toMap(),
      'maxDistance': maxDistance,
      'isOpenToMeetPetOwners': isOpenToMeetPetOwners,
      'hobbies': hobbies,
      'lifestyle': lifestyle,
      'languages': languages,
    };
  }

  // Copiar con modificaciones
  UserModel copyWith({
    String? displayName,
    String? fullName,
    String? photoURL,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    GeoPoint? location,
    List<String>? pets,
    List<String>? followers,
    List<String>? following,
    bool? isVerified,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      fullName: fullName ?? this.fullName,
      photoURL: photoURL ?? this.photoURL,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      pets: pets ?? this.pets,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
class AgeRange {
  final int min;
  final int max;

  AgeRange({required this.min, required this.max});

  factory AgeRange.fromMap(Map<String, dynamic> map) {
    return AgeRange(
      min: map['min'] ?? 18,
      max: map['max'] ?? 99,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'min': min,
      'max': max,
    };
  }
}