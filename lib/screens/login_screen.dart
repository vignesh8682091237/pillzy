import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

/// Login screen — collects Email and Date of Birth.
/// All UI text (labels, buttons, errors) is rendered in [languageCode].
class LoginScreen extends StatefulWidget {
  final String languageCode;
  const LoginScreen({super.key, this.languageCode = 'en'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isLoading = false;

  // ── Translations ──────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _t = {
    'en': {
      'heading': 'Welcome Back 👋',
      'subtitle': 'Enter your details to continue',
      'email': 'Email Address',
      'dob': 'Date of Birth (DD/MM/YYYY)',
      'continue_btn': 'Continue',
      'loading': 'Please wait...',
      'no_account': "Don't have an account? ",
      'signup': 'Sign Up',
      'email_required': 'Email is required.',
      'email_invalid': 'Enter a valid email address.',
      'dob_required': 'Date of birth is required.',
      'dob_format': 'Enter date as DD/MM/YYYY.',
      'dob_invalid': 'Enter a valid date.',
      'dob_future': 'Date of birth cannot be in the future.',
      'invalid_credentials': 'Invalid Email or Date of Birth.',
    },
    'hi': {
      'heading': 'वापस स्वागत है 👋',
      'subtitle': 'जारी रखने के लिए अपनी जानकारी दर्ज करें',
      'email': 'ईमेल पता',
      'dob': 'जन्म तिथि (DD/MM/YYYY)',
      'continue_btn': 'जारी रखें',
      'loading': 'कृपया प्रतीक्षा करें...',
      'no_account': 'खाता नहीं है? ',
      'signup': 'साइन अप करें',
      'email_required': 'ईमेल आवश्यक है।',
      'email_invalid': 'एक वैध ईमेल पता दर्ज करें।',
      'dob_required': 'जन्म तिथि आवश्यक है।',
      'dob_format': 'DD/MM/YYYY प्रारूप में दर्ज करें।',
      'dob_invalid': 'एक वैध तिथि दर्ज करें।',
      'dob_future': 'जन्म तिथि भविष्य में नहीं हो सकती।',
    },
    'ta': {
      'heading': 'மீண்டும் வரவேற்கிறோம் 👋',
      'subtitle': 'தொடர உங்கள் விவரங்களை உள்ளிடவும்',
      'email': 'மின்னஞ்சல் முகவரி',
      'dob': 'பிறந்த தேதி (DD/MM/YYYY)',
      'continue_btn': 'தொடர்க',
      'loading': 'தயவுசெய்து காத்திருங்கள்...',
      'no_account': 'கணக்கு இல்லையா? ',
      'signup': 'பதிவு செய்',
      'email_required': 'மின்னஞ்சல் தேவை.',
      'email_invalid': 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்.',
      'dob_required': 'பிறந்த தேதி தேவை.',
      'dob_format': 'DD/MM/YYYY வடிவத்தில் உள்ளிடவும்.',
      'dob_invalid': 'சரியான தேதியை உள்ளிடவும்.',
      'dob_future': 'பிறந்த தேதி எதிர்காலத்தில் இருக்க முடியாது.',
      'invalid_credentials': 'தவறான மின்னஞ்சல் அல்லது பிறந்த தேதி.',
    },
    'te': {
      'heading': 'మళ్ళీ స్వాగతం 👋',
      'subtitle': 'కొనసాగించడానికి మీ వివరాలు నమోదు చేయండి',
      'email': 'ఇమెయిల్ చిరునామా',
      'dob': 'పుట్టిన తేదీ (DD/MM/YYYY)',
      'continue_btn': 'కొనసాగించు',
      'loading': 'దయచేసి వేచి ఉండండి...',
      'no_account': 'ఖాతా లేదా? ',
      'signup': 'సైన్ అప్ చేయండి',
      'email_required': 'ఇమెయిల్ అవసరం.',
      'email_invalid': 'చెల్లుబాటు అయ్యే ఇమెయిల్ చిరునామా నమోదు చేయండి.',
      'dob_required': 'పుట్టిన తేదీ అవసరం.',
      'dob_format': 'DD/MM/YYYY ఆకృతిలో నమోదు చేయండి.',
      'dob_invalid': 'చెల్లుబాటు అయ్యే తేదీ నమోదు చేయండి.',
      'dob_future': 'పుట్టిన తేదీ భవిష్యత్తులో ఉండకూడదు.',
    },
    'bn': {
      'heading': 'আবার স্বাগতম 👋',
      'subtitle': 'চালিয়ে যেতে আপনার বিবরণ লিখুন',
      'email': 'ইমেইল ঠিকানা',
      'dob': 'জন্ম তারিখ (DD/MM/YYYY)',
      'continue_btn': 'চালিয়ে যান',
      'loading': 'অনুগ্রহ করে অপেক্ষা করুন...',
      'no_account': 'অ্যাকাউন্ট নেই? ',
      'signup': 'সাইন আপ করুন',
      'email_required': 'ইমেইল প্রয়োজন।',
      'email_invalid': 'একটি বৈধ ইমেইল ঠিকানা লিখুন।',
      'dob_required': 'জন্ম তারিখ প্রয়োজন।',
      'dob_format': 'DD/MM/YYYY ফর্ম্যাটে লিখুন।',
      'dob_invalid': 'একটি বৈধ তারিখ লিখুন।',
      'dob_future': 'জন্ম তারিখ ভবিষ্যতে হতে পারে না।',
    },
    'mr': {
      'heading': 'पुन्हा स्वागत 👋',
      'subtitle': 'सुरू ठेवण्यासाठी तुमची माहिती प्रविष्ट करा',
      'email': 'ईमेल पत्ता',
      'dob': 'जन्मतारीख (DD/MM/YYYY)',
      'continue_btn': 'सुरू ठेवा',
      'loading': 'कृपया प्रतीक्षा करा...',
      'no_account': 'खाते नाही? ',
      'signup': 'साइन अप करा',
      'email_required': 'ईमेल आवश्यक आहे.',
      'email_invalid': 'वैध ईमेल पत्ता प्रविष्ट करा.',
      'dob_required': 'जन्मतारीख आवश्यक आहे.',
      'dob_format': 'DD/MM/YYYY स्वरूपात प्रविष्ट करा.',
      'dob_invalid': 'वैध तारीख प्रविष्ट करा.',
      'dob_future': 'जन्मतारीख भविष्यात असू शकत नाही.',
    },
  };

  // ── Validators (use translated error messages) ────────────────────────────

  String? _validateEmail(String? value, Map<String, String> lang) {
    if (value == null || value.trim().isEmpty) return lang['email_required'];
    final regex = RegExp(r'^[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return lang['email_invalid'];
    return null;
  }

  String? _validateDob(String? value, Map<String, String> lang) {
    if (value == null || value.trim().isEmpty) return lang['dob_required'];
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(value.trim())) return lang['dob_format'];
    final parts = value.trim().split('/');
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return lang['dob_format'];
    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) {
      return lang['dob_invalid'];
    }
    final birth = DateTime(year, month, day);
    if (birth.isAfter(DateTime.now())) return lang['dob_future'];
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _handleLogin(Map<String, String> lang) {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    ApiService.loginUser(
      _emailController.text.trim(),
      _dobController.text.trim(),
    ).then((user) async {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        // Save profile for persistence
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_profile', jsonEncode(user));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(profileData: user),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang['invalid_credentials'] ?? 'Invalid Email or DOB'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  void _navigateToSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(languageCode: widget.languageCode),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _t[widget.languageCode] ?? _t['en']!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade50,
              Colors.teal.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Back Button ────────────────────────────────────────
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.teal),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 24),

                // ── Header ─────────────────────────────────────────────
                Text(
                  lang['heading']!,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang['subtitle']!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Form Card ──────────────────────────────────────────
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: lang['email'],
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Colors.teal,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.teal, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => _validateEmail(v, lang),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                          ),

                          const SizedBox(height: 20),

                          // DOB field
                          TextFormField(
                            controller: _dobController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d/]')),
                              LengthLimitingTextInputFormatter(10),
                              _DobInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: lang['dob'],
                              prefixIcon: const Icon(
                                Icons.cake_outlined,
                                color: Colors.teal,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.teal, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => _validateDob(v, lang),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onFieldSubmitted: (_) => _handleLogin(lang),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Continue Button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.teal.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : () => _handleLogin(lang),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(
                      _isLoading ? lang['loading']! : lang['continue_btn']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Sign Up Link ───────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang['no_account']!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToSignUp,
                        child: Text(
                          lang['signup']!,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.teal,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── DOB auto-formatter ─────────────────────────────────────────────────────────
class _DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
