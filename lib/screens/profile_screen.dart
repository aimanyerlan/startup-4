import 'dart:io';

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
            if (currentFirstName.isEmpty &&
                currentLastName.isEmpty &&
                (user.displayName ?? '').trim().isNotEmpty) {
              final parts = user.displayName!
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((part) => part.isNotEmpty)
                  .toList();
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign Out?', style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'You will be signed out of your account',
                  style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
                    },
                    child: Text(
                      'SIGN OUT',
                      style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey.shade700),
                    ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo is unavailable for guest accounts')),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile photo')),
      );
      debugPrint('Profile photo update error: $e');
    }
  }

  void _showPhotoSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSavePhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSavePhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
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
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _showPhotoSourcePicker,
                        child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          gradient: LinearGradient(
                            colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipOval(
                                child: profileData['photoPath'] != null &&
                                        profileData['photoPath'].toString().isNotEmpty
                                    ? (kIsWeb
                                        ? Image.network(
                                            profileData['photoPath'],
                                            fit: BoxFit.cover,
                                            width: 80,
                                            height: 80,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildInitialsAvatar(),
                                          )
                                        : Image.file(
                                            File(profileData['photoPath']),
                                            fit: BoxFit.cover,
                                            width: 80,
                                            height: 80,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildInitialsAvatar(),
                                          ))
                                    : _buildInitialsAvatar(),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLoading
                                    ? 'Loading...'
                                    : ('${profileData['firstName']} ${profileData['lastName']}'.trim().isEmpty
                                        ? (FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
                                            ? FirebaseAuth.instance.currentUser!.displayName!.trim()
                                            : 'Not specified')
                                        : '${profileData['firstName']} ${profileData['lastName']}'.trim()),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.mail_outline, size: 20, color: Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profileData['email'],
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuItem(
              title: 'Personal Information',
              icon: Icons.info_outline,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserInformationScreen()),
                );
                _loadUserData();
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              title: 'Change Password',
              icon: Icons.lock_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showLogoutConfirmation,
                child: Text(
                  'SIGN OUT',
                  style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
