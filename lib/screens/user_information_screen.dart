import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  final RegExp _phoneRegex = RegExp(r'^\+7\d{10}$');
  final List<String> _kzCities = const [
    'Almaty',
    'Astana',
    'Shymkent',
    'Aktobe',
    'Karaganda',
    'Taraz',
    'Pavlodar',
    'Oskemen',
    'Semey',
    'Atyrau',
    'Kostanay',
    'Kyzylorda',
    'Uralsk',
    'Petropavl',
    'Aktau',
    'Turkistan',
    'Kokshetau',
    'Taldykorgan',
    'Ekibastuz',
    'Rudny',
    'Zhezkazgan',
  ];

  final List<Map<String, String>> _dietaryOptions = const [
    {
      'value': 'Standard',
      'title': 'Standard (with meat)',
      'subtitle': 'I have no dietary preferences',
    },
    {
      'value': 'Pescatarian',
      'title': 'Pescatarian',
      'subtitle': 'I eat seafood but not meat',
    },
    {
      'value': 'Vegetarian',
      'title': 'Vegetarian',
      'subtitle': "I don't eat meat or seafood",
    },
    {
      'value': 'Vegan',
      'title': 'Vegan',
      'subtitle': "I don't eat any animal products",
    },
  ];

  Map<String, dynamic> _userData = {
    'firstName': '',
    'lastName': '',
    'email': '',
    'phone': '',
    'birthday': '',
    'location': '',
    'gender': 'female',
    'dietaryPreference': 'Standard',
    'allergies': <String>[],
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
      if (firstName.isEmpty &&
          lastName.isEmpty &&
          (user.displayName ?? '').trim().isNotEmpty) {
        final parts = user.displayName!
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();
        firstName = parts.isNotEmpty ? parts.first : '';
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      final allergiesRaw = data['allergies'];
      final allergies = allergiesRaw is List
          ? allergiesRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
          : <String>[];

      final authEmail = user.email ?? '';
      if (authEmail.isNotEmpty && (data['email'] ?? '').toString().trim().isEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'email': authEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;
      setState(() {
        _userData = {
          ..._userData,
          'firstName': firstName,
          'lastName': lastName,
          'email': authEmail,
          'phone': (data['phone'] ?? '').toString(),
          'birthday': (data['birthday'] ?? '').toString(),
          'location': (data['location'] ?? '').toString(),
          'gender': (data['gender'] ?? 'female').toString(),
          'dietaryPreference': (data['dietaryPreference'] ?? 'Standard').toString(),
          'allergies': allergies,
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
            {
              ...patch,
              if (authEmail.isNotEmpty) 'email': authEmail,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
      if (!mounted) return;
      setState(() {
        patch.forEach((key, value) => _userData[key] = value);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _displayValue(String key) {
    final value = (_userData[key] ?? '').toString().trim();
    if (value.isEmpty) return 'enter';
    return value;
  }

  String _displayBirthday() {
    final value = (_userData['birthday'] ?? '').toString().trim();
    if (value.isEmpty) return 'enter';
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
    return 'enter';
  }

  String _displayDietary() {
    final current = (_userData['dietaryPreference'] ?? 'Standard').toString();
    final match = _dietaryOptions.firstWhere(
      (item) => item['value'] == current,
      orElse: () => _dietaryOptions.first,
    );
    return match['title'] ?? 'Standard (with meat)';
  }

  String _displayAllergiesShort() {
    final allergies = ((_userData['allergies'] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (allergies.isEmpty) return 'enter';
    return allergies.join(', ');
  }

  Future<void> _editSimpleField({
    required String title,
    required String keyName,
    String hint = '',
  }) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _SingleValueEditScreen(
          title: title,
          initialValue: (_userData[keyName] ?? '').toString(),
          hintText: hint,
        ),
      ),
    );
    if (result == null) return;
    if (result.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title is required'), backgroundColor: Colors.red),
      );
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
          title: 'Phone',
          initialValue: initialPhone,
          hintText: '+7XXXXXXXXXX',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
              if (digits.startsWith('7')) digits = digits.substring(1);
              if (digits.length > 10) digits = digits.substring(0, 10);
              final next = '+7$digits';
              return TextEditingValue(
                text: next,
                selection: TextSelection.collapsed(offset: next.length),
              );
            }),
          ],
        ),
      ),
    );

    if (result == null) return;
    if (!_phoneRegex.hasMatch(result.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone must start with +7 and contain 10 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _savePatch({'phone': result.trim()});
  }

  Future<void> _editBirthday() async {
    final now = DateTime.now();
    DateTime initialDate = DateTime(now.year - 18, 1, 1);
    final existing = (_userData['birthday'] ?? '').toString().trim();
    if (existing.isNotEmpty) {
      try {
        initialDate = DateFormat('dd.MM.yyyy').parseStrict(existing);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select birthday',
    );
    if (picked == null) return;
    await _savePatch({'birthday': DateFormat('dd.MM.yyyy').format(picked)});
  }

  Future<void> _selectOption({
    required String title,
    required String keyName,
    required List<String> options,
  }) async {
    final current = (_userData[keyName] ?? '').toString();
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...options.map(
              (option) => ListTile(
                title: Text(option),
                trailing: option == current
                    ? const Icon(Icons.check, color: Color(0xFF2ECC71))
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            ),
            const SizedBox(height: 8),
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
      MaterialPageRoute(
        builder: (_) => _CitySelectScreen(
          cities: _kzCities,
          selectedCity: (_userData['location'] ?? '').toString(),
        ),
      ),
    );
    if (selected == null) return;
    await _savePatch({'location': selected});
  }

  Future<void> _selectDietaryPreference() async {
    final current = (_userData['dietaryPreference'] ?? 'Standard').toString();
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Dietary Preference',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ..._dietaryOptions.map(
              (option) => ListTile(
                title: Text(option['title']!),
                subtitle: Text(option['subtitle']!),
                trailing: option['value'] == current
                    ? const Icon(Icons.check, color: Color(0xFF2ECC71))
                    : null,
                onTap: () => Navigator.pop(context, option['value']),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _savePatch({'dietaryPreference': selected});
  }

  Future<void> _editAllergies() async {
    final current = ((_userData['allergies'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => _AllergiesEditScreen(initialValues: current),
      ),
    );
    if (result == null) return;
    await _savePatch({'allergies': result});
  }

  Widget _buildRow({
    required String title,
    required String value,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, color: Color(0xFF263238)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 17, color: Color(0xFF757575)),
                ),
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFF2F4F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildRow(
                      title: 'First Name',
                      value: _displayValue('firstName'),
                      onTap: () => _editSimpleField(
                        title: 'First Name',
                        keyName: 'firstName',
                        hint: 'Enter first name',
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildRow(
                      title: 'Last Name',
                      value: _displayValue('lastName'),
                      onTap: () => _editSimpleField(
                        title: 'Last Name',
                        keyName: 'lastName',
                        hint: 'Enter last name',
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildRow(
                      title: 'Email',
                      value: _displayValue('email'),
                      showArrow: false,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildRow(
                      title: 'Phone',
                      value: _displayValue('phone'),
                      onTap: _editPhone,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildRow(
                      title: 'City / Region',
                      value: _displayValue('location'),
                      onTap: _selectCity,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildRow(
                      title: 'Sex',
                      value: _displayGender(),
                      onTap: () => _selectOption(
                        title: 'Select sex',
                        keyName: 'gender',
                        options: const ['male', 'female'],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildRow(
                      title: 'Dietary Preference',
                      value: _displayDietary(),
                      onTap: _selectDietaryPreference,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildRow(
                      title: 'Date of Birth',
                      value: _displayBirthday(),
                      onTap: _editBirthday,
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildRow(
                      title: 'Allergic',
                      value: _displayAllergiesShort(),
                      onTap: _editAllergies,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SingleValueEditScreen extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _SingleValueEditScreen({
    required this.title,
    required this.initialValue,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

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
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFF2F4F7),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              decoration: InputDecoration(
                hintText: widget.hintText,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _controller.text),
                child: const Text('Save'),
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

class _CitySelectScreen extends StatelessWidget {
  final List<String> cities;
  final String selectedCity;

  const _CitySelectScreen({
    required this.cities,
    required this.selectedCity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Select City'),
        backgroundColor: const Color(0xFFF2F4F7),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView.separated(
        itemCount: cities.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade300),
        itemBuilder: (context, index) {
          final city = cities[index];
          return ListTile(
            title: Text(city),
            trailing: city == selectedCity
                ? const Icon(Icons.check, color: Color(0xFF2ECC71))
                : null,
            onTap: () => Navigator.pop(context, city),
          );
        },
      ),
    );
  }
}

class _AllergiesEditScreenState extends State<_AllergiesEditScreen> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialValues
        .map((value) => TextEditingController(text: value))
        .toList();
    if (_controllers.isEmpty) {
      _controllers = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeRow(int index) {
    if (_controllers.length == 1) return;
    setState(() {
      final removed = _controllers.removeAt(index);
      removed.dispose();
    });
  }

  void _save() {
    final data = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Allergic'),
        backgroundColor: const Color(0xFFF2F4F7),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _controllers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[index],
                          decoration: InputDecoration(
                            hintText: 'Allergy ${index + 1}',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _controllers.length == 1 ? null : () => _removeRow(index),
                        icon: const Icon(Icons.remove_circle_outline),
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
                icon: const Icon(Icons.add),
                label: const Text('Add allergy'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}