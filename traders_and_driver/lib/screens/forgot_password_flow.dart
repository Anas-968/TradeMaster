import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordFlowPage extends StatefulWidget {
  const ForgotPasswordFlowPage({super.key});

  @override
  State<ForgotPasswordFlowPage> createState() => _ForgotPasswordFlowPageState();
}

class _ForgotPasswordFlowPageState extends State<ForgotPasswordFlowPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _currentPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) return '+968$digits';
    if (digits.startsWith('968') && digits.length == 11) return '+$digits';
    if (raw.startsWith('+')) return raw;
    return '+$digits';
  }

  bool _isStrongPassword(String password) {
    return RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{6,}$',
    ).hasMatch(password);
  }

  String _resetErrorMessage(Object error, {required bool isOtpStep}) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (error.statusCode == '429' || message.contains('rate limit')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (isOtpStep &&
          (message.contains('token') ||
              message.contains('otp') ||
              message.contains('expired'))) {
        return 'That verification code is invalid or has expired.';
      }
    }
    return isOtpStep
        ? 'We could not reset your password. Please try again.'
        : 'We could not send a code. Check the phone number and try again.';
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final formatted = _formatPhoneNumber(_phoneController.text.trim());
      _currentPhone = formatted;
      await Supabase.instance.client.auth.signInWithOtp(phone: formatted);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OTP sent to $formatted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_resetErrorMessage(e, isOtpStep: false))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndReset() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter OTP')));
      return;
    }
    if (_newPasswordController.text.isEmpty ||
        !_isStrongPassword(_newPasswordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 6 characters and include uppercase, lowercase, and a special character.',
          ),
        ),
      );
      return;
    }
    if (_newPasswordController.text != _confirmController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Verify OTP (this will sign in the user)
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: _currentPhone!,
        token: _otpController.text.trim(),
        type: OtpType.sms,
      );
      if (!mounted) return;

      if (response.user != null) {
        // Update password for the signed-in user
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _newPasswordController.text.trim()),
        );
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password updated. Please login with your new password.',
            ),
          ),
        );
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Verification failed')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_resetErrorMessage(e, isOtpStep: true))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Forgot Password',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _otpSent ? _buildOtpView() : _buildPhoneView(),
        ),
      ),
    );
  }

  Widget _buildPhoneView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: Color(0xFF1A237E),
            ),
            hintText: 'Enter your phone',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Send OTP',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter OTP',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '000000',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'New Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF1A237E),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            hintText: 'Enter new password',
            helperText:
                '6+ characters, uppercase, lowercase, and special character',
            helperMaxLines: 2,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Confirm Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF1A237E),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            hintText: 'Confirm new password',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyAndReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Reset Password',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
