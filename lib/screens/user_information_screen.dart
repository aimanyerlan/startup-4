import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  final Color primaryGreen = const Color(0xFF2ECC71);
  bool _isLoading = true;
  bool _isSaving = false;

  final RegExp _phoneRegex = RegExp(r'^\+7\d{10}$');
  final List<String> _kzCities = const [
    'Almaty', 'Astana', 'Shymkent', 'Aktobe', 'Karaganda', 'Taraz', 'Pavlodar',
    'Oskemen', 'Semey', 'Atyrau', 'Kostanay', 'Kyzylorda', 'Uralsk',
    'Petropavl', 'Aktau', 'Turkistan', 'Kokshetau', 'Taldykorgan',
    'Ekibastuz', 'Rudny', 'Zhezkazgan',
  ];

  final List<Map<String, String>> _dietaryOptions = const [
    {'value': 'Standard', 'title': 'Standard (with meat)', 'subtitle': 'I have no dietary preferences'},
    {'value': 'Pescatarian', 'title': 'Pescatarian', 'subtitle': 'I eat seafood but not meat'},
    {'value': 'Vegetarian', 'title': 'Vegetarian', 'subtitle': "I don't eat meat or seafood"},
    {'value': 'Vegan', 'title': 'Vegan', 'subtitle': "I don't eat any animal products"},
  ];

  Map<String, dynamic> _userData = {
    'firstName': '', 'lastName': '', 'email': '', 'phone': '',
    'birthday': '', 'location': '', 'gender': 'female',
    'dietaryPreference': 'Standard', 'allergies': <String>[],
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (user.isAnonymous) {
      setState(() {
        _userData['firstName'] = 'Guest';
        _userData['email'] = 'Anonymous user';
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? <String, dynamic>{};

      var firstName = (data['firstName'] ?? '').toString();
      var lastName = (data['lastName'] ?? '').toString();
      if (firstName.isEmpty && lastName.isEmpty && (user.displayName ?? '').trim().isNotEmpty) {
        final parts = user.displayName!.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
        firstName = parts.isNotEmpty ? parts.first : '';
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      final allergiesRaw = data['allergies'];
      final allergies = allergiesRaw is List ? allergiesRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() : <String>[];

      final authEmail = user.email ?? '';
      if (authEmail.isNotEmpty && (data['email'] ?? '').toString().trim().isEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'email': authEmail, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;
      setState(() {
        _userData = {
          ..._userData,
          'firstName': firstName, 'lastName': lastName, 'email': authEmail,
          'phone': (data['phone'] ?? '').toString(), 'birthday': (data['birthday'] ?? '').toString(),
          'location': (data['location'] ?? '').toString(), 'gender': (data['gender'] ?? 'female').toString(),
          'dietaryPreference': (data['dietaryPreference'] ?? 'Standard').toString(), 'allergies': allergies,
        };
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePatch(Map<String, dynamic> patch) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    setState(() => _isSaving = true);
    try {
      final authEmail = user.email ?? '';
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {...patch, if (authEmail.isNotEmpty) 'email': authEmail, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
      if (!mounted) return;
      setState(() {
        patch.forEach((key, value) => _userData[key] = value);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _displayValue(String key) {
    final value = (_userData[key] ?? '').toString().trim();
    if (value.isEmpty) return 'Not set';
    return value;
  }

  String _displayBirthday() {
    final value = (_userData['birthday'] ?? '').toString().trim();
    if (value.isEmpty) return 'Not set';
    try {
      final date = DateFormat('dd.MM.yyyy').parseStrict(value);
      return DateFormat('d MMMM yyyy').format(date);
    } catch (_) {
      return value;
    }
  }

  String _displayGender() {
    final value = (_userData['gender'] ?? '').toString();
    if (value == 'male') return 'Male';
    if (value == 'female') return 'Female';
    if (value == 'other') return 'Other';
    return 'Not set';
  }

  String _displayDietary() {
    final current = (_userData['dietaryPreference'] ?? 'Standard').toString();
    final match = _dietaryOptions.firstWhere((item) => item['value'] == current, orElse: () => _dietaryOptions.first);
    return match['title'] ?? 'Standard (with meat)';
  }

  String _displayAllergiesShort() {
    final allergies = ((_userData['allergies'] as List?) ?? const []).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    if (allergies.isEmpty) return 'None';
    return allergies.join(', ');
  }

  Future<void> _editSimpleField({required String title, required String keyName, String hint = ''}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _SingleValueEditScreen(title: title, initialValue: (_userData[keyName] ?? '').toString(), hintText: hint)),
    );
    if (result == null) return;
    if (result.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title is required'), backgroundColor: Colors.red));
      return;
    }
    await _savePatch({keyName: result.trim()});
  }

  Future<void> _editPhone() async {
    final existing = (_userData['phone'] ?? '').toString();
    final digitsOnly = existing.replaceAll(RegExp(r'\D'), '');
    final normalized = digitsOnly.startsWith('7') ? digitsOnly.substring(1) : digitsOnly;
    final initialPhone = '+7${normalized.length > 10 ? normalized.substring(0, 10) : normalized}';

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _SingleValueEditScreen(
          title: 'Phone Number',
          initialValue: initialPhone,
          hintText: '+7 (XXX) XXX-XXXX',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
              if (digits.startsWith('7')) digits = digits.substring(1);
              if (digits.length > 10) digits = digits.substring(0, 10);
              final next = '+7$digits';
              return TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
            }),
          ],
        ),
      ),
    );

    if (result == null) return;
    if (!_phoneRegex.hasMatch(result.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone must start with +7 and contain 10 digits'), backgroundColor: Colors.red));
      return;
    }
    await _savePatch({'phone': result.trim()});
  }

  Future<void> _editBirthday() async {
    final now = DateTime.now();
    DateTime initialDate = DateTime(now.year - 18, 1, 1);
    final existing = (_userData['birthday'] ?? '').toString().trim();
    if (existing.isNotEmpty) {
      try { initialDate = DateFormat('dd.MM.yyyy').parseStrict(existing); } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2ECC71), onPrimary: Colors.white, onSurface: Colors.black),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFF2ECC71))),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    await _savePatch({'birthday': DateFormat('dd.MM.yyyy').format(picked)});
  }

  Future<void> _selectOption({required String title, required String keyName, required List<String> options}) async {
    final current = (_userData[keyName] ?? '').toString();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ...options.map((option) {
              final isSelected = option == current;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: isSelected ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                title: Text(option.toUpperCase(), style: GoogleFonts.lato(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? primaryGreen : Colors.black87)),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: primaryGreen) : null,
                onTap: () => Navigator.pop(context, option),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _savePatch({keyName: selected});
  }

  Future<void> _selectCity() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _CitySelectScreen(cities: _kzCities, selectedCity: (_userData['location'] ?? '').toString())),
    );
    if (selected == null) return;
    await _savePatch({'location': selected});
  }

  Future<void> _selectDietaryPreference() async {
    final current = (_userData['dietaryPreference'] ?? 'Standard').toString();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text('Dietary Preference', style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ..._dietaryOptions.map((option) {
              final isSelected = option['value'] == current;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: isSelected ? primaryGreen.withOpacity(0.1) : Colors.transparent,
                title: Text(option['title']!, style: GoogleFonts.lato(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: isSelected ? primaryGreen : Colors.black87)),
                subtitle: Text(option['subtitle']!, style: GoogleFonts.lato(color: isSelected ? primaryGreen.withOpacity(0.7) : Colors.grey)),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: primaryGreen) : null,
                onTap: () => Navigator.pop(context, option['value']),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _savePatch({'dietaryPreference': selected});
  }

  Future<void> _editAllergies() async {
    final current = ((_userData['allergies'] as List?) ?? const []).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => _AllergiesEditScreen(initialValues: current)),
    );
    if (result == null) return;
    await _savePatch({'allergies': result});
  }

  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool showArrow = true,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(24)) : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600, color: value == 'Not set' || value == 'None' ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12),
          child: Text(title.toUpperCase(), style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Personal Info', style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2ECC71)))),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSection('General Information', [
                    _buildRow(icon: Icons.person_outline_rounded, iconColor: Colors.blue, title: 'First Name', value: _displayValue('firstName'), onTap: () => _editSimpleField(title: 'First Name', keyName: 'firstName', hint: 'Enter first name')),
                    _buildRow(icon: Icons.badge_outlined, iconColor: Colors.indigo, title: 'Last Name', value: _displayValue('lastName'), onTap: () => _editSimpleField(title: 'Last Name', keyName: 'lastName', hint: 'Enter last name')),
                    _buildRow(icon: Icons.email_outlined, iconColor: Colors.orange, title: 'Email', value: _displayValue('email'), showArrow: false),
                    _buildRow(icon: Icons.phone_outlined, iconColor: Colors.teal, title: 'Phone', value: _displayValue('phone'), onTap: _editPhone),
                    _buildRow(icon: Icons.cake_outlined, iconColor: Colors.pink, title: 'Date of Birth', value: _displayBirthday(), onTap: _editBirthday),
                    _buildRow(icon: Icons.wc_rounded, iconColor: Colors.purple, title: 'Sex', value: _displayGender(), onTap: () => _selectOption(title: 'Select Sex', keyName: 'gender', options: const ['male', 'female'])),
                    _buildRow(icon: Icons.location_on_outlined, iconColor: Colors.red, title: 'Region', value: _displayValue('location'), onTap: _selectCity, isLast: true),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  _buildSection('Health & Preferences', [
                    _buildRow(icon: Icons.restaurant_rounded, iconColor: primaryGreen, title: 'Dietary', value: _displayDietary(), onTap: _selectDietaryPreference),
                    _buildRow(icon: Icons.medical_information_outlined, iconColor: Colors.redAccent, title: 'Allergies', value: _displayAllergiesShort(), onTap: _editAllergies, isLast: true),
                  ]),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// --- SUB SCREENS ---

class _SingleValueEditScreen extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _SingleValueEditScreen({required this.title, required this.initialValue, required this.hintText, this.keyboardType = TextInputType.text, this.inputFormatters});

  @override
  State<_SingleValueEditScreen> createState() => _SingleValueEditScreenState();
}

