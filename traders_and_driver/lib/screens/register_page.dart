import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpSent = false;
  String? _selectedUserType;
  String? _currentPhoneNumber;

  final List<String> _userTypes = ['Trader', 'Driver'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Format phone number to E.164 (Oman: 8 digits -> +968XXXXXXXX)
  String _formatPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      return '+968$digits';
    } else if (digits.startsWith('968') && digits.length == 11) {
      return '+$digits';
    } else if (raw.startsWith('+')) {
      return raw;
    } else {
      return '+$digits';
    }
  }

  // Step 1: Send OTP to verify phone number
  Future<void> _sendOtp() async {
    // Validate all fields before sending OTP
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select user type')),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (password != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedPhone = _formatPhoneNumber(phone);
      _currentPhoneNumber = formattedPhone;

      // Send OTP via Supabase Phone Auth
      await Supabase.instance.client.auth.signInWithOtp(
        phone: formattedPhone,
        data: {
          'full_name': _fullNameController.text.trim(),
          'user_type': _selectedUserType,
        },
      );

      setState(() {
        _otpSent = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to $formattedPhone')),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: ${error.toString()}')),
        );
      }
    }
  }

  // Step 2: Verify OTP and complete registration
  Future<void> _verifyOtpAndRegister() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verify OTP with Supabase - this creates/authenticates the user
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: _currentPhoneNumber!,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user != null) {
        // User is now authenticated via phone
        // Now we need to set their password and update metadata
        // Note: Supabase phone auth users don't have passwords by default
        // We need to update the user with password and metadata

        // Update user metadata and set password
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            password: _passwordController.text,
            data: {
              'full_name': _fullNameController.text.trim(),
              'user_type': _selectedUserType,
              'phone_verified': true,
            },
          ),
        );

        // Sign out after registration so user can login with phone+password
        await Supabase.instance.client.auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.')),
          );
          Navigator.pop(context); // back to login
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.phone_android, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text('Create Account', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    const SizedBox(height: 8),
                    Text('Register with your phone number', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_otpSent) ...[
                      // Full Name
                      Text('Full Name', style: _labelStyle()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: _inputDecoration('Enter your full name', Icons.person_outline),
                        validator: (v) => v == null || v.isEmpty ? 'Full name required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Phone Number
                      Text('Phone Number', style: _labelStyle()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('e.g., 12345678 (Oman)', Icons.phone_outlined),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Phone number required';
                          String digits = value.replaceAll(RegExp(r'\D'), '');
                          if (digits.length == 8) return null;
                          return 'Enter 8 digits (Oman phone number)';
                        },
                      ),
                      const SizedBox(height: 20),

                      // User Type
                      Text('User Type', style: _labelStyle()),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonFormField<String>(
                          value: _selectedUserType,
                          hint: Text('Select user type', style: GoogleFonts.poppins(color: Colors.grey[400])),
                          items: _userTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                          onChanged: (v) => setState(() => _selectedUserType = v),
                          validator: (v) => v == null ? 'Select user type' : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password
                      Text('Create Password', style: _labelStyle()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration('Password (min 6 characters)', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[500]),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      Text('Confirm Password', style: _labelStyle()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: _inputDecoration('Confirm your password', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[500]),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Send OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          style: _buttonStyle(),
                          child: _isLoading
                              ? _loader()
                              : Text('Send OTP', style: _buttonTextStyle()),
                        ),
                      ),
                    ],

                    if (_otpSent) ...[
                      // OTP Verification Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.sms, size: 48, color: Colors.green),
                            const SizedBox(height: 12),
                            Text(
                              'OTP Sent!',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'We sent a verification code to $_currentPhoneNumber',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text('Enter OTP', style: _labelStyle()),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: GoogleFonts.poppins(fontSize: 24, color: Colors.grey[300]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtpAndRegister,
                          style: _buttonStyle(),
                          child: _isLoading
                              ? _loader()
                              : Text('Verify & Register', style: _buttonTextStyle()),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Resend OTP
                      TextButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: Text('Resend Code', style: GoogleFonts.poppins(color: const Color(0xFF1A237E))),
                      ),

                      // Back to edit
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _otpSent = false;
                            _otpController.clear();
                          });
                        },
                        child: Text('Edit Phone Number', style: GoogleFonts.poppins(color: Colors.grey[600])),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ", style: GoogleFonts.poppins(color: Colors.grey[600])),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Login', style: GoogleFonts.poppins(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  TextStyle _labelStyle() => GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: const Color(0xFF1A237E)
  );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
  );

  ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1A237E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
  );

  TextStyle _buttonTextStyle() => GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white
  );

  Widget _loader() => const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
  );
}