import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phone;
  final String? address;
  final GeoPoint? location;
  final List<String> pets;
  final List<String> followers;
  final List<String> following;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phone,
    this.address,
    this.location,
    this.pets = const [],
    this.followers = const [],
    this.following = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
  });

  // Convertir desde Firebase DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      phone: data['phone'],
      address: data['address'],
      location: data['location'],
      pets: List<String>.from(data['pets'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  // Convertir a Map para Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phone': phone,
      'address': address,
      'location': location,
      'pets': pets,
      'followers': followers,
      'following': following,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
    };
  }

  // Copiar con modificaciones
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? phone,
    String? address,
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
      photoURL: photoURL ?? this.photoURL,
      phone: phone ?? this.phone,
      address: address ?? this.address,
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