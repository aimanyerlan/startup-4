import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final String _apiKey = 'AIzaSyBjz9Zm2nyDX6-klMDA84Z1SSv00ZVgv1M'; 
  bool _isLoading = true;
  Map<String, dynamic>? _analysisResult;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_analysisResult == null && _error == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final rawText = args?['fullText'] ?? '';
      _runAnalysis(rawText);
    }
  }

  Future<void> _saveAnalysis() async {
    if (_analysisResult == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, войдите в аккаунт для сохранения')),
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
            content: Text('Анализ успешно сохранен! 🍏'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  Future<void> _runAnalysis(String text) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

      final prompt = """
      Ты — эксперт-нутрициолог. Проанализируй этот текст этикетки: "$text".
      Выдай ответ СТРОГО в формате JSON на русском:
      {
        "productName": "название",
        "weight": "вес",
        "calories": "ккал",
        "status": "SAFE или DANGER",
        "dangerous": ["вредное"],
        "healthy": ["полезное"],
        "ingredients": ["список через запятую"]
      }
      """;

      final response = await model.generateContent([Content.text(prompt)]);
      final cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      
      setState(() {
        _analysisResult = jsonDecode(cleanJson);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Ошибка: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    final data = _analysisResult!;
    final bool isSafe = data['status'].toString().toUpperCase().contains('SAFE');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black, onPressed: () => Navigator.pop(context)),
        title: const Text("Анализ продукта", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['productName'] ?? 'Продукт', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            _buildStatusBanner(isSafe, isSafe ? "БЕЗОПАСНО" : "ОПАСНО"),
            
            const SizedBox(height: 24),
            Row(
              children: [
                _metricCard("Вес", data['weight'] ?? "--"),
                const SizedBox(width: 12),
                _metricCard("Калории", data['calories'] ?? "--"),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildList("⚠️ Опасные добавки", data['dangerous'], Colors.red),
            _buildList("✅ Полезные вещества", data['healthy'], Colors.green),
            
            const SizedBox(height: 10),
            const Text("Состав:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text((data['ingredients'] as List).join(', ')),

            const SizedBox(height: 40),
            
            // ИСПРАВЛЕННАЯ КНОПКА
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
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String title, dynamic items, Color color) {
    final list = items as List;
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: list.map((e) => Chip(
            label: Text(e.toString()), 
            backgroundColor: color.withOpacity(0.1),
            side: BorderSide.none,
          )).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}