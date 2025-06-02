// lib/data/models/ai_recognition_result.dart (Enhanced)
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

// NUEVO: Resultado detallado de múltiples modelos
class MultiModelBreedResult {
  final BreedRecognitionResult? googleVisionResult;
  final BreedRecognitionResult? roboflowResult;
  final BreedRecognitionResult? clarifaiResult;
  final BreedRecognitionResult bestResult;
  final DateTime analysisTime;
  final Duration processingDuration;

  MultiModelBreedResult({
    this.googleVisionResult,
    this.roboflowResult,
    this.clarifaiResult,
    required this.bestResult,
    required this.analysisTime,
    required this.processingDuration,
  });

  // Obtener todos los resultados válidos ordenados por confianza
  List<BreedRecognitionResult> get allValidResults {
    final results = <BreedRecognitionResult>[];

    if (googleVisionResult?.isValid == true) results.add(googleVisionResult!);
    if (roboflowResult?.isValid == true) results.add(roboflowResult!);
    if (clarifaiResult?.isValid == true) results.add(clarifaiResult!);

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  // Verificar si hay consenso entre los modelos
  bool get hasConsensus {
    final validResults = allValidResults;
    if (validResults.length < 2) return false;

    final topBreed = validResults.first.breed.toLowerCase();
    return validResults.any((result) =>
    result.breed.toLowerCase().contains(topBreed.split(' ').first) ||
        topBreed.contains(result.breed.toLowerCase().split(' ').first)
    );
  }

  // Nivel de consenso
  String get consensusLevel {
    final validResults = allValidResults;
    if (validResults.length < 2) return 'Insuficiente';

    if (hasConsensus) {
      if (validResults.length == 3) return 'Alto';
      return 'Medio';
    }
    return 'Bajo';
  }

  // Número de modelos que dieron resultado
  int get modelCount => allValidResults.length;

  @override
  String toString() => 'MultiModelBreedResult(best: ${bestResult.breed}, models: $modelCount)';
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

// Resultado completo del análisis de imagen - MEJORADO
class PetAnalysisResult {
  final MultiModelBreedResult breedAnalysis; // CAMBIADO: ahora es MultiModelBreedResult
  final Map<String, dynamic> characteristics;
  final List<SimilarPetResult> similarPets;
  final String detectedType;
  final String estimatedAge;
  final String estimatedSize;
  final String? error;
  final DateTime analysisTime;
  late final Duration totalProcessingTime;

  PetAnalysisResult({
    required this.breedAnalysis,
    required this.characteristics,
    required this.similarPets,
    required this.detectedType,
    required this.estimatedAge,
    required this.estimatedSize,
    this.error,
    required this.analysisTime,
    required this.totalProcessingTime,
  });

  factory PetAnalysisResult.error(String errorMessage) {
    return PetAnalysisResult(
      breedAnalysis: MultiModelBreedResult(
        bestResult: BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0),
        analysisTime: DateTime.now(),
        processingDuration: Duration.zero,
      ),
      characteristics: {},
      similarPets: [],
      detectedType: 'Desconocido',
      estimatedAge: 'Desconocido',
      estimatedSize: 'Desconocido',
      error: errorMessage,
      analysisTime: DateTime.now(),
      totalProcessingTime: Duration.zero,
    );
  }

  bool get isValid => error == null;
  bool get hasBreedInfo => breedAnalysis.bestResult.isValid;
  bool get hasSimilarPets => similarPets.isNotEmpty;

  // ACTUALIZADO: usar el mejor resultado del análisis multimodelo
  BreedRecognitionResult get breed => breedAnalysis.bestResult;

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

    // Agregar información de consenso
    if (breedAnalysis.modelCount > 1) {
      parts.add('Consenso: ${breedAnalysis.consensusLevel}');
    }

    return parts.join(' • ');
  }

  @override
  String toString() => 'PetAnalysisResult(breed: ${breed.breed}, type: $detectedType, models: ${breedAnalysis.modelCount})';
}

// Configuración de análisis de IA
class AIAnalysisConfig {
  final bool useGoogleVision;
  final bool useRoboflow;
  final bool useClarifai;
  final double similarityThreshold;
  final int maxSimilarPets;
  final bool includeCharacteristics;
  final bool showAllModelResults; // NUEVO: para mostrar todos los resultados

  const AIAnalysisConfig({
    this.useGoogleVision = true,
    this.useRoboflow = true,
    this.useClarifai = true,
    this.similarityThreshold = 0.3,
    this.maxSimilarPets = 5,
    this.includeCharacteristics = true,
    this.showAllModelResults = true,
  });

  static const AIAnalysisConfig standard = AIAnalysisConfig();

  static const AIAnalysisConfig fast = AIAnalysisConfig(
    useRoboflow: false,
    useClarifai: false,
    maxSimilarPets: 3,
    includeCharacteristics: false,
    showAllModelResults: false,
  );

  static const AIAnalysisConfig comprehensive = AIAnalysisConfig(
    similarityThreshold: 0.2,
    maxSimilarPets: 10,
    showAllModelResults: true,
  );
}

// Historial de análisis de IA
class AIAnalysisHistory {
  final String id;
  final DateTime timestamp;
  final String imageUrl;
  final PetAnalysisResult result;
  final String userId;
  final String? petId;

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
        'breedAnalysis': {
          'bestResult': {
            'name': result.breedAnalysis.bestResult.breed,
            'confidence': result.breedAnalysis.bestResult.confidence,
            'source': result.breedAnalysis.bestResult.source,
          },
          'modelCount': result.breedAnalysis.modelCount,
          'consensusLevel': result.breedAnalysis.consensusLevel,
          'allResults': result.breedAnalysis.allValidResults.map((r) => {
            'name': r.breed,
            'confidence': r.confidence,
            'source': r.source,
          }).toList(),
        },
        'characteristics': result.characteristics,
        'detectedType': result.detectedType,
        'estimatedAge': result.estimatedAge,
        'estimatedSize': result.estimatedSize,
        'similarPetsCount': result.similarPets.length,
        'processingTime': result.totalProcessingTime.inMilliseconds,
      },
      'userId': userId,
      'petId': petId,
    };
  }

  factory AIAnalysisHistory.fromMap(Map<String, dynamic> map) {
    final resultMap = map['result'] as Map<String, dynamic>;
    final breedAnalysisMap = resultMap['breedAnalysis'] as Map<String, dynamic>;
    final bestResultMap = breedAnalysisMap['bestResult'] as Map<String, dynamic>;

    return AIAnalysisHistory(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      imageUrl: map['imageUrl'],
      result: PetAnalysisResult(
        breedAnalysis: MultiModelBreedResult(
          bestResult: BreedRecognitionResult(
            breed: bestResultMap['name'],
            confidence: bestResultMap['confidence'],
            source: bestResultMap['source'],
          ),
          analysisTime: DateTime.parse(map['timestamp']),
          processingDuration: Duration(milliseconds: resultMap['processingTime'] ?? 0),
        ),
        characteristics: Map<String, dynamic>.from(resultMap['characteristics']),
        similarPets: [],
        detectedType: resultMap['detectedType'],
        estimatedAge: resultMap['estimatedAge'],
        estimatedSize: resultMap['estimatedSize'],
        analysisTime: DateTime.parse(map['timestamp']),
        totalProcessingTime: Duration(milliseconds: resultMap['processingTime'] ?? 0),
      ),
      userId: map['userId'],
      petId: map['petId'],
    );
  }
}