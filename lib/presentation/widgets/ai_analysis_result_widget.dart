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
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Análisis Completado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.result.summary,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.result.hasBreedInfo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Raza Detectada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.result.breed.breed,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Confianza',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.result.breed.confidencePercentage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        indicator: BoxDecoration(
          color: const Color(0xFF4A7AA7),
          borderRadius: BorderRadius.circular(25),
        ),
        tabs: const [
          Tab(text: 'Raza'),
          Tab(text: 'Info'),
          Tab(text: 'Similares'),
        ],
      ),
    );
  }

  Widget _buildBreedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.result.hasBreedInfo) ...[
            _buildInfoCard(
              title: 'Información de Raza',
              children: [
                _buildInfoRow(
                  'Raza',
                  widget.result.breed.breed,
                  Icons.pets,
                ),
                _buildInfoRow(
                  'Confianza',
                  widget.result.breed.confidencePercentage,
                  Icons.bar_chart,
                ),
                _buildInfoRow(
                  'Nivel de Confianza',
                  widget.result.breed.confidenceLevel,
                  Icons.speed,
                ),
                if (widget.result.breed.source != null)
                  _buildInfoRow(
                    'Fuente',
                    widget.result.breed.source!,
                    Icons.source,
                  ),
              ],
            ),

            const SizedBox(height: 20),

            _buildConfidenceIndicator(),
          ] else
            _buildNoBreedInfo(),
        ],
      ),
    );
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
  }) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final confidence = widget.result.breed.confidence;
    final color = confidence >= 0.8
        ? Colors.green
        : confidence >= 0.6
        ? Colors.orange
        : confidence >= 0.4
        ? Colors.yellow[700]
        : Colors.red;

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
            'Nivel de Confianza',
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
                widget.result.breed.confidencePercentage,
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
        ],
      ),
    );
  }

  Widget _buildNoBreedInfo() {
    return Container(
      padding: const EdgeInsets.all(30),
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
        children: [
          Icon(
            Icons.help_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No se pudo determinar la raza',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con una imagen más clara donde se vea mejor la mascota',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (widget.onNewAnalysis != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onNewAnalysis,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Nuevo Análisis'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (widget.onNewAnalysis != null && widget.onSaveResult != null)
            const SizedBox(width: 16),

          if (widget.onSaveResult != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onSaveResult,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Resultado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A7AA7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  void _viewPetDetails(PetModel pet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(pet: pet),
      ),
    );
  }
}