import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

/// The app's Login / Sign Up choice screen — shown after LanguageScreen.
/// All UI text is rendered in the [languageCode] selected by the user.
class EntryScreen extends StatelessWidget {
  final String languageCode;

  const EntryScreen({super.key, this.languageCode = 'en'});

  // ── Translations ──────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _t = {
    'en': {
      'tagline': 'Your Health, Our Priority',
      'heading': 'Get Started',
      'subtitle': 'Login to your account or create a new one',
      'login': 'Login',
      'signup': 'Sign Up',
      'footer': 'Stay Consistent, Stay Healthy 💊',
    },
    'hi': {
      'tagline': 'आपका स्वास्थ्य, हमारी प्राथमिकता',
      'heading': 'शुरू करें',
      'subtitle': 'अपने खाते में लॉगिन करें या नया बनाएं',
      'login': 'लॉगिन',
      'signup': 'साइन अप',
      'footer': 'नियमित रहें, स्वस्थ रहें 💊',
    },
    'ta': {
      'tagline': 'உங்கள் ஆரோக்கியம், எங்கள் முன்னுரிமை',
      'heading': 'தொடங்குங்கள்',
      'subtitle': 'உங்கள் கணக்கில் உள்நுழையுங்கள் அல்லது புதியதை உருவாக்குங்கள்',
      'login': 'உள்நுழை',
      'signup': 'பதிவு செய்',
      'footer': 'தொடர்ந்து இருங்கள், ஆரோக்கியமாக இருங்கள் 💊',
    },
    'te': {
      'tagline': 'మీ ఆరోగ్యం, మా ప్రాధాన్యత',
      'heading': 'ప్రారంభించండి',
      'subtitle': 'మీ ఖాతాలో లాగిన్ అవ్వండి లేదా కొత్తది సృష్టించండి',
      'login': 'లాగిన్',
      'signup': 'సైన్ అప్',
      'footer': 'స్థిరంగా ఉండండి, ఆరోగ్యంగా ఉండండి 💊',
    },
    'bn': {
      'tagline': 'আপনার স্বাস্থ্য, আমাদের অগ্রাধিকার',
      'heading': 'শুরু করুন',
      'subtitle': 'আপনার অ্যাকাউন্টে লগইন করুন বা নতুন তৈরি করুন',
      'login': 'লগইন',
      'signup': 'সাইন আপ',
      'footer': 'নিয়মিত থাকুন, সুস্থ থাকুন 💊',
    },
    'mr': {
      'tagline': 'तुमचे आरोग्य, आमची प्राथमिकता',
      'heading': 'सुरू करा',
      'subtitle': 'तुमच्या खात्यात लॉगिन करा किंवा नवीन तयार करा',
      'login': 'लॉगिन',
      'signup': 'साइन अप',
      'footer': 'सातत्य राखा, निरोगी राहा 💊',
    },
  };

  @override
  Widget build(BuildContext context) {
    final lang = _t[languageCode] ?? _t['en']!;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ── App Logo ───────────────────────────────────────────
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // ── App Name ───────────────────────────────────────────
                const Text(
                  'Pillzy',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang['tagline']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),

                const Spacer(flex: 2),

                // ── Heading ────────────────────────────────────────────
                Text(
                  lang['heading']!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang['subtitle']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 36),

                // ── Login Button ───────────────────────────────────────
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
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(
                      lang['login']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LoginScreen(languageCode: languageCode),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ── Sign Up Button ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: Text(
                      lang['signup']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RegistrationScreen(languageCode: languageCode),
                        ),
                      );
                    },
                  ),
                ),

                const Spacer(flex: 3),

                // ── Footer ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    lang['footer']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
