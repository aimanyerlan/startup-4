import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/screens/user_information_screen.dart';
import 'package:my_app/screens/change_password_screen.dart';
import 'package:my_app/widgets/layout.dart';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryGreen = const Color(0xFF2ECC71);
  bool isGuest = false;
  bool isLoading = true;
  String gender = 'male';

  final Map<String, dynamic> profileData = {
    'firstName': '',
    'lastName': '',
    'email': '',
    'phone': '',
    'birthday': '',
    'location': '',
    'gender': 'male',
    'photoPath': null,
  };
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    gender = profileData['gender'];

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.isAnonymous) {
        isGuest = true;
        isLoading = false;
        profileData['firstName'] = 'Guest';
        profileData['lastName'] = '';
        profileData['email'] = 'Anonymous account';
      } else {
        isGuest = false;
        profileData['email'] = user.email ?? 'No email';
        _loadUserData();
      }
    } else {
      isLoading = false;
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            final currentFirstName = (data['firstName'] ?? '').toString();
            final currentLastName = (data['lastName'] ?? '').toString();
            if (currentFirstName.isEmpty && currentLastName.isEmpty && (user.displayName ?? '').trim().isNotEmpty) {
              final parts = user.displayName!.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
              profileData['firstName'] = parts.isNotEmpty ? parts.first : '';
              profileData['lastName'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
            } else {
              profileData['firstName'] = currentFirstName;
              profileData['lastName'] = currentLastName;
            }
            profileData['phone'] = data['phone'] ?? '';
            profileData['birthday'] = data['birthday'] ?? '';
            profileData['location'] = data['location'] ?? '';
            profileData['gender'] = data['gender'] ?? 'male';
            profileData['photoPath'] = data['photoPath'];
            gender = profileData['gender'];
          });
        }
      } catch (e) {
        debugPrint("Profile loading error: $e");
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  String getInitials() {
    if (isLoading) return '';
    String first = profileData['firstName']?.isNotEmpty == true ? profileData['firstName'][0] : '';
    String last = profileData['lastName']?.isNotEmpty == true ? profileData['lastName'][0] : '';
    String initials = (first + last).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  void _showLogoutConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 24),
                Text('Sign Out?', style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 8),
                Text('Are you sure you want to log out of your account?', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
                    },
                    child: Text('YES, SIGN OUT', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey.shade700, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndSavePhoto(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo is unavailable for guest accounts')));
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
      if (pickedFile == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoPath': pickedFile.path,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        profileData['photoPath'] = pickedFile.path;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile photo')));
    }
  }

  void _showPhotoSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(Icons.photo_camera_rounded, color: primaryGreen),
                ),
                title: Text('Take a photo', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSavePhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                ),
                title: Text('Choose from gallery', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSavePhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              getInitials(),
              style: GoogleFonts.lato(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      showNav: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ШАПКА ---
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.black87, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manage your account', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey[600])),
                        Text('PROFILE', style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.black)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),

                // --- ПАРЯЩАЯ КАРТОЧКА ПОЛЬЗОВАТЕЛЯ ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _showPhotoSourcePicker,
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: primaryGreen.withOpacity(0.3), width: 4),
                                  boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2ECC71), Color(0xFF1ABC9C)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ClipOval(
                                  child: profileData['photoPath'] != null && profileData['photoPath'].toString().isNotEmpty
                                      ? (kIsWeb
                                          ? Image.network(profileData['photoPath'], fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildInitialsAvatar())
                                          : Image.file(File(profileData['photoPath']), fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildInitialsAvatar()))
                                      : _buildInitialsAvatar(),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isLoading 
                            ? 'Loading...' 
                            : ('${profileData['firstName']} ${profileData['lastName']}'.trim().isEmpty
                                ? (FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
                                    ? FirebaseAuth.instance.currentUser!.displayName!.trim()
                                    : 'Guest User')
                                : '${profileData['firstName']} ${profileData['lastName']}'.trim()),
                        style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isGuest ? Colors.grey.shade100 : primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          profileData['email'],
                          style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w700, color: isGuest ? Colors.grey.shade600 : primaryGreen),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text('SETTINGS', style: GoogleFonts.lato(letterSpacing: 1.2, color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),

                // --- МЕНЮ НАСТРОЕК ---
                if (!isGuest) ...[
                  _buildMenuItem(
                    title: 'Personal Information',
                    subtitle: 'Update your details',
                    icon: Icons.person_outline_rounded,
                    iconColor: Colors.blue,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const UserInformationScreen()));
                      _loadUserData();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    title: 'Change Password',
                    subtitle: 'Update security settings',
                    icon: Icons.lock_outline_rounded,
                    iconColor: Colors.purple,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                    },
                  ),
                  const SizedBox(height: 32),
                ],

                // --- КНОПКА ВЫХОДА ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGuest ? primaryGreen : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: isGuest ? Colors.transparent : Colors.red.withOpacity(0.3), width: 1.5),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isGuest ? () => Navigator.pushNamed(context, '/register') : _showLogoutConfirmation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isGuest ? Icons.app_registration_rounded : Icons.logout_rounded, color: isGuest ? Colors.white : Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          isGuest ? 'CREATE ACCOUNT' : 'SIGN OUT',
                          style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w900, color: isGuest ? Colors.white : Colors.red, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100), // Отступ для нижнего меню
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Обновленный дизайн элементов меню (как в iOS)
  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}