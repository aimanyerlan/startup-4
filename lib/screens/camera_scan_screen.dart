import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_app/widgets/layout.dart'; 
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart'; 

const Color _emerald = Color(0xFF10B981);

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isScanning = false;
  
  // Переменная для отслеживания состояния вспышки
  bool _isFlashOn = false;

  late AnimationController _lineController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _lineController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.setFocusMode(FocusMode.auto);
      
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Ошибка камеры: $e");
    }
  }

  // Метод переключения вспышки
  Future<void> _toggleFlash() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      debugPrint("Ошибка вспышки: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    _lineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (_isScanning) _stopScanning();
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
    _lineController.repeat();
    _pulseController.repeat();
    _cameraController?.startImageStream(_processCameraImage);
  }

  void _stopScanning() {
    _cameraController?.stopImageStream();
    _lineController.stop();
    _pulseController.stop();
    setState(() => _isScanning = false);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame || !_isScanning) return;
    _isProcessingFrame = true;

    try {
      final inputImage = _convertCameraImage(image);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String structuredText = recognizedText.blocks.map((b) => b.text).join('\n---\n');

      if (structuredText.length > 40) { 
        await HapticFeedback.heavyImpact();
        _stopScanning();

        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/results',
            arguments: {'fullText': structuredText},
          );
        }
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return InputImage.fromBytes(
      bytes: allBytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation90deg, 
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) await _handleBack();
      },
      child: Layout(
        showNav: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: _isCameraInitialized 
                ? CameraPreview(_cameraController!) 
                : Container(color: Colors.black),
            ),
            _buildGlassHeader(),
            Column(
              children: [
                const SizedBox(height: 120),
                Expanded(child: Center(child: _buildViewfinder())),
                _buildCaptureZone(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassHeader() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _handleBack,
                  ),
                  // Кнопка вспышки
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off, 
                      color: _isFlashOn ? Colors.yellow : Colors.white
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 300, height: 320,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            _cornerMarker(Alignment.topLeft),
            _cornerMarker(Alignment.topRight, isRight: true),
            _cornerMarker(Alignment.bottomLeft, isBottom: true),
            _cornerMarker(Alignment.bottomRight, isRight: true, isBottom: true),
            if (_isScanning)
              AnimatedBuilder(
                animation: _lineController,
                builder: (context, _) => Positioned(
                  top: 320 * _lineController.value,
                  child: Container(width: 300, height: 2, color: _emerald),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _isScanning ? "Анализируем..." : "Наведите на состав",
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _cornerMarker(Alignment alignment, {bool isRight = false, bool isBottom = false}) {
    return Positioned(
      left: isRight ? null : 0, right: isRight ? 0 : null,
      top: isBottom ? null : 0, bottom: isBottom ? 0 : null,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: !isBottom ? const BorderSide(width: 4, color: _emerald) : BorderSide.none,
            bottom: isBottom ? const BorderSide(width: 4, color: _emerald) : BorderSide.none,
            left: !isRight ? const BorderSide(width: 4, color: _emerald) : BorderSide.none,
            right: isRight ? const BorderSide(width: 4, color: _emerald) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureZone() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: GestureDetector(
        onTap: _isScanning ? null : _startScanning,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isScanning)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => Transform.scale(
                  scale: 1.0 + 0.5 * _pulseController.value,
                  child: Opacity(
                    opacity: 1 - _pulseController.value,
                    child: Container(width: 80, height: 80, decoration: const BoxDecoration(color: _emerald, shape: BoxShape.circle)),
                  ),
                ),
              ),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
              child: _isScanning ? const Center(child: CircularProgressIndicator(color: _emerald)) : null,
            ),
          ],
        ),
      ),
    );
  }
}