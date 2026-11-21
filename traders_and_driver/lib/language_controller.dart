import 'package:flutter/material.dart';

/// App-wide English/Arabic language selection.
class AppLanguageController extends ChangeNotifier {
  AppLanguageController._();

  static final AppLanguageController instance = AppLanguageController._();

  bool isArabic = false;

  Locale get locale => Locale(isArabic ? 'ar' : 'en');
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  void toggle() {
    isArabic = !isArabic;
    notifyListeners();
  }
}

/// Translations for the app's welcome, account, and common dashboard labels.
String appText(String english) {
  if (!AppLanguageController.instance.isArabic) return english;
  const arabic = <String, String>{
    'TradeMaster': '\u{62a}\u{631}\u{64a}\u{62f} \u{645}\u{627}\u{633}\u{62a}\u{631}',
    'Connect & Trade': '\u{62a}\u{648}\u{627}\u{635}\u{644} \u{648}\u{62a}\u{627}\u{62c}\u{631}',
    'Welcome To TradeMaster': '\u{645}\u{631}\u{62d}\u{628}\u{627}\u{64b} \u{628}\u{643} \u{641}\u{64a} \u{62a}\u{631}\u{64a}\u{62f} \u{645}\u{627}\u{633}\u{62a}\u{631}',
    'Your platform for seamless trading between traders and drivers': '\u{645}\u{646}\u{635}\u{62a}\u{643} \u{644}\u{644}\u{62a}\u{62f}\u{627}\u{648}\u{644} \u{627}\u{644}\u{633}\u{644}\u{633} \u{628}\u{64a}\u{646} \u{627}\u{644}\u{62a}\u{62c}\u{627}\u{631} \u{648}\u{627}\u{644}\u{633}\u{627}\u{626}\u{642}\u{64a}\u{646}',
    'For Traders': '\u{644}\u{644}\u{62a}\u{62c}\u{627}\u{631}',
    'Post your products and find reliable drivers': '\u{627}\u{639}\u{631}\u{636} \u{645}\u{646}\u{62a}\u{62c}\u{627}\u{62a}\u{643} \u{648}\u{627}\u{639}\u{62b}\u{631} \u{639}\u{644}\u{649} \u{633}\u{627}\u{626}\u{642}\u{64a}\u{646} \u{645}\u{648}\u{62b}\u{648}\u{642}\u{64a}\u{646}',
    'For Drivers': '\u{644}\u{644}\u{633}\u{627}\u{626}\u{642}\u{64a}\u{646}',
    'Find loads and earn money': '\u{627}\u{639}\u{62b}\u{631} \u{639}\u{644}\u{649} \u{62d}\u{645}\u{648}\u{644}\u{627}\u{62a} \u{648}\u{627}\u{643}\u{633}\u{628} \u{627}\u{644}\u{645}\u{627}\u{644}',
    'Secure Transactions': '\u{645}\u{639}\u{627}\u{645}\u{644}\u{627}\u{62a} \u{622}\u{645}\u{646}\u{629}',
    'Safe and verified trading': '\u{62a}\u{62f}\u{627}\u{648}\u{644} \u{622}\u{645}\u{646} \u{648}\u{645}\u{648}\u{62b}\u{648}\u{642}',
    'Login': '\u{62a}\u{633}\u{62c}\u{64a}\u{644} \u{627}\u{644}\u{62f}\u{62e}\u{648}\u{644}',
    'Register': '\u{625}\u{646}\u{634}\u{627}\u{621} \u{62d}\u{633}\u{627}\u{628}',
    'Live Chat Support': '\u{627}\u{644}\u{62f}\u{639}\u{645} \u{627}\u{644}\u{645}\u{628}\u{627}\u{634}\u{631}',
    'Switch to English': '\u{627}\u{644}\u{62a}\u{628}\u{62f}\u{64a}\u{644} \u{625}\u{644}\u{649} \u{627}\u{644}\u{625}\u{646}\u{62c}\u{644}\u{64a}\u{632}\u{64a}\u{629}',
    'Switch to Arabic': '\u{627}\u{644}\u{62a}\u{628}\u{62f}\u{64a}\u{644} \u{625}\u{644}\u{649} \u{627}\u{644}\u{639}\u{631}\u{628}\u{64a}\u{629}',
    'Switch to light mode': '\u{627}\u{644}\u{62a}\u{628}\u{62f}\u{64a}\u{644} \u{625}\u{644}\u{649} \u{627}\u{644}\u{648}\u{636}\u{639} \u{627}\u{644}\u{641}\u{627}\u{62a}\u{62d}',
    'Switch to dark mode': '\u{627}\u{644}\u{62a}\u{628}\u{62f}\u{64a}\u{644} \u{625}\u{644}\u{649} \u{627}\u{644}\u{648}\u{636}\u{639} \u{627}\u{644}\u{62f}\u{627}\u{643}\u{646}',
    'Cancel': '\u{625}\u{644}\u{63a}\u{627}\u{621}',
    'Save': '\u{62d}\u{641}\u{638}',
    'Close': '\u{625}\u{63a}\u{644}\u{627}\u{642}',
    'Delete': '\u{62d}\u{630}\u{641}',
    'Edit': '\u{62a}\u{639}\u{62f}\u{64a}\u{644}',
    'Retry': '\u{625}\u{639}\u{627}\u{62f}\u{629} \u{627}\u{644}\u{645}\u{62d}\u{627}\u{648}\u{644}\u{629}',
    'Send': '\u{625}\u{631}\u{633}\u{627}\u{644}',
    'Password': '\u{643}\u{644}\u{645}\u{629} \u{627}\u{644}\u{645}\u{631}\u{648}\u{631}',
    'Phone Number': '\u{631}\u{642}\u{645} \u{627}\u{644}\u{647}\u{627}\u{62a}\u{641}',
    'Full Name': '\u{627}\u{644}\u{627}\u{633}\u{645} \u{627}\u{644}\u{643}\u{627}\u{645}\u{644}',
    'Forgot Password?': '\u{647}\u{644} \u{646}\u{633}\u{64a}\u{62a} \u{643}\u{644}\u{645}\u{629} \u{627}\u{644}\u{645}\u{631}\u{648}\u{631}\u{61f}',
    'Create Account': '\u{625}\u{646}\u{634}\u{627}\u{621} \u{62d}\u{633}\u{627}\u{628}',
    'Trader': '\u{62a}\u{627}\u{62c}\u{631}',
    'Driver': '\u{633}\u{627}\u{626}\u{642}',
    'Admin': '\u{645}\u{634}\u{631}\u{641}',
    'Logout': '\u{62a}\u{633}\u{62c}\u{64a}\u{644} \u{627}\u{644}\u{62e}\u{631}\u{648}\u{62c}',
    'Enter your phone number': '\u{623}\u{62f}\u{62e}\u{644} \u{631}\u{642}\u{645} \u{647}\u{627}\u{62a}\u{641}\u{643}',
    'Enter your password': '\u{623}\u{62f}\u{62e}\u{644} \u{643}\u{644}\u{645}\u{629} \u{627}\u{644}\u{645}\u{631}\u{648}\u{631}',
    'Create Password': '\u{625}\u{646}\u{634}\u{627}\u{621} \u{643}\u{644}\u{645}\u{629} \u{645}\u{631}\u{648}\u{631}',
    'Confirm Password': '\u{62a}\u{623}\u{643}\u{64a}\u{62f} \u{643}\u{644}\u{645}\u{629} \u{627}\u{644}\u{645}\u{631}\u{648}\u{631}',
    'Send OTP': '\u{625}\u{631}\u{633}\u{627}\u{644} \u{631}\u{645}\u{632} \u{627}\u{644}\u{62a}\u{62d}\u{642}\u{642}',
    'User Type': '\u{646}\u{648}\u{639} \u{627}\u{644}\u{645}\u{633}\u{62a}\u{62e}\u{62f}\u{645}',
    'Please enter your full name': '\u{64a}\u{631}\u{62c}\u{649} \u{625}\u{62f}\u{62e}\u{627}\u{644} \u{627}\u{633}\u{645}\u{643} \u{627}\u{644}\u{643}\u{627}\u{645}\u{644}',
    'Please select user type': '\u{64a}\u{631}\u{62c}\u{649} \u{627}\u{62e}\u{62a}\u{64a}\u{627}\u{631} \u{646}\u{648}\u{639} \u{627}\u{644}\u{645}\u{633}\u{62a}\u{62e}\u{62f}\u{645}',
    'Please enter phone number': '\u{64a}\u{631}\u{62c}\u{649} \u{625}\u{62f}\u{62e}\u{627}\u{644} \u{631}\u{642}\u{645} \u{627}\u{644}\u{647}\u{627}\u{62a}\u{641}',
    'Passwords do not match': '\u{643}\u{644}\u{645}\u{62a}\u{627} \u{627}\u{644}\u{645}\u{631}\u{648}\u{631} \u{63a}\u{64a}\u{631} \u{645}\u{62a}\u{637}\u{627}\u{628}\u{642}\u{62a}\u{64a}\u{646}',
    'Please enter the OTP code': '\u{64a}\u{631}\u{62c}\u{649} \u{625}\u{62f}\u{62e}\u{627}\u{644} \u{631}\u{645}\u{632} \u{627}\u{644}\u{62a}\u{62d}\u{642}\u{642}',
    'Registration successful! Please login.': '\u{62a}\u{645} \u{625}\u{646}\u{634}\u{627}\u{621} \u{627}\u{644}\u{62d}\u{633}\u{627}\u{628} \u{628}\u{646}\u{62c}\u{627}\u{62d}! \u{64a}\u{631}\u{62c}\u{649} \u{62a}\u{633}\u{62c}\u{64a}\u{644} \u{627}\u{644}\u{62f}\u{62e}\u{648}\u{644}.',
    'Sign in to view your dashboard.': '\u{633}\u{62c}\u{644} \u{627}\u{644}\u{62f}\u{62e}\u{648}\u{644} \u{644}\u{639}\u{631}\u{636} \u{644}\u{648}\u{62d}\u{629} \u{627}\u{644}\u{62a}\u{62d}\u{643}\u{645}.',
    'No active jobs.': '\u{644}\u{627} \u{62a}\u{648}\u{62c}\u{62f} \u{645}\u{647}\u{627}\u{645} \u{646}\u{634}\u{637}\u{629}.',
    'Could not load available jobs.': '\u{62a}\u{639}\u{630}\u{631} \u{62a}\u{62d}\u{645}\u{64a}\u{644} \u{627}\u{644}\u{645}\u{647}\u{627}\u{645} \u{627}\u{644}\u{645}\u{62a}\u{627}\u{62d}\u{629}.',
    'There are no available loads right now.': '\u{644}\u{627} \u{62a}\u{648}\u{62c}\u{62f} \u{62d}\u{645}\u{648}\u{644}\u{627}\u{62a} \u{645}\u{62a}\u{627}\u{62d}\u{629} \u{62d}\u{627}\u{644}\u{64a}\u{627}\u{64b}.',
    'View Details': '\u{639}\u{631}\u{636} \u{627}\u{644}\u{62a}\u{641}\u{627}\u{635}\u{64a}\u{644}',
    'Accept Order': '\u{642}\u{628}\u{648}\u{644} \u{627}\u{644}\u{637}\u{644}\u{628}',
    'Confirm delivery': '\u{62a}\u{623}\u{643}\u{64a}\u{62f} \u{627}\u{644}\u{62a}\u{633}\u{644}\u{64a}\u{645}',
    'Delivered': '\u{62a}\u{645} \u{627}\u{644}\u{62a}\u{633}\u{644}\u{64a}\u{645}',
    'Awaiting': '\u{642}\u{64a}\u{62f} \u{627}\u{644}\u{627}\u{646}\u{62a}\u{638}\u{627}\u{631}',
    'Accepted': '\u{645}\u{642}\u{628}\u{648}\u{644}',
    'My Jobs': '\u{645}\u{647}\u{627}\u{645}\u{64a}',
    'Driver Dashboard': '\u{644}\u{648}\u{62d}\u{629} \u{627}\u{644}\u{633}\u{627}\u{626}\u{642}',
    'Trader Dashboard': '\u{644}\u{648}\u{62d}\u{629} \u{627}\u{644}\u{62a}\u{627}\u{62c}\u{631}',
    'Admin Panel': '\u{644}\u{648}\u{62d}\u{629} \u{627}\u{644}\u{645}\u{634}\u{631}\u{641}',
    'Available Loads': '\u{627}\u{644}\u{62d}\u{645}\u{648}\u{644}\u{627}\u{62a} \u{627}\u{644}\u{645}\u{62a}\u{627}\u{62d}\u{629}',
    'Already accepted': '\u{62a}\u{645} \u{627}\u{644}\u{642}\u{628}\u{648}\u{644} \u{645}\u{633}\u{628}\u{642}\u{627}\u{64b}',
    'Enter your full name': '\u{623}\u{62f}\u{62e}\u{644} \u{627}\u{633}\u{645}\u{643} \u{627}\u{644}\u{643}\u{627}\u{645}\u{644}',
    'Select user type': '\u{627}\u{62e}\u{62a}\u{631} \u{646}\u{648}\u{639} \u{627}\u{644}\u{645}\u{633}\u{62a}\u{62e}\u{62f}\u{645}',
    'Register with your phone number': '\u{633}\u{62c}\u{644} \u{628}\u{627}\u{633}\u{62a}\u{62e}\u{62f}\u{627}\u{645} \u{631}\u{642}\u{645} \u{647}\u{627}\u{62a}\u{641}\u{643}',
    'Welcome Back!': '\u{645}\u{631}\u{62d}\u{628}\u{627}\u{64b} \u{628}\u{639}\u{648}\u{62f}\u{62a}\u{643}!',
    'Login to your account': '\u{633}\u{62c}\u{644} \u{627}\u{644}\u{62f}\u{62e}\u{648}\u{644} \u{625}\u{644}\u{649} \u{62d}\u{633}\u{627}\u{628}\u{643}',
    'Don\'t have an account? ': '\u{644}\u{64a}\u{633} \u{644}\u{62f}\u{64a}\u{643} \u{62d}\u{633}\u{627}\u{628}\u{61f} ',
    'Already have an account? ': '\u{644}\u{62f}\u{64a}\u{643} \u{62d}\u{633}\u{627}\u{628} \u{628}\u{627}\u{644}\u{641}\u{639}\u{644}\u{61f} ',
    'Confirm your password': '\u{623}\u{643}\u{62f} \u{643}\u{644}\u{645}\u{629} \u{627}\u{644}\u{645}\u{631}\u{648}\u{631}',
    'Enter OTP': '\u{623}\u{62f}\u{62e}\u{644} \u{631}\u{645}\u{632} \u{627}\u{644}\u{62a}\u{62d}\u{642}\u{642}',
    'Edit Phone Number': '\u{62a}\u{639}\u{62f}\u{64a}\u{644} \u{631}\u{642}\u{645} \u{627}\u{644}\u{647}\u{627}\u{62a}\u{641}',
    'OTP Sent!': '\u{62a}\u{645} \u{625}\u{631}\u{633}\u{627}\u{644} \u{631}\u{645}\u{632} \u{627}\u{644}\u{62a}\u{62d}\u{642}\u{642}!',
    'Order': '\u{637}\u{644}\u{628}',
    'Verify & Register': '\u{62a}\u{62d}\u{642}\u{642} \u{648}\u{625}\u{646}\u{634}\u{627}\u{621} \u{627}\u{644}\u{62d}\u{633}\u{627}\u{628}',
    'Resend Code': '\u{625}\u{639}\u{627}\u{62f}\u{629} \u{625}\u{631}\u{633}\u{627}\u{644} \u{627}\u{644}\u{631}\u{645}\u{632}',
    'Full name required': '\u{627}\u{644}\u{627}\u{633}\u{645} \u{627}\u{644}\u{643}\u{627}\u{645}\u{644} \u{645}\u{637}\u{644}\u{648}\u{628}',
    'Phone number required': '\u{631}\u{642}\u{645} \u{627}\u{644}\u{647}\u{627}\u{62a}\u{641} \u{645}\u{637}\u{644}\u{648}\u{628}',
    'Enter 8 digits (Oman phone number)': '\u{623}\u{62f}\u{62e}\u{644} \u{668} \u{623}\u{631}\u{642}\u{627}\u{645} (\u{631}\u{642}\u{645} \u{647}\u{627}\u{62a}\u{641} \u{639}\u{64f}\u{645}\u{627}\u{646}\u{64a})',
    'Password required': '\u{643}\u{644}\u{645}\u{629} \u{627}\u{644}\u{645}\u{631}\u{648}\u{631} \u{645}\u{637}\u{644}\u{648}\u{628}\u{629}',
    'Use uppercase, lowercase, and special char': '\u{627}\u{633}\u{62a}\u{62e}\u{62f}\u{645} \u{623}\u{62d}\u{631}\u{641}\u{627}\u{64b} \u{643}\u{628}\u{64a}\u{631}\u{629} \u{648}\u{635}\u{63a}\u{64a}\u{631}\u{629} \u{648}\u{631}\u{645}\u{632}\u{627}\u{64b} \u{62e}\u{627}\u{635}\u{627}\u{64b}',
  };
  return arabic[english] ?? english;
}

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLanguageController.instance.isArabic
        ? 'Switch to English'
        : '\u{0627}\u{0644}\u{062a}\u{0628}\u{062f}\u{064a}\u{0644} \u{0625}\u{0644}\u{0649} \u{0627}\u{0644}\u{0639}\u{0631}\u{0628}\u{064a}\u{0629}',
    onPressed: AppLanguageController.instance.toggle,
    icon: Text(
      AppLanguageController.instance.isArabic ? 'EN' : '\u{0639}',
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    ),
  );
}

