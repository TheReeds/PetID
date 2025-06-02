import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/pet_model.dart';
import '../models/ai_recognition_result.dart';
import 'firebase_service.dart';

class AIRecognitionService {
  // API Keys - CAMBIAR ESTOS POR TUS KEYS REALES
  static const String _googleVisionApiKey = 'AIzaSyB65mcXMNoOelkoYzeGUcwu_sD8RtZFBT4';
  static const String _roboflowApiKey = 'kzEso6BdqfaNpl9MxyZn';
  static const String _clarifaiApiKey = '9902aa0fca4e4f7f918f5692f58157ee';

  // URLs de APIs
  static const String _googleVisionUrl = 'https://vision.googleapis.com/v1/images:annotate';
  static const String _roboflowUrl = 'https://serverless.roboflow.com/dog-breeds-uvqar-ignp4/2';
  static const String _clarifaiUrl = 'https://api.clarifai.com/v2/models/general-image-recognition/outputs';

  // Reconocer raza de mascota usando múltiples APIs
  static Future<BreedRecognitionResult> recognizeBreed(File imageFile) async {
    try {
      if (kDebugMode) {
        print('Iniciando reconocimiento de raza...');
      }

      // Comprimir imagen para APIs
      final compressedImage = await _compressImage(imageFile);

      // Intentar múltiples servicios en paralelo
      final results = await Future.wait([
        _recognizeBreedWithGoogle(compressedImage),
        _recognizeBreedWithRoboflow(compressedImage),
        _recognizeBreedWithClarifai(compressedImage),
      ]);

      // Combinar resultados y seleccionar el mejor
      return _combineBreedResults(results);
    } catch (e) {
      if (kDebugMode) {
        print('Error en reconocimiento de raza: $e');
      }
      return BreedRecognitionResult(
        breed: 'Desconocida',
        confidence: 0.0,
        error: 'Error al procesar imagen: $e',
      );
    }
  }

