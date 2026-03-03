import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:my_app/widgets/layout.dart';

const Color _emerald = Color(0xFF10B981);

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with TickerProviderStateMixin {
  bool _isScanning = false;
  int _scanProgress = 0;
  Timer? _timer;
  late AnimationController _lineController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scanProgress = 0;
    });
    _lineController.repeat();
    _pulseController.repeat();

    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        if (_scanProgress >= 100) {
          _scanProgress = 100;
          _stopScanning();
          // navigate after a short delay to give UI a moment
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(
                '/results',
                arguments: {'source': 'scan'},
              );
            }
          });
        } else {
          _scanProgress += 2;
        }
      });
    });
  }

  void _stopScanning() {
    _timer?.cancel();
    _lineController.stop();
    _pulseController.stop();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _handleBack() async {
    if (_isScanning) {
      _stopScanning();
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleBack();
        }
      },
      child: Layout(
        showNav: false,
        child: Stack(
          children: [
          // black background
          Container(color: Colors.black),
          // soft green gradient overlay
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _lineController,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _emerald.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // header with glassmorphism
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _iconButton(Icons.arrow_back, () {
                          _handleBack();
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // main content
          Column(
            children: [
              const SizedBox(height: 120),
              Expanded(
                child: Center(
                  child: _buildViewfinder(),
                ),
              ),
              _buildCaptureZone(),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildViewfinder() {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth.clamp(0.0, 320.0);
      final double height = width * 5 / 4;
      Widget corner(Alignment alignment) {
        return Positioned(
          left: alignment.x == -1 ? 0 : null,
          right: alignment.x == 1 ? 0 : null,
          top: alignment.y == -1 ? 0 : null,
          bottom: alignment.y == 1 ? 0 : null,
          child: _cornerMarker(alignment),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        spreadRadius: 2),
                  ],
                ),
              ),
              // corners
              corner(Alignment.topLeft),
              corner(Alignment.topRight),
              corner(Alignment.bottomLeft),
              corner(Alignment.bottomRight),
              // scanning line inside container
              if (_isScanning)
                AnimatedBuilder(
                  animation: _lineController,
                  builder: (context, _) {
                    final double dy = height * _lineController.value;
                    return Positioned(
                      top: dy,
                      child: Container(
                        width: width,
                        height: 2,
                        color: _emerald,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 500),
            child: Text(
              _isScanning ? "Processing analysis..." : "Align ingredients area",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          if (_isScanning)
            Column(
              children: [
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _scanProgress / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _emerald,
                        boxShadow: [
                          BoxShadow(
                              color: _emerald.withOpacity(0.6),
                              blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Scanning... $_scanProgress%",
                  style: const TextStyle(
                      color: _emerald,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1),
                ),
              ],
            ),
        ],
      );
    });
  }

  // replaces previous _corner; returns a corner marker sized box
  Widget _cornerMarker(Alignment alignment) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: alignment.y == -1
              ? BorderSide(width: 4, color: _emerald)
              : BorderSide.none,
          bottom: alignment.y == 1
              ? BorderSide(width: 4, color: _emerald)
              : BorderSide.none,
          left: alignment.x == -1
              ? BorderSide(width: 4, color: _emerald)
              : BorderSide.none,
          right: alignment.x == 1
              ? BorderSide(width: 4, color: _emerald)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: alignment == Alignment.topLeft
              ? const Radius.circular(38)
              : Radius.zero,
          topRight: alignment == Alignment.topRight
              ? const Radius.circular(38)
              : Radius.zero,
          bottomLeft: alignment == Alignment.bottomLeft
              ? const Radius.circular(38)
              : Radius.zero,
          bottomRight: alignment == Alignment.bottomRight
              ? const Radius.circular(38)
              : Radius.zero,
        ),
      ),
    );
  }

  Widget _buildCaptureZone() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isScanning)
            AnimatedOpacity(
              opacity: 0.6,
              duration: const Duration(seconds: 2),
              child: const Text(
                'Tap to analyze',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1),
              ),
            ),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.center,
            children: [
              if (_isScanning)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final double scale = 0.8 + 0.7 * _pulseController.value;
                    final double opacity = 1 - _pulseController.value;
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              GestureDetector(
                onTap: _isScanning ? null : _startScanning,
                child: AnimatedScale(
                  scale: _isScanning ? 0.9 : 1,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            spreadRadius: 2),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(width: 2, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
