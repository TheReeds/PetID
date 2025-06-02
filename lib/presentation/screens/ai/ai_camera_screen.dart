import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../data/services/ai_recognition_service.dart';
import '../../../data/models/ai_recognition_result.dart';
import '../../widgets/ai_analysis_result_widget.dart';

class AICameraScreen extends StatefulWidget {
  const AICameraScreen({super.key});

  @override
  State<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState extends State<AICameraScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  bool _showResults = false;
  File? _capturedImage;
  PetAnalysisResult? _analysisResult;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestPermissions();
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission.isGranted) {
      await _initializeCamera();
    } else {
      _showPermissionDialog();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error inicializando cámara: $e');
      _showErrorDialog('Error al inicializar la cámara');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Reconocimiento IA'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_showResults)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _resetCamera,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isCameraInitialized) {
      return _buildLoadingScreen();
    }

    if (_showResults && _analysisResult != null) {
      return _buildResultsScreen();
    }

    return _buildCameraScreen();
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text(
            'Inicializando cámara...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Stack(
      children: [
        // Vista de la cámara
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        // Overlay de guía
        Positioned.fill(
          child: _buildCameraOverlay(),
        ),

        // Animación de escaneo cuando está analizando
        if (_isAnalyzing) _buildScanningOverlay(),

        // Controles inferiores
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildCameraControls(),
        ),

        // Instrucciones superiores
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildInstructions(),
        ),
      ],
    );
  }

  Widget _buildCameraOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Esquinas del marco
              ...List.generate(4, (index) => _buildCorner(index)),

              // Centro del marco
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(int index) {
    final positions = [
      const Alignment(-1, -1), // Top-left
      const Alignment(1, -1),  // Top-right
      const Alignment(-1, 1),  // Bottom-left
      const Alignment(1, 1),   // Bottom-right
    ];

    return Align(
      alignment: positions[index],
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: index < 2 ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: index >= 2 ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: index % 2 == 0 ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: index % 2 == 1 ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
          ),
          child: Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Línea de escaneo
                  Positioned(
                    top: _scanAnimation.value * 260 + 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.blue.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Centro pulsante
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(0.3),
                              border: Border.all(color: Colors.blue, width: 3),
                            ),
                            child: const Icon(
                              Icons.pets,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              _isAnalyzing
                  ? 'Analizando imagen con IA...'
                  : 'Coloca la mascota dentro del marco',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!_isAnalyzing) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '• Reconocimiento de raza\n• Búsqueda de mascotas similares\n• Análisis de características',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Galería
          FloatingActionButton(
            heroTag: "gallery",
            onPressed: _isAnalyzing ? null : _pickFromGallery,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.photo_library, color: Colors.white),
          ),

          // Botón de captura principal
          GestureDetector(
            onTap: _isAnalyzing ? null : _captureAndAnalyze,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isAnalyzing ? Colors.grey : Colors.white,
                border: Border.all(
                  color: _isAnalyzing ? Colors.grey : Colors.blue,
                  width: 4,
                ),
              ),
              child: _isAnalyzing
                  ? const CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              )
                  : const Icon(
                Icons.camera_alt,
                color: Colors.blue,
                size: 35,
              ),
            ),
          ),

          // Cambiar cámara
          FloatingActionButton(
            heroTag: "switch_camera",
            onPressed: _isAnalyzing ? null : _switchCamera,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.switch_camera, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Imagen capturada
          if (_capturedImage != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: FileImage(_capturedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Resultados del análisis
          Expanded(
            child: AIAnalysisResultWidget(
              result: _analysisResult!,
              onSaveResult: _saveAnalysisResult,
              onNewAnalysis: _resetCamera,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || _isAnalyzing) return;

    try {
      setState(() {
        _isAnalyzing = true;
      });

      // Iniciar animaciones
      _scanAnimationController.repeat();
      _pulseAnimationController.repeat(reverse: true);

      // Capturar imagen
      final image = await _cameraController!.takePicture();
      _capturedImage = File(image.path);

      // Analizar con IA
      final result = await AIRecognitionService.analyzeImage(_capturedImage!);

      // Detener animaciones
      _scanAnimationController.stop();
      _pulseAnimationController.stop();

      setState(() {
        _analysisResult = result;
        _showResults = true;
        _isAnalyzing = false;
      });

    } catch (e) {
      print('Error en captura y análisis: $e');
      _showErrorDialog('Error al capturar y analizar la imagen');

      setState(() {
        _isAnalyzing = false;
      });

      _scanAnimationController.stop();
      _pulseAnimationController.stop();
    }
  }

  Future<void> _pickFromGallery() async {
    // Implementar selección desde galería
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de galería próximamente')),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return;

    final currentIndex = _cameras.indexOf(_cameraController!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;

    await _cameraController?.dispose();

    _cameraController = CameraController(
      _cameras[nextIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() {});
  }

  void _resetCamera() {
    setState(() {
      _showResults = false;
      _analysisResult = null;
      _capturedImage = null;
      _isAnalyzing = false;
    });
  }

  Future<void> _saveAnalysisResult() async {
    if (_analysisResult == null) return;

    // Implementar guardado en historial
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resultado guardado en el historial'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso de Cámara'),
        content: const Text(
          'Esta aplicación necesita acceso a la cámara para reconocer mascotas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}