class _SingleValueEditScreenState extends State<_SingleValueEditScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text(widget.title, style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: widget.hintText,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('SAVE CHANGES', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergiesEditScreen extends StatefulWidget {
  final List<String> initialValues;
  const _AllergiesEditScreen({required this.initialValues});
  @override
  State<_AllergiesEditScreen> createState() => _AllergiesEditScreenState();
}

class _AllergiesEditScreenState extends State<_AllergiesEditScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialValues.map((value) => TextEditingController(text: value)).toList();
    if (_controllers.isEmpty) _controllers = [TextEditingController()];
    _focusNodes = List.generate(_controllers.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _addRow() {
    final focusNode = FocusNode();
    setState(() {
      _controllers.add(TextEditingController());
      _focusNodes.add(focusNode);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  void _removeRow(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _focusNodes[index].dispose();
      _focusNodes.removeAt(index);
    });
  }

  void _save() {
    final data = _controllers.map((c) => c.text.trim()).where((text) => text.isNotEmpty).toList();
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text('Edit Allergies', style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _controllers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'e.g. Peanuts, Gluten',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: IconButton(
                          onPressed: () => _removeRow(index),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2ECC71)),
                label: Text('ADD ANOTHER', style: GoogleFonts.lato(fontWeight: FontWeight.w900, color: const Color(0xFF2ECC71))),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('SAVE ALLERGIES', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitySelectScreen extends StatelessWidget {
  final List<String> cities;
  final String selectedCity;

  const _CitySelectScreen({required this.cities, required this.selectedCity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text('Select Region', style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: ListView.separated(
          itemCount: cities.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) {
            final city = cities[index];
            final isSelected = city == selectedCity;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              title: Text(city, style: GoogleFonts.lato(fontSize: 16, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? const Color(0xFF2ECC71) : Colors.black87)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71)) : null,
              onTap: () => Navigator.pop(context, city),
            );
          },
        ),
      ),
    );
  }
}