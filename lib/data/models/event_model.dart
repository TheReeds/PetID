import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { meetup, training, veterinary, adoption, contest, social, other }
enum EventStatus { upcoming, ongoing, completed, cancelled }

class EventModel {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final EventStatus status;
  final String creatorId;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final List<String> imageUrls;
  final LocationData location;
  final int maxParticipants;
  final List<String> participants;
  final List<String> waitingList;
  final bool isPetFriendly;
  final List<String> allowedPetTypes;
  final double? price;
  final String? priceDescription;
  final bool isPrivate;
  final String? requirements;
  final List<String> tags;
  final String? contactInfo;
  final String? externalLink;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = EventStatus.upcoming,
    required this.creatorId,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    this.imageUrls = const [],
    required this.location,
    this.maxParticipants = 0, // 0 = sin límite
    this.participants = const [],
    this.waitingList = const [],
    this.isPetFriendly = true,
    this.allowedPetTypes = const [],
    this.price,
    this.priceDescription,
    this.isPrivate = false,
    this.requirements,
    this.tags = const [],
    this.contactInfo,
    this.externalLink,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  // Propiedades calculadas
  bool get isFullyBooked => maxParticipants > 0 && participants.length >= maxParticipants;
  bool get hasWaitingList => waitingList.isNotEmpty;
  bool get isFree => price == null || price == 0;
  bool get hasStarted => DateTime.now().isAfter(startDate);
  bool get hasEnded => DateTime.now().isAfter(endDate);
  bool get isActive => status == EventStatus.ongoing ||
      (status == EventStatus.upcoming && hasStarted && !hasEnded);

  int get availableSpots => maxParticipants > 0 ? maxParticipants - participants.length : -1;

  String get displayPrice {
    if (isFree) return 'Gratis';
    if (price != null) return '\$${price!.toStringAsFixed(0)}';
    return priceDescription ?? 'Precio a consultar';
  }

  String get displayLocation {
    if (location.address != null) return location.address!;
    return '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  Duration get duration => endDate.difference(startDate);

  String get displayDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  bool isUserParticipating(String userId) => participants.contains(userId);
  bool isUserInWaitingList(String userId) => waitingList.contains(userId);
  bool isUserCreator(String userId) => creatorId == userId;

  // Convertir desde Firestore
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: EventType.values.firstWhere(
            (e) => e.toString().split('.').last == data['type'],
        orElse: () => EventType.other,
      ),
      status: EventStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => EventStatus.upcoming,
      ),
      creatorId: data['creatorId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: LocationData.fromMap(data['location']),
      maxParticipants: data['maxParticipants'] ?? 0,
      participants: List<String>.from(data['participants'] ?? []),
      waitingList: List<String>.from(data['waitingList'] ?? []),
      isPetFriendly: data['isPetFriendly'] ?? true,
      allowedPetTypes: List<String>.from(data['allowedPetTypes'] ?? []),
      price: data['price']?.toDouble(),
      priceDescription: data['priceDescription'],
      isPrivate: data['isPrivate'] ?? false,
      requirements: data['requirements'],
      tags: List<String>.from(data['tags'] ?? []),
      contactInfo: data['contactInfo'],
      externalLink: data['externalLink'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'creatorId': creatorId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'location': location.toMap(),
      'maxParticipants': maxParticipants,
      'participants': participants,
      'waitingList': waitingList,
      'isPetFriendly': isPetFriendly,
      'allowedPetTypes': allowedPetTypes,
      'price': price,
      'priceDescription': priceDescription,
      'isPrivate': isPrivate,
      'requirements': requirements,
      'tags': tags,
      'contactInfo': contactInfo,
      'externalLink': externalLink,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  // Crear copia con cambios
  EventModel copyWith({
    String? title,
    String? description,
    EventType? type,
    EventStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    List<String>? imageUrls,
    LocationData? location,
    int? maxParticipants,
    List<String>? participants,
    List<String>? waitingList,
    bool? isPetFriendly,
    List<String>? allowedPetTypes,
    double? price,
    String? priceDescription,
    bool? isPrivate,
    String? requirements,
    List<String>? tags,
    String? contactInfo,
    String? externalLink,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      creatorId: creatorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      waitingList: waitingList ?? this.waitingList,
      isPetFriendly: isPetFriendly ?? this.isPetFriendly,
      allowedPetTypes: allowedPetTypes ?? this.allowedPetTypes,
      price: price ?? this.price,
      priceDescription: priceDescription ?? this.priceDescription,
      isPrivate: isPrivate ?? this.isPrivate,
      requirements: requirements ?? this.requirements,
      tags: tags ?? this.tags,
      contactInfo: contactInfo ?? this.contactInfo,
      externalLink: externalLink ?? this.externalLink,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, type: $type, startDate: $startDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Clase para datos de ubicación
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? placeName;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.placeName,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
      postalCode: map['postalCode'],
      placeName: map['placeName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'placeName': placeName,
    };
  }

  @override
  String toString() {
    return address ?? placeName ?? '$latitude, $longitude';
  }
}