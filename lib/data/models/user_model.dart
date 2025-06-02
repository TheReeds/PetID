// lib/data/models/user_model.dart - Agregar estos getters y métodos

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
  final List<String> interests;
  final List<String> petPreferences;
  final AgeRange? ageRange;
  final double? maxDistance;
  final bool isOpenToMeetPetOwners;
  final List<String> hobbies;
  final String? lifestyle;
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

  // NUEVO: Getter para calcular la edad
  int? get age {
    if (dateOfBirth == null) return null;

    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;

    // Ajustar si aún no ha llegado el cumpleaños este año
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }

    return age;
  }

  // NUEVO: Getter para mostrar la edad de forma amigable
  String get displayAge {
    final userAge = age;
    if (userAge == null) return 'Edad no disponible';
    return '$userAge años';
  }

  // NUEVO: Verificar si el usuario está en un rango de edad específico
  bool isInAgeRange(int minAge, int maxAge) {
    final userAge = age;
    if (userAge == null) return false;
    return userAge >= minAge && userAge <= maxAge;
  }

  // NUEVO: Verificar si tiene intereses en común con otro usuario
  bool hasCommonInterests(UserModel otherUser) {
    return interests.any((interest) => otherUser.interests.contains(interest));
  }

  // NUEVO: Calcular puntuación de compatibilidad (0.0 - 1.0)
  double calculateCompatibilityScore(UserModel otherUser) {
    double score = 0.0;
    double factors = 0.0;

    // Intereses en común (peso: 40%)
    if (interests.isNotEmpty && otherUser.interests.isNotEmpty) {
      final commonInterests = interests.where((interest) =>
          otherUser.interests.contains(interest)).length;
      final maxInterests = interests.length > otherUser.interests.length
          ? interests.length
          : otherUser.interests.length;
      score += (commonInterests / maxInterests) * 0.4;
      factors += 0.4;
    }

    // Preferencias de mascotas (peso: 30%)
    if (petPreferences.isNotEmpty && otherUser.petPreferences.isNotEmpty) {
      final commonPetPrefs = petPreferences.where((pref) =>
          otherUser.petPreferences.contains(pref)).length;
      final maxPetPrefs = petPreferences.length > otherUser.petPreferences.length
          ? petPreferences.length
          : otherUser.petPreferences.length;
      score += (commonPetPrefs / maxPetPrefs) * 0.3;
      factors += 0.3;
    }

    // Rango de edad compatible (peso: 20%)
    if (ageRange != null && otherUser.age != null) {
      if (otherUser.age! >= ageRange!.min && otherUser.age! <= ageRange!.max) {
        score += 0.2;
      }
      factors += 0.2;
    }

    // Disponibilidad para conocer dueños de mascotas (peso: 10%)
    if (isOpenToMeetPetOwners && otherUser.isOpenToMeetPetOwners) {
      score += 0.1;
    }
    factors += 0.1;

    // Normalizar el puntaje
    return factors > 0 ? score / factors : 0.0;
  }

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

  // Copiar con modificaciones - ACTUALIZADO para incluir más campos
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
    List<String>? interests,
    List<String>? petPreferences,
    AgeRange? ageRange,
    double? maxDistance,
    bool? isOpenToMeetPetOwners,
    List<String>? hobbies,
    String? lifestyle,
    List<String>? languages,
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
      interests: interests ?? this.interests,
      petPreferences: petPreferences ?? this.petPreferences,
      ageRange: ageRange ?? this.ageRange,
      maxDistance: maxDistance ?? this.maxDistance,
      isOpenToMeetPetOwners: isOpenToMeetPetOwners ?? this.isOpenToMeetPetOwners,
      hobbies: hobbies ?? this.hobbies,
      lifestyle: lifestyle ?? this.lifestyle,
      languages: languages ?? this.languages,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, displayName: $displayName, age: $age)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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

  @override
  String toString() => 'AgeRange(min: $min, max: $max)';

  bool contains(int age) => age >= min && age <= max;
}