  // Buscar mascotas similares en la base de datos
  static Future<List<SimilarPetResult>> findSimilarPets(File imageFile) async {
    try {
      if (kDebugMode) {
        print('Buscando mascotas similares...');
      }

      // Obtener todas las mascotas registradas
      final petsSnapshot = await FirebaseService.pets.get();
      final pets = petsSnapshot.docs
          .map((doc) => PetModel.fromFirestore(doc))
          .where((pet) => pet.profilePhoto != null)
          .toList();

      if (pets.isEmpty) {
        return [];
      }

      // Generar embeddings de la imagen de búsqueda
      final searchEmbedding = await _generateImageEmbedding(imageFile);
      if (searchEmbedding == null) {
        return [];
      }

      List<SimilarPetResult> similarPets = [];

      // Comparar con cada mascota registrada
      for (final pet in pets) {
        try {
          final similarity = await _comparePetImages(imageFile, pet.profilePhoto!);
          if (similarity > 0.3) { // Umbral de similitud
            similarPets.add(SimilarPetResult(
              pet: pet,
              similarity: similarity,
              matchType: similarity > 0.8 ? 'Alta' : similarity > 0.6 ? 'Media' : 'Baja',
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error comparando con ${pet.name}: $e');
          }
        }
      }

      // Ordenar por similitud
      similarPets.sort((a, b) => b.similarity.compareTo(a.similarity));

      return similarPets.take(5).toList(); // Top 5 resultados
    } catch (e) {
      if (kDebugMode) {
        print('Error buscando mascotas similares: $e');
      }
      return [];
    }
  }

  // Análisis completo de la imagen (raza + características)
  static Future<PetAnalysisResult> analyzeImage(File imageFile) async {
    final startTime = DateTime.now();

    try {
      if (kDebugMode) {
        print('🚀 Iniciando análisis completo de imagen...');
      }

      // Ejecutar análisis en paralelo
      final results = await Future.wait([
        recognizeBreedWithAllModels(imageFile), // CAMBIADO: usar el nuevo método
        _detectPetCharacteristics(imageFile),
        findSimilarPets(imageFile),
      ]);

      final breedAnalysis = results[0] as MultiModelBreedResult;
      final characteristics = results[1] as Map<String, dynamic>;
      final similarPets = results[2] as List<SimilarPetResult>;

      final endTime = DateTime.now();
      final totalProcessingTime = endTime.difference(startTime);

      if (kDebugMode) {
        print('✅ Análisis completo terminado en ${totalProcessingTime.inSeconds}s');
        print('📊 Modelos usados: ${breedAnalysis.modelCount}');
        print('🤝 Consenso: ${breedAnalysis.consensusLevel}');
        print('🔍 Mascotas similares: ${similarPets.length}');
      }

      return PetAnalysisResult(
        breedAnalysis: breedAnalysis,
        characteristics: characteristics,
        similarPets: similarPets,
        detectedType: characteristics['type'] ?? 'Desconocido',
        estimatedAge: characteristics['age'] ?? 'Desconocido',
        estimatedSize: characteristics['size'] ?? 'Desconocido',
        analysisTime: startTime,
        totalProcessingTime: totalProcessingTime,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en análisis completo: $e');
      }

      final endTime = DateTime.now();
      final totalProcessingTime = endTime.difference(startTime);

      return PetAnalysisResult.error('Error al analizar imagen: $e')
        ..totalProcessingTime = totalProcessingTime;
    }
  }
  static Future<MultiModelBreedResult> recognizeBreedWithAllModels(File imageFile) async {
    final startTime = DateTime.now();

    try {
      if (kDebugMode) {
        print('Iniciando reconocimiento de raza con todos los modelos...');
      }

      // Comprimir imagen para APIs
      final compressedImage = await _compressImage(imageFile);

      // Ejecutar todos los servicios en paralelo y capturar cada resultado individualmente
      final futures = <Future<BreedRecognitionResult>>[];
      final sources = <String>[];

      // Google Vision
      if (_googleVisionApiKey != 'TU_GOOGLE_VISION_API_KEY') {
        futures.add(_recognizeBreedWithGoogle(compressedImage));
        sources.add('google');
      }

      // Roboflow
      if (_roboflowApiKey != 'TU_ROBOFLOW_API_KEY') {
        futures.add(_recognizeBreedWithRoboflow(compressedImage));
        sources.add('roboflow');
      }

      // Clarifai
      if (_clarifaiApiKey != 'TU_CLARIFAI_API_KEY') {
        futures.add(_recognizeBreedWithClarifai(compressedImage));
        sources.add('clarifai');
      }

      // Esperar todos los resultados
      final results = await Future.wait(futures, eagerError: false);

      // Asignar resultados a cada servicio
      BreedRecognitionResult? googleResult;
      BreedRecognitionResult? roboflowResult;
      BreedRecognitionResult? clarifaiResult;

      for (int i = 0; i < results.length; i++) {
        switch (sources[i]) {
          case 'google':
            googleResult = results[i];
            break;
          case 'roboflow':
            roboflowResult = results[i];
            break;
          case 'clarifai':
            clarifaiResult = results[i];
            break;
        }
      }

      // Seleccionar el mejor resultado
      final validResults = results.where((r) => r.isValid && r.confidence > 0.3).toList();
      validResults.sort((a, b) => b.confidence.compareTo(a.confidence));

      final bestResult = validResults.isNotEmpty
          ? validResults.first
          : BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);

      final endTime = DateTime.now();
      final processingDuration = endTime.difference(startTime);

      if (kDebugMode) {
        print('🎯 Análisis completado en ${processingDuration.inMilliseconds}ms');
        print('📊 Google Vision: ${googleResult?.breed} (${googleResult?.confidencePercentage})');
        print('📊 Roboflow: ${roboflowResult?.breed} (${roboflowResult?.confidencePercentage})');
        print('📊 Clarifai: ${clarifaiResult?.breed} (${clarifaiResult?.confidencePercentage})');
        print('🏆 Mejor resultado: ${bestResult.breed} (${bestResult.confidencePercentage})');
      }

      return MultiModelBreedResult(
        googleVisionResult: googleResult,
        roboflowResult: roboflowResult,
        clarifaiResult: clarifaiResult,
        bestResult: bestResult,
        analysisTime: startTime,
        processingDuration: processingDuration,
      );

    } catch (e) {
      if (kDebugMode) {
        print('Error en reconocimiento de raza: $e');
      }

      final endTime = DateTime.now();
      final processingDuration = endTime.difference(startTime);

      return MultiModelBreedResult(
        bestResult: BreedRecognitionResult(
          breed: 'Desconocida',
          confidence: 0.0,
          error: 'Error al procesar imagen: $e',
        ),
        analysisTime: startTime,
        processingDuration: processingDuration,
      );
    }
  }
  // MÉTODOS PRIVADOS

  // Reconocimiento de raza con Google Vision
  static Future<BreedRecognitionResult> _recognizeBreedWithGoogle(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$_googleVisionUrl?key=$_googleVisionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [{
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},
            ],
          }],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseGoogleVisionResponse(data);
      } else {
        throw Exception('Google Vision API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error con Google Vision: $e');
      }
      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    }
  }

  // Reconocimiento con Roboflow (especializado en mascotas)
  static Future<BreedRecognitionResult> _recognizeBreedWithRoboflow(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$_roboflowUrl?api_key=$_roboflowApiKey'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: base64Image,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseRoboflowResponse(data);
      } else {
        throw Exception('Roboflow API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error con Roboflow: $e');
      }
      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    }
  }

  // Reconocimiento con Clarifai
  static Future<BreedRecognitionResult> _recognizeBreedWithClarifai(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(_clarifaiUrl),
        headers: {
          'Authorization': 'Key $_clarifaiApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': [{
            'data': {
              'image': {'base64': base64Image}
            }
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseClarifaiResponse(data);
      } else {
        throw Exception('Clarifai API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error con Clarifai: $e');
      }
      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    }
  }

  // Detectar características de la mascota
  static Future<Map<String, dynamic>> _detectPetCharacteristics(File imageFile) async {
    try {
      final imageBytes = await _compressImage(imageFile);
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$_googleVisionUrl?key=$_googleVisionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [{
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 20},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},
            ],
          }],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _extractCharacteristics(data);
      }

      return {};
    } catch (e) {
      if (kDebugMode) {
        print('Error detectando características: $e');
      }
      return {};
    }
  }

  // Generar embedding de imagen para comparación
  // Generar embedding de imagen para comparación - CORREGIDO
  static Future<List<double>?> _generateImageEmbedding(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) return null;

      // Generar embedding simple basado en histograma de colores
      List<double> embedding = [];

      // Histograma RGB simplificado
      List<int> rHist = List.filled(16, 0);
      List<int> gHist = List.filled(16, 0);
      List<int> bHist = List.filled(16, 0);

      for (int y = 0; y < image.height; y += 10) {
        for (int x = 0; x < image.width; x += 10) {
          final pixel = image.getPixel(x, y);

          // CORREGIDO: Usar métodos correctos de la librería image
          final r = pixel.r.toInt() ~/ 16;
          final g = pixel.g.toInt() ~/ 16;
          final b = pixel.b.toInt() ~/ 16;

          if (r < 16) rHist[r]++;
          if (g < 16) gHist[g]++;
          if (b < 16) bHist[b]++;
        }
      }

      // Normalizar histogramas
      final total = (image.width ~/ 10) * (image.height ~/ 10);
      embedding.addAll(rHist.map((x) => x / total));
      embedding.addAll(gHist.map((x) => x / total));
      embedding.addAll(bHist.map((x) => x / total));

      return embedding;
    } catch (e) {
      return null;
    }
  }

  // Comparar dos imágenes para similitud
  static Future<double> _comparePetImages(File image1, String imageUrl2) async {
    try {
      // Descargar imagen 2
      final response = await http.get(Uri.parse(imageUrl2));
      if (response.statusCode != 200) return 0.0;

      final image2File = File('${Directory.systemTemp.path}/temp_image.jpg');
      await image2File.writeAsBytes(response.bodyBytes);

      // Generar embeddings
      final embedding1 = await _generateImageEmbedding(image1);
      final embedding2 = await _generateImageEmbedding(image2File);

      // Limpiar archivo temporal
      if (await image2File.exists()) {
        await image2File.delete();
      }

      if (embedding1 == null || embedding2 == null) return 0.0;

      // Calcular similitud coseno
      return _cosineSimilarity(embedding1, embedding2);
    } catch (e) {
      return 0.0;
    }
  }

  // Calcular similitud coseno entre dos vectores
  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  // Comprimir imagen para APIs
  static Future<Uint8List> _compressImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) return imageBytes;

    // Redimensionar si es muy grande
    final resized = image.width > 800 || image.height > 800
        ? img.copyResize(image, width: 800)
        : image;

    // Comprimir a JPEG con calidad 85
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  // PARSERS DE RESPUESTAS

  static BreedRecognitionResult _parseGoogleVisionResponse(Map<String, dynamic> data) {
    try {
      final responses = data['responses'] as List;
      if (responses.isEmpty) {
        return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
      }

      final labels = responses[0]['labelAnnotations'] as List? ?? [];

      // Buscar etiquetas relacionadas con razas de perros/gatos
      for (final label in labels) {
        final description = label['description'] as String;
        final score = label['score'] as double;

        if (_isBreedLabel(description)) {
          return BreedRecognitionResult(
            breed: _cleanBreedName(description),
            confidence: score,
            source: 'Google Vision',
          );
        }
      }

      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    } catch (e) {
      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    }
  }

  static BreedRecognitionResult _parseRoboflowResponse(Map<String, dynamic> data) {
    try {
      final predictions = data['predictions'] as List? ?? [];
      if (predictions.isEmpty) {
        return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
      }

      final topPrediction = predictions[0];
      return BreedRecognitionResult(
        breed: _cleanBreedName(topPrediction['class'] ?? 'Desconocida'),
        confidence: topPrediction['confidence'] ?? 0.0,
        source: 'Roboflow',
      );
    } catch (e) {
      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    }
  }

  static BreedRecognitionResult _parseClarifaiResponse(Map<String, dynamic> data) {
    try {
      final outputs = data['outputs'] as List? ?? [];
      if (outputs.isEmpty) {
        return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
      }

      final concepts = outputs[0]['data']['concepts'] as List? ?? [];

      for (final concept in concepts) {
        final name = concept['name'] as String;
        final value = concept['value'] as double;

        if (_isBreedLabel(name)) {
          return BreedRecognitionResult(
            breed: _cleanBreedName(name),
            confidence: value,
            source: 'Clarifai',
          );
        }
      }

      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    } catch (e) {
      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    }
  }

  static Map<String, dynamic> _extractCharacteristics(Map<String, dynamic> data) {
    Map<String, dynamic> characteristics = {};

    try {
      final responses = data['responses'] as List;
      if (responses.isEmpty) return {};

      final labels = responses[0]['labelAnnotations'] as List? ?? [];

      for (final label in labels) {
        final description = (label['description'] as String).toLowerCase();
        final score = label['score'] as double;

        // Detectar tipo de animal
        if (description.contains('dog') || description.contains('puppy')) {
          characteristics['type'] = 'Perro';
        } else if (description.contains('cat') || description.contains('kitten')) {
          characteristics['type'] = 'Gato';
        }

        // Detectar tamaño
        if (description.contains('small') && score > 0.7) {
          characteristics['size'] = 'Pequeño';
        } else if (description.contains('large') && score > 0.7) {
          characteristics['size'] = 'Grande';
        }

        // Detectar edad aproximada
        if (description.contains('puppy') || description.contains('kitten')) {
          characteristics['age'] = 'Cachorro';
        } else if (description.contains('adult')) {
          characteristics['age'] = 'Adulto';
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error extrayendo características: $e');
      }
    }

    return characteristics;
  }

  static BreedRecognitionResult _combineBreedResults(List<BreedRecognitionResult> results) {
    // Filtrar resultados válidos
    final validResults = results.where((r) => r.breed != 'Desconocida' && r.confidence > 0.3).toList();

    if (validResults.isEmpty) {
      return BreedRecognitionResult(breed: 'Desconocida', confidence: 0.0);
    }

    // Ordenar por confianza
    validResults.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Devolver el mejor resultado
    return validResults.first;
  }

  static bool _isBreedLabel(String label) {
    final breedKeywords = [
      'golden retriever', 'labrador', 'bulldog', 'german shepherd', 'poodle',
      'chihuahua', 'beagle', 'rottweiler', 'yorkshire', 'dachshund',
      'siberian husky', 'shih tzu', 'boston terrier', 'pomeranian',
      'persian cat', 'siamese', 'maine coon', 'british shorthair',
      'ragdoll', 'bengal', 'abyssinian', 'russian blue'
    ];

    final lowerLabel = label.toLowerCase();
    return breedKeywords.any((breed) => lowerLabel.contains(breed));
  }

  static String _cleanBreedName(String breed) {
    return breed
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}