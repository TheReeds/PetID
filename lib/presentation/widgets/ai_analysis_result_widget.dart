// lib/presentation/widgets/ai_analysis_result_widget.dart (COMPLETO)
import 'package:flutter/material.dart';
import 'dart:math' as Math;
import '../../data/models/ai_recognition_result.dart';
import '../../data/models/pet_model.dart';
import '../screens/pets/pet_detail_screen.dart';

class AIAnalysisResultWidget extends StatefulWidget {
  final PetAnalysisResult result;
  final VoidCallback? onSaveResult;
  final VoidCallback? onNewAnalysis;

  const AIAnalysisResultWidget({
    super.key,
    required this.result,
    this.onSaveResult,
    this.onNewAnalysis,
  });

  @override
  State<AIAnalysisResultWidget> createState() => _AIAnalysisResultWidgetState();
}

class _AIAnalysisResultWidgetState extends State<AIAnalysisResultWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.result.isValid) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // Header con resumen
        _buildResultHeader(),
        const SizedBox(height: 20),

        // Tabs de resultados
        _buildTabBar(),

        // Contenido de tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBreedTab(),
              _buildCharacteristicsTab(),
              _buildSimilarPetsTab(),
            ],
          ),
        ),

        // Botones de acción
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.result.error ?? 'Error desconocido',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (widget.onNewAnalysis != null)
            ElevatedButton(
              onPressed: widget.onNewAnalysis,
              child: const Text('Intentar de nuevo'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    final breedAnalysis = widget.result.breedAnalysis;
    final bestResult = breedAnalysis.bestResult;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A7AA7),
            const Color(0xFF6B9BD1),
            const Color(0xFF8BB5E8),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A7AA7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Análisis Completado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${breedAnalysis.modelCount} modelo${breedAnalysis.modelCount != 1 ? 's' : ''} de IA analizaron la imagen',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.result.hasBreedInfo) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Raza Identificada',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bestResult.breed,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Confianza',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              bestResult.confidencePercentage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Indicador de consenso mejorado
                  if (breedAnalysis.modelCount > 1) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: breedAnalysis.hasConsensus
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              breedAnalysis.hasConsensus
                                  ? Icons.check_circle
                                  : Icons.info,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Consenso: ${breedAnalysis.consensusLevel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.result.totalProcessingTime.inSeconds}s',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          color: const Color(0xFF4A7AA7),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A7AA7).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return Colors.grey.withOpacity(0.1);
            }
            if (states.contains(MaterialState.pressed)) {
              return Colors.grey.withOpacity(0.2);
            }
            return null;
          },
        ),
        tabs: const [
          Tab(
            text: 'Raza',
            height: 45,
          ),
          Tab(
            text: 'Información',
            height: 45,
          ),
          Tab(
            text: 'Similares',
            height: 45,
          ),
        ],
      ),
    );
  }

  // PESTAÑA DE RAZA MEJORADA CON TODOS LOS MODELOS
  Widget _buildBreedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mejor resultado (destacado)
          _buildBestResultCard(),

          const SizedBox(height: 20),

          // Consenso y estadísticas
          if (widget.result.breedAnalysis.modelCount > 1) ...[
            _buildConsensusCard(),
            const SizedBox(height: 20),
          ],

          // Resultados de todos los modelos
          _buildAllModelsCard(),

          const SizedBox(height: 20),

          // Indicador de confianza del mejor resultado
          if (widget.result.hasBreedInfo) _buildConfidenceIndicator(),
        ],
      ),
    );
  }

  Widget _buildBestResultCard() {
    final bestResult = widget.result.breedAnalysis.bestResult;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A7AA7),
            const Color(0xFF6B9BD1),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mejor Resultado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (bestResult.source != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bestResult.source!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            bestResult.breed,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Confianza: ${bestResult.confidencePercentage}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bestResult.confidenceLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsensusCard() {
    final breedAnalysis = widget.result.breedAnalysis;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: breedAnalysis.hasConsensus ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                breedAnalysis.hasConsensus ? Icons.check_circle : Icons.info,
                color: breedAnalysis.hasConsensus ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Análisis de Consenso',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: breedAnalysis.hasConsensus ? Colors.green[700] : Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Modelos Usados',
                  '${breedAnalysis.modelCount}/3',
                  Icons.psychology,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Nivel de Consenso',
                  breedAnalysis.consensusLevel,
                  Icons.thumbs_up_down,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Tiempo',
                  '${breedAnalysis.processingDuration.inMilliseconds}ms',
                  Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllModelsCard() {
    final breedAnalysis = widget.result.breedAnalysis;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resultados por Modelo de IA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Google Vision
          _buildModelResultCard(
            'Google Vision',
            breedAnalysis.googleVisionResult,
            Icons.visibility,
            const Color(0xFF4285F4),
            'Reconocimiento general de objetos e imágenes',
          ),

          const SizedBox(height: 12),

          // Roboflow
          _buildModelResultCard(
            'Roboflow',
            breedAnalysis.roboflowResult,
            Icons.pets,
            const Color(0xFF6366F1),
            'Especializado en clasificación de razas de perros',
          ),

          const SizedBox(height: 12),

          // Clarifai
          _buildModelResultCard(
            'Clarifai',
            breedAnalysis.clarifaiResult,
            Icons.psychology,
            const Color(0xFF8B5CF6),
            'Reconocimiento visual e inteligencia artificial',
          ),
        ],
      ),
    );
  }

  Widget _buildModelResultCard(
      String modelName,
      BreedRecognitionResult? result,
      IconData icon,
      Color color,
      String description,
      ) {
    final bool isAvailable = result != null;
    final bool isBestResult = isAvailable &&
        result.breed == widget.result.breedAnalysis.bestResult.breed &&
        result.confidence == widget.result.breedAnalysis.bestResult.confidence;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.grey[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBestResult
              ? Colors.green.withOpacity(0.5)
              : isAvailable
              ? color.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: isBestResult ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAvailable ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isAvailable ? color : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          modelName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                        if (isBestResult) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'MEJOR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isAvailable && result.isValid) ...[
            // Resultado válido
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Raza Detectada',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        result.breed,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Confianza',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: result.confidence,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getConfidenceColor(result.confidence),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          result.confidencePercentage,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getConfidenceColor(result.confidence),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ] else if (isAvailable && !result.isValid) ...[
            // Error o resultado inválido
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.error ?? 'No se pudo determinar la raza',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[600],
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // API no disponible
            Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API no configurada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    if (confidence >= 0.4) return Colors.yellow[700]!;
    return Colors.red;
  }

  Widget _buildConfidenceIndicator() {
    final confidence = widget.result.breedAnalysis.bestResult.confidence;
    final color = _getConfidenceColor(confidence);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análisis de Confianza',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: confidence,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.result.breedAnalysis.bestResult.confidencePercentage,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getConfidenceDescription(confidence),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),

          // Información adicional sobre el consenso
          if (widget.result.breedAnalysis.modelCount > 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getConsensusDescription(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getConfidenceDescription(double confidence) {
    if (confidence >= 0.8) {
      return 'Muy confiable - La identificación es muy precisa';
    } else if (confidence >= 0.6) {
      return 'Confiable - La identificación es bastante precisa';
    } else if (confidence >= 0.4) {
      return 'Moderado - La identificación puede ser correcta';
    } else {
      return 'Bajo - La identificación es incierta';
    }
  }

  String _getConsensusDescription() {
    final breedAnalysis = widget.result.breedAnalysis;

    if (breedAnalysis.hasConsensus) {
      return 'Los modelos de IA están de acuerdo en la identificación, lo que aumenta la confiabilidad del resultado.';
    } else if (breedAnalysis.modelCount > 1) {
      return 'Los modelos de IA tienen opiniones diferentes. Te mostramos el resultado con mayor confianza.';
    } else {
      return 'Solo un modelo de IA pudo procesar la imagen. Considera verificar el resultado.';
    }
  }

  Widget _buildCharacteristicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Características Detectadas',
            children: [
              _buildInfoRow(
                'Tipo de Animal',
                widget.result.detectedType,
                Icons.category,
              ),
              _buildInfoRow(
                'Edad Estimada',
                widget.result.estimatedAge,
                Icons.cake,
              ),
              _buildInfoRow(
                'Tamaño Estimado',
                widget.result.estimatedSize,
                Icons.straighten,
              ),
            ],
          ),

          if (widget.result.characteristics.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildInfoCard(
              title: 'Características Adicionales',
              children: widget.result.characteristics.entries
                  .map((entry) => _buildInfoRow(
                _formatKey(entry.key),
                entry.value.toString(),
                Icons.info,
              ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimilarPetsTab() {
    if (!widget.result.hasSimilarPets) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron mascotas similares',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con una imagen más clara o diferente ángulo',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.result.similarPets.length,
      itemBuilder: (context, index) {
        final similarPet = widget.result.similarPets[index];
        return _buildSimilarPetCard(similarPet);
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (color ?? const Color(0xFF4A7AA7)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color ?? const Color(0xFF4A7AA7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF4A7AA7),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarPetCard(SimilarPetResult similarPet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: similarPet.isHighMatch
              ? Colors.green.withOpacity(0.3)
              : similarPet.isMediumMatch
              ? Colors.orange.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto de la mascota
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: similarPet.pet.profilePhoto != null
                  ? Image.network(
                similarPet.pet.profilePhoto!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.pets, size: 40, color: Colors.grey),
              )
                  : const Icon(Icons.pets, size: 40, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),

          // Información de la mascota
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        similarPet.pet.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: similarPet.isHighMatch
                            ? Colors.green[100]
                            : similarPet.isMediumMatch
                            ? Colors.orange[100]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${similarPet.similarityPercentage} similar',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: similarPet.isHighMatch
                              ? Colors.green[700]
                              : similarPet.isMediumMatch
                              ? Colors.orange[700]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${similarPet.pet.breed} • ${similarPet.pet.displayAge}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tipo de coincidencia: ${similarPet.matchType}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Botón para ver detalles
          IconButton(
            onPressed: () => _viewPetDetails(similarPet.pet),
            icon: const Icon(Icons.arrow_forward_ios),
            iconSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.onNewAnalysis != null)
            Expanded(
              child: Container(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: widget.onNewAnalysis,
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text(
                    'Nuevo Análisis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A7AA7),
                    side: const BorderSide(
                      color: Color(0xFF4A7AA7),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),

          if (widget.onNewAnalysis != null && widget.onSaveResult != null)
            const SizedBox(width: 12),

          if (widget.onSaveResult != null)
            Expanded(
              child: Container(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: widget.onSaveResult,
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text(
                    'Guardar Resultado',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7AA7),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF4A7AA7).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    switch (key.toLowerCase()) {
      case 'type':
        return 'Tipo';
      case 'age':
        return 'Edad';
      case 'size':
        return 'Tamaño';
      case 'color':
        return 'Color';
      case 'breed':
        return 'Raza';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  void _viewPetDetails(PetModel pet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(pet: pet),
      ),
    );
  }
}