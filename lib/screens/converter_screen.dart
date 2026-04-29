import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/widgets/layout.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _fromUnit = 'g';
  String _toUnit = 'kg';
  String _result = '';

  static const Map<String, double> conversionRates = {
    'g': 1,
    'kg': 1000,
    'ml': 1,
    'l': 1000,
    'cups': 240,
    'tbsp': 15,
    'tsp': 5,
  };

  final List<String> _units = [
    'g',
    'kg',
    'ml',
    'l',
    'cups',
    'tbsp',
    'tsp',
  ];

  static const Map<String, String> _unitNames = {
    'g': 'Grams (g)',
    'kg': 'Kilograms (kg)',
    'ml': 'Milliliters (ml)',
    'l': 'Liters (l)',
    'cups': 'Cups',
    'tbsp': 'Tablespoons (tbsp)',
    'tsp': 'Teaspoons (tsp)',
  };

  bool _isValidNumericInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed);
  }

  void _handleConvert() {
    if (!_isValidNumericInput(_amountController.text)) {
      setState(() {
        _result = '';
      });
      return;
    }

    final amt = double.tryParse(_amountController.text);
    if (amt != null && amt >= 0) {
      final fromValue = amt * conversionRates[_fromUnit]!;
      final toValue = fromValue / conversionRates[_toUnit]!;
      setState(() {
        _result = toValue.toStringAsFixed(2);
      });
    } else {
      setState(() {
        _result = '';
      });
    }
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

  DropdownButtonFormField<String> _unitDropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
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
      ),
      items: _units
          .map((u) => DropdownMenuItem<String>(
                value: u,
                child: Text(_unitNames[u] ?? u,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
                    const SizedBox(height: 8),
                    const Text(
                      'TRANSLATOR',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Unit Metric conversion',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
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
                    const Text(
                      'INPUT QUANTITY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: _inputDecoration('0.00'),
                      onChanged: (_) => _handleConvert(),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FROM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _unitDropdown(_fromUnit, (val) {
                                if (val != null) {
                                  setState(() => _fromUnit = val);
                                  _handleConvert();
                                }
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _unitDropdown(_toUnit, (val) {
                                if (val != null) {
                                  setState(() => _toUnit = val);
                                  _handleConvert();
                                }
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    if (_result.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _result,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _toUnit,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2ECC71),
                                letterSpacing: 1,
                                textBaseline: TextBaseline.alphabetic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      'STANDARDS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _refCard('1 Cup', '240 ml'),
                        _refCard('1 Tbsp', '15 ml'),
                        _refCard('1 Tsp', '5 ml'),
                        _refCard('1 Kg', '1000 g'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _refCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
