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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Reconocimiento IA',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.3),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_showResults)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 20),
                ),
                onPressed: _resetCamera,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 4,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Inicializando cámara...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Preparando el reconocimiento IA',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Vista de la cámara con aspectRatio correcto
            Positioned.fill(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),

                ),
              ),
            ),

            // Overlay de guía
            Positioned.fill(
              child: _buildCameraOverlay(constraints),
            ),

            // Animación de escaneo cuando está analizando
            if (_isAnalyzing) _buildScanningOverlay(constraints),

            // Instrucciones superiores
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildInstructions(),
            ),

            // Controles inferiores
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCameraControls(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCameraOverlay(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final frameSize = screenWidth * 0.75; // 75% del ancho de pantalla
    final maxFrameSize = 320.0;
    final finalFrameSize = frameSize > maxFrameSize ? maxFrameSize : frameSize;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
      ),
      child: Center(
        child: Container(
          width: finalFrameSize,
          height: finalFrameSize,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Esquinas del marco mejoradas
              ...List.generate(4, (index) => _buildCorner(index)),

              // Centro del marco
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 35,
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
    const cornerSize = 25.0;
    const borderWidth = 4.0;

    final positions = [
      const Alignment(-1, -1), // Top-left
      const Alignment(1, -1),  // Top-right
      const Alignment(-1, 1),  // Bottom-left
      const Alignment(1, 1),   // Bottom-right
    ];

    return Align(
      alignment: positions[index],
      child: Container(
        margin: const EdgeInsets.all(8),
        width: cornerSize,
        height: cornerSize,
        decoration: BoxDecoration(
          border: Border(
            top: index < 2 ? const BorderSide(color: Colors.blue, width: borderWidth) : BorderSide.none,
            bottom: index >= 2 ? const BorderSide(color: Colors.blue, width: borderWidth) : BorderSide.none,
            left: index % 2 == 0 ? const BorderSide(color: Colors.blue, width: borderWidth) : BorderSide.none,
            right: index % 2 == 1 ? const BorderSide(color: Colors.blue, width: borderWidth) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildScanningOverlay(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final frameSize = screenWidth * 0.75;
    final maxFrameSize = 320.0;
    final finalFrameSize = frameSize > maxFrameSize ? maxFrameSize : frameSize;

    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
          ),
          child: Center(
            child: Container(
              width: finalFrameSize,
              height: finalFrameSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Línea de escaneo mejorada
                  Positioned(
                    top: _scanAnimation.value * (finalFrameSize - 60) + 30,
                    left: 30,
                    right: 30,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.blue,
                            Colors.lightBlueAccent,
                            Colors.blue,
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.7),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Centro pulsante mejorado
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.4),
                                  Colors.blue.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(color: Colors.blue, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pets,
                              color: Colors.blue,
                              size: 45,
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
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              _isAnalyzing
                  ? 'Analizando imagen con IA...'
                  : 'Coloca la mascota dentro del marco',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!_isAnalyzing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.8),
                    Colors.blue.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Análisis IA Avanzado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Reconocimiento de raza\n• Búsqueda de mascotas similares\n• Análisis de características',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Galería
          _buildControlButton(
            icon: Icons.photo_library,
            onPressed: _isAnalyzing ? null : _pickFromGallery,
            size: 56,
          ),

          // Botón de captura principal
          GestureDetector(
            onTap: _isAnalyzing ? null : _captureAndAnalyze,
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isAnalyzing
                    ? LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade700])
                    : const LinearGradient(
                  colors: [Colors.white, Colors.grey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _isAnalyzing ? Colors.grey.shade600 : Colors.blue,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isAnalyzing ? Colors.grey : Colors.blue).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _isAnalyzing
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 4,
                ),
              )
                  : const Icon(
                Icons.camera_alt,
                color: Colors.blue,
                size: 40,
              ),
            ),
          ),

          // Cambiar cámara
          _buildControlButton(
            icon: Icons.switch_camera,
            onPressed: _isAnalyzing || _cameras.length <= 1 ? null : _switchCamera,
            size: 56,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double size,
  }) {
    final isEnabled = onPressed != null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isEnabled
              ? [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)]
              : [Colors.grey.withOpacity(0.2), Colors.grey.withOpacity(0.1)],
        ),
        border: Border.all(
          color: isEnabled ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
            size: size * 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          // Imagen capturada con diseño mejorado
          if (_capturedImage != null)
            Container(
              margin: const EdgeInsets.all(20),
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  _capturedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Resultados del análisis
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: AIAnalysisResultWidget(
                result: _analysisResult!,
                onSaveResult: _saveAnalysisResult,
                onNewAnalysis: _resetCamera,
              ),
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
      SnackBar(
        content: const Text('Función de galería próximamente'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Resultado guardado en el historial'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.blue),
            SizedBox(width: 12),
            Text('Permiso de Cámara'),
          ],
        ),
        content: const Text(
          'Esta aplicación necesita acceso a la cámara para reconocer mascotas mediante inteligencia artificial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Configuración', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}