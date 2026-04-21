import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// 1. Подключаем проверку на Web платформу
import 'package:flutter/foundation.dart'; 
// 2. Подключаем Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileScreen({Key? key, required this.initialData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late String gender;
  late Map<String, TextEditingController> controllers;
  final ImagePicker _picker = ImagePicker();
  String? _photoPath;
  bool _isSaving = false; // Добавим индикатор загрузки

  @override
  void initState() {
    super.initState();
    gender = (widget.initialData['gender'] ?? 'male').toString();
    _photoPath = widget.initialData['photoPath']?.toString();
    controllers = {
      'firstName': TextEditingController(text: (widget.initialData['firstName'] ?? '').toString()),
      'lastName': TextEditingController(text: (widget.initialData['lastName'] ?? '').toString()),
      'email': TextEditingController(text: (widget.initialData['email'] ?? '').toString()),
      'phone': TextEditingController(text: (widget.initialData['phone'] ?? '').toString()),
      'birthday': TextEditingController(text: (widget.initialData['birthday'] ?? '').toString()),
      'location': TextEditingController(text: (widget.initialData['location'] ?? '').toString()),
    };
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (picked == null) return;

      setState(() {
        _photoPath = picked.path;
      });
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Плагин галереи не инициализирован. Перезапустите приложение полностью.'),
        ),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть галерею. Проверьте доступ к фото.')),
      );
    }
  }

  void _showPhotoActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Выбрать из галереи'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhotoFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Удалить фото', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _photoPath = null;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildInputField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Enter your $label',
            hintStyle: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: GoogleFonts.lato(fontSize: 12),
        ),
      ],
    );
  }

  // --- МАГИЯ СОХРАНЕНИЯ В БАЗУ ДАННЫХ ---
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    final updatedData = {
      'firstName': controllers['firstName']!.text,
      'lastName': controllers['lastName']!.text,
      'email': controllers['email']!.text,
      'phone': controllers['phone']!.text,
      'birthday': controllers['birthday']!.text,
      'location': controllers['location']!.text,
      'gender': gender,
      'photoPath': _photoPath,
    };

    try {
      // Сохраняем данные в Firestore, если пользователь не Гость
      if (user != null && !user.isAnonymous) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updatedData, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() => _isSaving = false);
        // Возвращаем данные на предыдущий экран, чтобы интерфейс обновился
        Navigator.pop(context, updatedData);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Update your information',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showPhotoActions,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: ClipOval(
                                        // ИСПРАВЛЕНА ОШИБКА IMAGE.FILE ДЛЯ WEB!
                                        child: _photoPath != null && _photoPath!.isNotEmpty
                                            ? (kIsWeb 
                                                ? Image.network(
                                                    _photoPath!,
                                                    fit: BoxFit.cover,
                                                    width: 84,
                                                    height: 84,
                                                  )
                                                : Image.file(
                                                    File(_photoPath!),
                                                    fit: BoxFit.cover,
                                                    width: 84,
                                                    height: 84,
                                                  ))
                                            : Center(
                                                child: Text(
                                                  '${controllers['firstName']!.text.isNotEmpty ? controllers['firstName']!.text[0] : 'J'}${controllers['lastName']!.text.isNotEmpty ? controllers['lastName']!.text[0] : 'D'}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade200, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите, чтобы изменить фото',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputField('First Name', Icons.person, controllers['firstName']!),
                    const SizedBox(height: 12),
                    _buildInputField('Last Name', Icons.person, controllers['lastName']!),
                    const SizedBox(height: 12),
                    _buildInputField('Email', Icons.mail_outline, controllers['email']!, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildInputField('Phone', Icons.phone, controllers['phone']!, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildInputField('Birthday', Icons.calendar_today, controllers['birthday']!),
                    const SizedBox(height: 12),
                    _buildInputField('Location', Icons.location_on, controllers['location']!),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ['male', 'female', 'other']
                              .map(
                                (g) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: GestureDetector(
                                      onTap: () => setState(() => gender = g),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: gender == g ? const Color(0xFF2ECC71) : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          g == 'male' ? 'Male' : g == 'female' ? 'Female' : 'Other',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.lato(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: gender == g ? Colors.white : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _saveChanges,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'SAVE CHANGES',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}