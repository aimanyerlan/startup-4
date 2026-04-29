import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/widgets/layout.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final TextEditingController price1Controller = TextEditingController();
  final TextEditingController weight1Controller = TextEditingController();
  final TextEditingController price2Controller = TextEditingController();
  final TextEditingController weight2Controller = TextEditingController();

  bool showResult = false;
  double perUnit1 = 0.0;
  double perUnit2 = 0.0;
  String better = '';

  bool _isValidNumericInput(String value) {
    final trimmed = value.trim();
    return RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed);
  }

  void handleCalculate() {
    FocusScope.of(context).unfocus(); 
    
    if (!_isValidNumericInput(price1Controller.text) ||
        !_isValidNumericInput(weight1Controller.text) ||
        !_isValidNumericInput(price2Controller.text) ||
        !_isValidNumericInput(weight2Controller.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter numbers only, for example 12 or 12.5')),
      );
      return;
    }

    final double? p1 = double.tryParse(price1Controller.text);
    final double? w1 = double.tryParse(weight1Controller.text);
    final double? p2 = double.tryParse(price2Controller.text);
    final double? w2 = double.tryParse(weight2Controller.text);

    if (p1 != null && w1 != null && w1 > 0 && p2 != null && w2 != null && w2 > 0) {
      setState(() {
        perUnit1 = p1 / w1;
        perUnit2 = p2 / w2;
        better = perUnit1 < perUnit2 ? 'Option A' : 'Option B';
        showResult = true;
      });
    }
  }

  @override
  void dispose() {
    price1Controller.dispose();
    weight1Controller.dispose();
    price2Controller.dispose();
    weight2Controller.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2ECC71)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  TextField _buildNumberField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: _inputDecoration(hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Layout(
        showNav: true,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.trending_up_rounded, color: Color(0xFF2ECC71), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COMPARISON',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Evaluate best value',
                                style: GoogleFonts.lato(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OPTION A', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildNumberField(controller: price1Controller, hint: 'Price')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildNumberField(controller: weight1Controller, hint: 'Weight')),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text('OPTION B', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildNumberField(controller: price2Controller, hint: 'Price')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildNumberField(controller: weight2Controller, hint: 'Weight')),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: handleCalculate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: const Text('Calculate Value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (showResult) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: const [
                            Icon(Icons.scale, color: Color(0xFF2ECC71)),
                            SizedBox(width: 8),
                            Text('Efficiency Result', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('A / Unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text('\$${perUnit1.toStringAsFixed(3)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('B / Unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                                    const SizedBox(height: 4),
                                    Text('\$${perUnit2.toStringAsFixed(3)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recommendation', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text('$better IS BETTER', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}