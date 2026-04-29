import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/widgets/bottom_nav.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY');
  static const Color _pageBg = Color(0xFFF9FAFB);
  static const Color _accentGreen = Color(0xFF2ECC71);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _cardBorder = Color(0xFFE5E7EB);
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
          _analysisResult = _normalizeAnalysis(args);
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

  bool _isModelUnavailableError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('not found for api version') ||
        text.contains('is not supported for generatecontent') ||
        text.contains('model not found');
  }

  Exception _wrapGeminiFailure(Object? lastError) {
    if (lastError == null) return Exception('AI analysis failed');
    if (lastError is InvalidApiKey) {
      return Exception(
        'Invalid Gemini API key. Create a key at Google AI Studio '
        '(https://aistudio.google.com/apikey) and run with '
        '--dart-define=GEMINI_API_KEY=your_key. Do not use the Firebase '
        'Android/iOS client key from google-services.json.',
      );
    }
    final msg = lastError.toString();
    if (_isModelUnavailableError(lastError)) {
      return Exception(
        'No Gemini model responded for this key. Use a Google AI Studio API key '
        '(Generative Language API), or check region restrictions. Technical: $msg',
      );
    }
    return Exception(msg);
  }

  Future<GenerateContentResponse> _generateWithRetry(List<Part> parts) async {
    const apiVersions = ['v1', 'v1beta'];
    const modelNames = <String>[
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-pro',
      'gemini-1.0-pro',
    ];
    Object? lastError;

    for (final apiVersion in apiVersions) {
      for (final modelName in modelNames) {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _geminiApiKey,
          requestOptions: RequestOptions(apiVersion: apiVersion),
        );

        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            return await model.generateContent([Content.multi(parts)]);
          } catch (e) {
            lastError = e;
            if (_isModelUnavailableError(e)) {
              break;
            }
            final isLastAttempt = attempt == 2;
            if (_isRetryableGeminiError(e) && !isLastAttempt) {
              await Future.delayed(Duration(seconds: 1 + attempt * 2));
              continue;
            }
            break;
          }
        }
      }
    }

    throw _wrapGeminiFailure(lastError);
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
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {'tab': BottomNavBar.savedTabIndex},
        );
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
    final dangerous = data['dangerous'] as List;
    final healthy = data['healthy'] as List;
    final ingredients = data['ingredients'] as List;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accentGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                color: _accentGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCAN RESULT',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Read top to bottom — it is quick',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVerdictSection(isSafe),
            const SizedBox(height: 16),
            _buildProductCard(data),
            const SizedBox(height: 16),
            _buildNumberedSectionCard(
              step: 1,
              title: 'Things to double-check',
              hint:
                  'Allergens and additives the AI noticed. Always compare with the real package.',
              icon: Icons.visibility_rounded,
              iconColor: _danger,
              items: dangerous,
              emptyMessage:
                  'Nothing risky was highlighted. Still check the label if you have allergies.',
              itemTint: _danger,
            ),
            const SizedBox(height: 16),
            _buildNumberedSectionCard(
              step: 2,
              title: 'Possible positives',
              hint: 'Ingredients that are often seen as beneficial — not medical advice.',
              icon: Icons.eco_rounded,
              iconColor: const Color(0xFF15803D),
              items: healthy,
              emptyMessage: 'No “healthy highlights” were called out for this product.',
              itemTint: const Color(0xFF15803D),
            ),
            const SizedBox(height: 16),
            _buildIngredientsCard(ingredients),
            if (_canSaveAnalysis) ...[
              const SizedBox(height: 28),
              Text(
                'Like this breakdown? Save it to open later from the Saved tab.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveAnalysis,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Analysis',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildVerdictSection(bool isSafe) {
    final title = isSafe ? 'Looks OK to eat' : 'Use extra caution';
    final body = isSafe
        ? 'We did not flag major risks from this photo. If you have allergies, always verify on the physical package.'
        : 'The AI flagged possible allergens or additives. Read the real label and avoid the product if unsure.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSafe
              ? [
                  _accentGreen,
                  const Color(0xFF10B981),
                ]
              : [
                  const Color(0xFFEF4444),
                  const Color(0xFFDC2626),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isSafe ? _accentGreen : _danger).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VERDICT',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                isSafe ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data) {
    final name = data['productName']?.toString() ?? 'Product';
    final weight = data['weight']?.toString() ?? '--';
    final calories = data['calories']?.toString() ?? '--';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRODUCT',
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  Icons.scale_rounded,
                  'Weight',
                  weight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniStat(
                  Icons.local_fire_department_rounded,
                  'Energy',
                  calories,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _pageBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _accentGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

  Widget _buildNumberedSectionCard({
    required int step,
    required String title,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required List items,
    required String emptyMessage,
    required Color itemTint,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$step',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: iconColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hint,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              emptyMessage,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            )
          else
            Column(
              children: items.map<Widget>((raw) {
                final text = raw.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: itemTint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard(List ingredients) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '3',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full ingredient list',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Everything we could read from the label, one line per item.',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (ingredients.isEmpty)
            Text(
              'No ingredient list was extracted. Try a clearer photo of the ingredients block.',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            )
          else
            ...ingredients.map<Widget>((raw) {
              final text = raw.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _accentGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}