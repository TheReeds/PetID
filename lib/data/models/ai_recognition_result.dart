import '../models/pet_model.dart';

// Resultado del reconocimiento de raza
class BreedRecognitionResult {
  final String breed;
  final double confidence;
  final String? source;
  final String? error;
  final Map<String, dynamic>? additionalInfo;

  BreedRecognitionResult({
    required this.breed,
    required this.confidence,
    this.source,
    this.error,
    this.additionalInfo,
  });

  bool get isValid => error == null && confidence > 0.0;

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';

  String get confidenceLevel {
    if (confidence >= 0.8) return 'Muy Alta';
    if (confidence >= 0.6) return 'Alta';
    if (confidence >= 0.4) return 'Media';
    if (confidence >= 0.2) return 'Baja';
    return 'Muy Baja';
  }

  @override
  String toString() => 'BreedRecognitionResult(breed: $breed, confidence: $confidence)';
}

// Resultado de mascota similar encontrada
class SimilarPetResult {
  final PetModel pet;
  final double similarity;
  final String matchType;
  final List<String>? matchingFeatures;

  SimilarPetResult({
    required this.pet,
    required this.similarity,
    required this.matchType,
    this.matchingFeatures,
  });

  String get similarityPercentage => '${(similarity * 100).toStringAsFixed(1)}%';

  bool get isHighMatch => similarity >= 0.8;
  bool get isMediumMatch => similarity >= 0.6 && similarity < 0.8;
  bool get isLowMatch => similarity >= 0.3 && similarity < 0.6;

  @override
  String toString() => 'SimilarPetResult(pet: ${pet.name}, similarity: $similarity)';
}

// Resultado completo del análisis de imagen
class PetAnalysisResult {
  final BreedRecognitionResult breed;
  final Map<String, dynamic> characteristics;
  final List<SimilarPetResult> similarPets;
  final String detectedType;
  final String estimatedAge;
  final String estimatedSize;
  final String? error;

  PetAnalysisResult({
    required this.breed,
    required this.characteristics,
    required this.similarPets,
    required this.detectedType,
    required this.estimatedAge,
    required this.estimatedSize,
    this.error,
  });

  factory PetAnalysisResult.error(String errorMessage) {
    return PetAnalysisResult(
      breed: BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0),
      characteristics: {},
      similarPets: [],
      detectedType: 'Desconocido',
      estimatedAge: 'Desconocido',
      estimatedSize: 'Desconocido',
      error: errorMessage,
    );
  }

  bool get isValid => error == null;
  bool get hasBreedInfo => breed.isValid;
  bool get hasSimilarPets => similarPets.isNotEmpty;

  String get summary {
    if (!isValid) return 'Error en el análisis';

    List<String> parts = [];

    if (hasBreedInfo) {
      parts.add('Raza: ${breed.breed} (${breed.confidencePercentage})');
    }

    if (detectedType != 'Desconocido') {
      parts.add('Tipo: $detectedType');
    }

    if (estimatedAge != 'Desconocido') {
      parts.add('Edad: $estimatedAge');
    }

    if (estimatedSize != 'Desconocido') {
      parts.add('Tamaño: $estimatedSize');
    }

    if (hasSimilarPets) {
      parts.add('${similarPets.length} mascotas similares encontradas');
    }

    return parts.join(' • ');
  }

  @override
  String toString() => 'PetAnalysisResult(breed: ${breed.breed}, type: $detectedType)';
}

// Configuración de análisis de IA - CORREGIDO
class AIAnalysisConfig {
  final bool useGoogleVision;
  final bool useRoboflow;
  final bool useClarifai;
  final double similarityThreshold;
  final int maxSimilarPets;
  final bool includeCharacteristics;

  const AIAnalysisConfig({
    this.useGoogleVision = true,
    this.useRoboflow = true,
    this.useClarifai = true,
    this.similarityThreshold = 0.3,
    this.maxSimilarPets = 5,
    this.includeCharacteristics = true,
  });

  // Configuración estándar
  static const AIAnalysisConfig standard = AIAnalysisConfig();

  // Configuración rápida - CORREGIDO: usar parámetros nombrados
  static const AIAnalysisConfig fast = AIAnalysisConfig(
    useRoboflow: false,
    useClarifai: false,
    maxSimilarPets: 3,
    includeCharacteristics: false,
  );

  // Configuración comprehensiva - CORREGIDO: usar parámetros nombrados
  static const AIAnalysisConfig comprehensive = AIAnalysisConfig(
    similarityThreshold: 0.2,
    maxSimilarPets: 10,
  );
}

// Historial de análisis de IA
class AIAnalysisHistory {
  final String id;
  final DateTime timestamp;
  final String imageUrl;
  final PetAnalysisResult result;
  final String userId;
  final String? petId; // Si se asoció con una mascota específica

  AIAnalysisHistory({
    required this.id,
    required this.timestamp,
    required this.imageUrl,
    required this.result,
    required this.userId,
    this.petId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'result': {
        'breed': {
          'name': result.breed.breed,
          'confidence': result.breed.confidence,
          'source': result.breed.source,
        },
        'characteristics': result.characteristics,
        'detectedType': result.detectedType,
        'estimatedAge': result.estimatedAge,
        'estimatedSize': result.estimatedSize,
        'similarPetsCount': result.similarPets.length,
      },
      'userId': userId,
      'petId': petId,
    };
  }

  factory AIAnalysisHistory.fromMap(Map<String, dynamic> map) {
    final resultMap = map['result'] as Map<String, dynamic>;
    final breedMap = resultMap['breed'] as Map<String, dynamic>;

    return AIAnalysisHistory(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      imageUrl: map['imageUrl'],
      result: PetAnalysisResult(
        breed: BreedRecognitionResult(
          breed: breedMap['name'],
          confidence: breedMap['confidence'],
          source: breedMap['source'],
        ),
        characteristics: Map<String, dynamic>.from(resultMap['characteristics']),
        similarPets: [], // No cargamos las mascotas similares del historial
        detectedType: resultMap['detectedType'],
        estimatedAge: resultMap['estimatedAge'],
        estimatedSize: resultMap['estimatedSize'],
      ),
      userId: map['userId'],
      petId: map['petId'],
    );
  }
}