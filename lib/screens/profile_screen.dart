import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_app/screens/user_information_screen.dart';
import 'package:my_app/screens/change_password_screen.dart';
import 'package:my_app/screens/edit_profile_screen.dart';
import 'package:my_app/widgets/layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isGuest = false;
  String gender = 'male';

  final Map<String, dynamic> profileData = {
    'firstName': 'John',
    'lastName': 'Doe',
    'email': 'john.doe@example.com',
    'phone': '+1 987 654 3210',
    'birthday': '15 May 1990',
    'location': 'Seattle, WA',
    'gender': 'male',
    'photoPath': null,
  };

  @override
  void initState() {
    super.initState();
    gender = profileData['gender'];
  }

  Future<void> _openEditProfileScreen() async {
    final updatedProfile = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialData: Map<String, dynamic>.from(profileData),
        ),
      ),
    );

    if (updatedProfile == null) return;

    setState(() {
      profileData['firstName'] = (updatedProfile['firstName'] ?? '').toString();
      profileData['lastName'] = (updatedProfile['lastName'] ?? '').toString();
      profileData['email'] = (updatedProfile['email'] ?? '').toString();
      profileData['phone'] = (updatedProfile['phone'] ?? '').toString();
      profileData['birthday'] = (updatedProfile['birthday'] ?? '').toString();
      profileData['location'] = (updatedProfile['location'] ?? '').toString();
      profileData['gender'] = (updatedProfile['gender'] ?? gender).toString();
      profileData['photoPath'] = updatedProfile['photoPath'];
      gender = profileData['gender'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
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
                Text(
                  'Sign Out?',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will be signed out of your account',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
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
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    },
                    child: Text(
                      'SIGN OUT',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
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
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade700,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 16),
            const Text(
              'Account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 32),

            // Account Card
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
                    // Avatar
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: profileData['photoPath'] != null
                              ? DecorationImage(
                                  image: FileImage(File(profileData['photoPath'])),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          gradient: profileData['photoPath'] == null
                              ? const LinearGradient(
                                  colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: profileData['photoPath'] == null
                            ? const Center(
                                child: Text(
                                  'JD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name
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
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${profileData['firstName']} ${profileData['lastName']}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email
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
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profileData['email'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
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

            // Menu Items
            _buildMenuItem(
              title: 'Personal Information',
              icon: Icons.info_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserInformationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              title: 'Change Password',
              icon: Icons.lock_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              title: 'Edit Profile',
              icon: Icons.edit_outlined,
              onTap: _openEditProfileScreen,
            ),
            const SizedBox(height: 32),

            // Logout Button
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
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
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
              child: Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
