// lib/data/models/pet_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PetType { dog, cat, bird, rabbit, hamster, fish, reptile, other }
enum PetSize { small, medium, large }
enum PetSex { male, female }

class PetModel {
  final String id;
  final String name;
  final PetType type;
  final String breed;
  final PetSex sex;
  final DateTime birthDate;
  final PetSize size;
  final double weight;
  final String ownerId;
  final String? profilePhoto;
  final List<String> photos;
  final String description;
  final bool isLost;
  final bool isForAdoption;
  final bool isForMating;
  final String? qrCode;
  final HealthInfo? healthInfo;
  final LocationInfo? lastKnownLocation;
  final List<String> tags;
  final Map<String, dynamic> characteristics;
  final bool isNeutered;
  final bool isVaccinated;
  final bool isMicrochipped;
  final String? microchipId;
  final ContactInfo? emergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;
  GeoPoint? get location => lastKnownLocation != null
      ? GeoPoint(lastKnownLocation!.latitude, lastKnownLocation!.longitude)
      : null;

  PetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.sex,
    required this.birthDate,
    required this.size,
    required this.weight,
    required this.ownerId,
    this.profilePhoto,
    this.photos = const [],
    this.description = '',
    this.isLost = false,
    this.isForAdoption = false,
    this.isForMating = false,
    this.qrCode,
    this.healthInfo,
    this.lastKnownLocation,
    this.tags = const [],
    this.characteristics = const {},
    this.isNeutered = false,
    this.isVaccinated = false,
    this.isMicrochipped = false,
    this.microchipId,
    this.emergencyContact,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculated properties
  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  }

  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String get displayAge {
    final years = ageInYears;
    final months = ageInMonths % 12;

    if (years == 0) {
      return months == 1 ? '1 mes' : '$months meses';
    } else if (months == 0) {
      return years == 1 ? '1 año' : '$years años';
    } else {
      return years == 1 ? '1 año $months meses' : '$years años $months meses';
    }
  }

  bool get isAdult {
    switch (type) {
      case PetType.dog:
        return ageInMonths >= 12;
      case PetType.cat:
        return ageInMonths >= 12;
      case PetType.rabbit:
        return ageInMonths >= 6;
      case PetType.hamster:
        return ageInMonths >= 3;
      case PetType.bird:
        return ageInMonths >= 12;
      case PetType.fish:
        return ageInMonths >= 6;
      case PetType.reptile:
        return ageInMonths >= 18;
      case PetType.other:
        return ageInMonths >= 12;
    }
  }

  // Convertir desde Firestore
  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PetModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: PetType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
        orElse: () => PetType.other,
      ),
      breed: data['breed'] ?? '',
      sex: PetSex.values.firstWhere(
            (e) => e.toString().split('.').last == data['sex'],
        orElse: () => PetSex.male,
      ),
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      size: PetSize.values.firstWhere(
            (e) => e.toString().split('.').last == data['size'],
        orElse: () => PetSize.medium,
      ),
      weight: (data['weight'] ?? 0.0).toDouble(),
      ownerId: data['ownerId'] ?? '',
      profilePhoto: data['profilePhoto'],
      photos: List<String>.from(data['photos'] ?? []),
      description: data['description'] ?? '',
      isLost: data['isLost'] ?? false,
      isForAdoption: data['isForAdoption'] ?? false,
      isForMating: data['isForMating'] ?? false,
      qrCode: data['qrCode'],
      healthInfo: data['healthInfo'] != null
          ? HealthInfo.fromMap(data['healthInfo'])
          : null,
      lastKnownLocation: data['lastKnownLocation'] != null
          ? LocationInfo.fromMap(data['lastKnownLocation'])
          : null,
      tags: List<String>.from(data['tags'] ?? []),
      characteristics: Map<String, dynamic>.from(data['characteristics'] ?? {}),
      isNeutered: data['isNeutered'] ?? false,
      isVaccinated: data['isVaccinated'] ?? false,
      isMicrochipped: data['isMicrochipped'] ?? false,
      microchipId: data['microchipId'],
      emergencyContact: data['emergencyContact'] != null
          ? ContactInfo.fromMap(data['emergencyContact'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'breed': breed,
      'sex': sex.toString().split('.').last,
      'birthDate': Timestamp.fromDate(birthDate),
      'size': size.toString().split('.').last,
      'weight': weight,
      'ownerId': ownerId,
      'profilePhoto': profilePhoto,
      'photos': photos,
      'description': description,
      'isLost': isLost,
      'isForAdoption': isForAdoption,
      'isForMating': isForMating,
      'qrCode': qrCode,
      'healthInfo': healthInfo?.toMap(),
      'lastKnownLocation': lastKnownLocation?.toMap(),
      'tags': tags,
      'characteristics': characteristics,
      'isNeutered': isNeutered,
      'isVaccinated': isVaccinated,
      'isMicrochipped': isMicrochipped,
      'microchipId': microchipId,
      'emergencyContact': emergencyContact?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Crear copia con cambios
  PetModel copyWith({
    String? id,
    String? name,
    PetType? type,
    String? breed,
    PetSex? sex,
    DateTime? birthDate,
    PetSize? size,
    double? weight,
    String? ownerId,
    String? profilePhoto,
    List<String>? photos,
    String? description,
    bool? isLost,
    bool? isForAdoption,
    bool? isForMating,
    String? qrCode,
    HealthInfo? healthInfo,
    LocationInfo? lastKnownLocation,
    List<String>? tags,
    Map<String, dynamic>? characteristics,
    bool? isNeutered,
    bool? isVaccinated,
    bool? isMicrochipped,
    String? microchipId,
    ContactInfo? emergencyContact,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      size: size ?? this.size,
      weight: weight ?? this.weight,
      ownerId: ownerId ?? this.ownerId,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      photos: photos ?? this.photos,
      description: description ?? this.description,
      isLost: isLost ?? this.isLost,
      isForAdoption: isForAdoption ?? this.isForAdoption,
      isForMating: isForMating ?? this.isForMating,
      qrCode: qrCode ?? this.qrCode,
      healthInfo: healthInfo ?? this.healthInfo,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      tags: tags ?? this.tags,
      characteristics: characteristics ?? this.characteristics,
      isNeutered: isNeutered ?? this.isNeutered,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      isMicrochipped: isMicrochipped ?? this.isMicrochipped,
      microchipId: microchipId ?? this.microchipId,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Métodos útiles
  bool hasVaccination(String vaccineName) {
    return healthInfo?.vaccinations.any((v) => v.name == vaccineName) ?? false;
  }

  bool needsVaccination(String vaccineName) {
    if (!hasVaccination(vaccineName)) return true;

    final vaccination = healthInfo?.vaccinations
        .where((v) => v.name == vaccineName)
        .lastOrNull;

    if (vaccination?.nextDue != null) {
      return DateTime.now().isAfter(vaccination!.nextDue!);
    }

    return false;
  }

  @override
  String toString() {
    return 'PetModel(id: $id, name: $name, type: $type, breed: $breed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Clases de apoyo
class HealthInfo {
  final List<Vaccination> vaccinations;
  final List<String> allergies;
  final List<String> medications;
  final List<MedicalRecord> medicalHistory;
  final String? veterinarian;
  final String? veterinarianPhone;
  final DateTime? lastCheckup;
  final DateTime? nextCheckup;
  final String generalHealth;
  final double? temperature;
  final String? bloodType;
  final Map<String, dynamic> vitals;

  HealthInfo({
    this.vaccinations = const [],
    this.allergies = const [],
    this.medications = const [],
    this.medicalHistory = const [],
    this.veterinarian,
    this.veterinarianPhone,
    this.lastCheckup,
    this.nextCheckup,
    this.generalHealth = 'Buena',
    this.temperature,
    this.bloodType,
    this.vitals = const {},
  });

  factory HealthInfo.fromMap(Map<String, dynamic> map) {
    return HealthInfo(
      vaccinations: (map['vaccinations'] as List<dynamic>?)
          ?.map((v) => Vaccination.fromMap(v))
          .toList() ?? [],
      allergies: List<String>.from(map['allergies'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      medicalHistory: (map['medicalHistory'] as List<dynamic>?)
          ?.map((m) => MedicalRecord.fromMap(m))
          .toList() ?? [],
      veterinarian: map['veterinarian'],
      veterinarianPhone: map['veterinarianPhone'],
      lastCheckup: map['lastCheckup'] != null
          ? (map['lastCheckup'] as Timestamp).toDate()
          : null,
      nextCheckup: map['nextCheckup'] != null
          ? (map['nextCheckup'] as Timestamp).toDate()
          : null,
      generalHealth: map['generalHealth'] ?? 'Buena',
      temperature: map['temperature']?.toDouble(),
      bloodType: map['bloodType'],
      vitals: Map<String, dynamic>.from(map['vitals'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vaccinations': vaccinations.map((v) => v.toMap()).toList(),
      'allergies': allergies,
      'medications': medications,
      'medicalHistory': medicalHistory.map((m) => m.toMap()).toList(),
      'veterinarian': veterinarian,
      'veterinarianPhone': veterinarianPhone,
      'lastCheckup': lastCheckup != null
          ? Timestamp.fromDate(lastCheckup!)
          : null,
      'nextCheckup': nextCheckup != null
          ? Timestamp.fromDate(nextCheckup!)
          : null,
      'generalHealth': generalHealth,
      'temperature': temperature,
      'bloodType': bloodType,
      'vitals': vitals,
    };
  }
}

class Vaccination {
  final String name;
  final DateTime date;
  final DateTime? nextDue;
  final String? veterinarian;
  final String? batchNumber;
  final String? manufacturer;

  Vaccination({
    required this.name,
    required this.date,
    this.nextDue,
    this.veterinarian,
    this.batchNumber,
    this.manufacturer,
  });

  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      name: map['name'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      nextDue: map['nextDue'] != null
          ? (map['nextDue'] as Timestamp).toDate()
          : null,
      veterinarian: map['veterinarian'],
      batchNumber: map['batchNumber'],
      manufacturer: map['manufacturer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'nextDue': nextDue != null ? Timestamp.fromDate(nextDue!) : null,
      'veterinarian': veterinarian,
      'batchNumber': batchNumber,
      'manufacturer': manufacturer,
    };
  }
}

class MedicalRecord {
  final String id;
  final DateTime date;
  final String type;
  final String description;
  final String? veterinarian;
  final List<String> attachments;
  final Map<String, dynamic> details;

  MedicalRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    this.veterinarian,
    this.attachments = const [],
    this.details = const {},
  });

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      veterinarian: map['veterinarian'],
      attachments: List<String>.from(map['attachments'] ?? []),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'type': type,
      'description': description,
      'veterinarian': veterinarian,
      'attachments': attachments,
      'details': details,
    };
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;
  final double? accuracy;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
    this.accuracy,
  });

  factory LocationInfo.fromMap(Map<String, dynamic> map) {
    return LocationInfo(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      accuracy: map['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': Timestamp.fromDate(timestamp),
      'accuracy': accuracy,
    };
  }
}

class ContactInfo {
  final String name;
  final String phone;
  final String? email;
  final String? relationship;

  ContactInfo({
    required this.name,
    required this.phone,
    this.email,
    this.relationship,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      relationship: map['relationship'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
    };
  }
}

// Extensión para obtener el último elemento de una lista
extension ListExtension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}