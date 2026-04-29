import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:my_app/widgets/layout.dart';
import 'package:flutter/services.dart';

const Color _emerald = Color(0xFF10B981);

class CameraScanScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const CameraScanScreen({super.key, this.onBackToHome});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.max, // Максимальное качество для Cloud Vision
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.setFocusMode(FocusMode.auto);
      
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

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
      debugPrint("Flash toggle error: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null || _isTakingPicture) return;

    setState(() => _isTakingPicture = true);
    try {
      await HapticFeedback.mediumImpact();
      final XFile image = await _cameraController!.takePicture();
      
      if (mounted) {
        // Передаем путь к файлу на экран результатов
        Navigator.of(context).pushReplacementNamed(
          '/results',
          arguments: {'imagePath': image.path},
        );
      }
    } catch (e) {
      debugPrint("Take picture error: $e");
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    widget.onBackToHome?.call();
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
              width: 300, height: 400,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            _cornerMarker(Alignment.topLeft),
            _cornerMarker(Alignment.topRight, isRight: true),
            _cornerMarker(Alignment.bottomLeft, isBottom: true),
            _cornerMarker(Alignment.bottomRight, isRight: true, isBottom: true),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "Point at the ingredient list and capture",
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
        onTap: _takePicture,
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white, 
            shape: BoxShape.circle, 
            border: Border.all(color: Colors.grey.shade300, width: 4)
          ),
          child: _isTakingPicture 
              ? const Center(child: CircularProgressIndicator(color: _emerald)) 
              : Center(
                  child: Container(
                    width: 65, 
                    height: 65, 
                    decoration: const BoxDecoration(
                      color: Colors.white, 
                      shape: BoxShape.circle, 
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}