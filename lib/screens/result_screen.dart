import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');
  bool _isLoading = true;
  bool _canSaveAnalysis = true;
  Map<String, dynamic>? _analysisResult;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_analysisResult == null && _error == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      final hasSavedAnalysisData = args != null &&
          (args.containsKey('status') ||
              args.containsKey('dangerous') ||
              args.containsKey('healthy') ||
              args.containsKey('productName'));

      // Если данные пришли из сохраненных сканирований или истории
      if (hasSavedAnalysisData) {
        setState(() {
          _analysisResult = _normalizeAnalysis(args!);
          _canSaveAnalysis = false;
          _isLoading = false;
        });
        return;
      }

      // Если мы пришли с камеры
      final imagePath = (args?['imagePath'] ?? '').toString();

      if (imagePath.isEmpty) {
        setState(() {
          _error = 'No image provided for analysis';
          _isLoading = false;
        });
        return;
      }

      _runAnalysis(imagePath);
    }
  }

  Map<String, dynamic> _normalizeAnalysis(Map<String, dynamic> data) {
    return {
      'productName': (data['productName'] ?? 'Unknown Product').toString(),
      'weight': (data['weight'] ?? '--').toString(),
      'calories': (data['calories'] ?? '--').toString(),
      'status': (data['status'] ?? 'CHECK').toString(),
      'dangerous': _toStringList(data['dangerous']),
      'healthy': _toStringList(data['healthy']),
      'ingredients': _toStringList(data['ingredients']),
    };
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  bool _isRetryableGeminiError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('503') ||
        text.contains('unavailable') ||
        text.contains('high demand') ||
        text.contains('try again later');
  }

  Future<GenerateContentResponse> _generateWithRetry(List<Part> parts) async {
    const models = <String>[
      'gemini-2.5-flash',
      'gemini-1.5-flash',
    ];
    Object? lastError;

    for (final modelName in models) {
      final model = GenerativeModel(
        model: modelName,
        apiKey: _geminiApiKey,
      );

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          return await model.generateContent([Content.multi(parts)]);
        } catch (e) {
          lastError = e;
          final isLastAttempt = attempt == 2;
          if (_isRetryableGeminiError(e) && !isLastAttempt) {
            await Future.delayed(Duration(seconds: 1 + attempt * 2));
            continue;
          }
          break;
        }
      }
    }

    throw lastError ?? Exception('AI analysis failed');
  }

  Future<void> _saveAnalysis() async {
    if (_analysisResult == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save this analysis')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_scans')
          .add({
        ..._analysisResult!,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis saved successfully! 🍏'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamed(context, '/saved');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save analysis: $e')),
        );
      }
    }
  }

  Future<void> _runAnalysis(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      if (_geminiApiKey.isEmpty) {
        throw Exception(
          'Missing GEMINI_API_KEY. Run with --dart-define=GEMINI_API_KEY=...',
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      String allergiesText = 'No known allergies';
      if (user != null && !user.isAnonymous) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() ?? {};
        final allergiesRaw = userData['allergies'];
        if (allergiesRaw is List) {
          final allergies = allergiesRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (allergies.isNotEmpty) {
            allergiesText = allergies.join(', ');
          }
        }
      }

      final response = await _generateWithRetry([
        TextPart('''
Analyze this food package image.
User allergies: $allergiesText

Tasks:
1) Extract and clean product label text.
2) Identify product name, weight and calories if present.
3) Check for allergens and risky additives.
4) Mark status as SAFE TO CONSUME or DANGER.

Return ONLY valid JSON in English:
{
  "productName": "Product name",
  "weight": "Weight or --",
  "calories": "Calories or --",
  "status": "SAFE TO CONSUME or DANGER",
  "dangerous": ["risky additives or allergens"],
  "healthy": ["beneficial ingredients"],
  "ingredients": ["full cleaned ingredient list"]
}
'''),
        DataPart('image/jpeg', bytes),
      ]);
      final raw = response.text ?? '';
      final cleanJson = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(cleanJson) as Map<String, dynamic>;

      setState(() {
        _analysisResult = _normalizeAnalysis(data);
        _canSaveAnalysis = true;
        _isLoading = false;
      });

      await _saveToHistory();
    } catch (e) {
      final friendlyError = _isRetryableGeminiError(e)
          ? 'AI service is temporarily busy. Please try again in a few seconds.'
          : 'Error during analysis: $e';
      setState(() {
        _error = friendlyError;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToHistory() async {
    if (_analysisResult == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scan_history')
          .add({
        ..._analysisResult!,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("History save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF10B981)),
              SizedBox(height: 20),
              Text('Analyzing ingredients with AI...'),
            ],
          ),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: BackButton(color: Colors.black)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }

    final data = _analysisResult!;
    final bool isSafe = data['status'].toString().toUpperCase().contains('SAFE');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black, onPressed: () => Navigator.pop(context)),
        title: const Text("Product Analysis", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['productName'] ?? 'Product',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            
            _buildStatusBanner(isSafe, isSafe ? "SAFE TO CONSUME" : "WARNING / DANGER"),
            
            const SizedBox(height: 24),
            Row(
              children: [
                _metricCard("Weight", data['weight'] ?? "--"),
                const SizedBox(width: 12),
                _metricCard("Calories", data['calories'] ?? "--"),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildList("Risky ingredients & allergens", data['dangerous'], Colors.red),
            _buildList("Beneficial ingredients", data['healthy'], Colors.green),
            
            const SizedBox(height: 10),
            const Text(
              "Full ingredients",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                (data['ingredients'] as List).join(', '),
                style: const TextStyle(height: 1.5, fontSize: 16),
              ),
            ),

            const SizedBox(height: 40),
            
            if (_canSaveAnalysis) ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAnalysis, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'Save Analysis', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isSafe, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(isSafe ? Icons.check_circle : Icons.warning, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String title, dynamic items, Color color) {
    final list = items as List;
    final icon = color == Colors.red ? Icons.warning_amber_rounded : Icons.check_circle;
    final accent = color == Colors.red ? const Color(0xFFB91C1C) : const Color(0xFF166534);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              color == Colors.red
                  ? 'No risky ingredients detected.'
                  : 'No beneficial ingredients detected.',
              style: const TextStyle(color: Colors.black54),
            ),
          )
        else
          Column(
            children: list.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final text = entry.value.toString();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 16, height: 1.35),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}