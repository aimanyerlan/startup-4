import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInformationScreen extends StatefulWidget {
  const UserInformationScreen({super.key});

  @override
  State<UserInformationScreen> createState() => _UserInformationScreenState();
}

class _UserInformationScreenState extends State<UserInformationScreen> {
  bool _isLoading = true;

  // Данные по умолчанию (пока грузится Firebase)
  Map<String, dynamic> _userData = {
    'firstName': '',
    'lastName': '',
    'email': '',
    'phone': '',
    'birthday': '',
    'location': '',
    'photoPath': null,
    'creationTime': 'Unknown',
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.isAnonymous) {
        setState(() {
          _userData['firstName'] = 'Guest';
          _userData['email'] = 'Anonymous User';
          _userData['creationTime'] = 'Session started today';
          _isLoading = false;
        });
      } else {
        try {
          // Получаем дату создания аккаунта
          String creationDate = 'Unknown';
          if (user.metadata.creationTime != null) {
            creationDate = DateFormat('MMMM yyyy').format(user.metadata.creationTime!);
          }

          // Идем в базу данных
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          
          if (mounted) {
            setState(() {
              if (doc.exists && doc.data() != null) {
                final data = doc.data()!;
                _userData['firstName'] = data['firstName'] ?? '';
                _userData['lastName'] = data['lastName'] ?? '';
                _userData['phone'] = data['phone'] ?? 'Not set';
                _userData['birthday'] = data['birthday'] ?? 'Not set';
                _userData['location'] = data['location'] ?? 'Not set';
                _userData['photoPath'] = data['photoPath'];
              }
              _userData['email'] = user.email ?? 'No email';
              _userData['creationTime'] = creationDate;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String getInitials() {
    String first = _userData['firstName']?.isNotEmpty == true ? _userData['firstName'][0] : '';
    String last = _userData['lastName']?.isNotEmpty == true ? _userData['lastName'][0] : '';
    String initials = (first + last).toUpperCase();
    return initials.isEmpty ? '?' : initials;
  }

  // --- ДИНАМИЧЕСКИЙ СПИСОК ИНФОРМАЦИИ ---
  List<Map<String, dynamic>> get _userInfoList {
    return [
      {'icon': Icons.person, 'label': 'First Name', 'value': _userData['firstName'].toString().isEmpty ? 'Not set' : _userData['firstName']},
      {'icon': Icons.person, 'label': 'Last Name', 'value': _userData['lastName'].toString().isEmpty ? 'Not set' : _userData['lastName']},
      {'icon': Icons.mail_outline, 'label': 'Email', 'value': _userData['email']},
      {'icon': Icons.phone, 'label': 'Phone', 'value': _userData['phone']},
      {'icon': Icons.calendar_today, 'label': 'Birthday', 'value': _userData['birthday']},
      {'icon': Icons.location_on, 'label': 'Location', 'value': _userData['location']},
      {'icon': Icons.access_time, 'label': 'Member Since', 'value': _userData['creationTime']},
      {'icon': Icons.star, 'label': 'Membership Type', 'value': FirebaseAuth.instance.currentUser?.isAnonymous == true ? 'Guest' : 'Standard Member'},
    ];
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        getInitials(),
        style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71))) 
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildProfilePhotoSection(),
                  _buildUserInformationList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade50),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Information',
                      style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your profile details',
                      style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    final photoPath = _userData['photoPath'];
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipOval(
            child: photoPath != null && photoPath.toString().isNotEmpty
                ? (kIsWeb
                    ? Image.network(photoPath, fit: BoxFit.cover, width: 96, height: 96, errorBuilder: (c, e, s) => _buildInitialsAvatar())
                    : Image.file(File(photoPath), fit: BoxFit.cover, width: 96, height: 96, errorBuilder: (c, e, s) => _buildInitialsAvatar()))
                : _buildInitialsAvatar(),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInformationList() {
    final items = _userInfoList;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Icon(item['icon'], size: 20, color: Colors.grey.shade600)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['label'],
                          style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['value'].toString(),
                          style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}