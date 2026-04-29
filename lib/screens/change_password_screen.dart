import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isObscureCurrentPassword = true;
  bool _isObscureNewPassword = true;
  bool _isObscureConfirmPassword = true;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null || user.isAnonymous) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guests cannot change passwords')),
        );
        setState(() => _isLoading = false);
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: _currentPasswordController.text
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully! 🔐'), 
            backgroundColor: Color(0xFF2ECC71)
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = 'Error changing password';
        if (e.code == 'invalid-credential') {
           errorMessage = 'Current password is incorrect';
        } else if (e.code == 'weak-password') {
           errorMessage = 'The new password is too weak';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade50,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Change Password',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Update your account password',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPasswordField(
            label: 'Current Password',
            controller: _currentPasswordController,
            isObscure: _isObscureCurrentPassword,
            onToggleVisibility: () => setState(
              () => _isObscureCurrentPassword = !_isObscureCurrentPassword,
            ),
          ),
          const SizedBox(height: 16),

          _buildPasswordField(
            label: 'New Password',
            controller: _newPasswordController,
            isObscure: _isObscureNewPassword,
            onToggleVisibility: () => setState(
              () => _isObscureNewPassword = !_isObscureNewPassword,
            ),
          ),
          const SizedBox(height: 16),

          _buildPasswordField(
            label: 'Confirm New Password',
            controller: _confirmPasswordController,
            isObscure: _isObscureConfirmPassword,
            onToggleVisibility: () => setState(
              () => _isObscureConfirmPassword = !_isObscureConfirmPassword,
            ),
          ),
          const SizedBox(height: 20),

          _buildRequirementsBox(),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _handleSave,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Update Password',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
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
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              size: 18,
              color: Colors.grey.shade400,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: Colors.grey.shade400,
              ),
              onPressed: onToggleVisibility,
            ),
            hintText: 'Enter ${label.toLowerCase()}',
            hintStyle: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2ECC71),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: GoogleFonts.lato(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequirementItem('At least 8 characters long'),
              const SizedBox(height: 4),
              _buildRequirementItem('Contains uppercase and lowercase letters'),
              const SizedBox(height: 4),
              _buildRequirementItem('Contains at least one number'),
              const SizedBox(height: 4),
              _buildRequirementItem('Contains at least one special character'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: GoogleFonts.lato(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
