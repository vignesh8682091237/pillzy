import 'package:flutter/material.dart';
import 'language_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── APP LOGO ──────────────────────────────────────────
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  size: 65,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 28),

              // ── APP NAME ──────────────────────────────────────────
              const Text(
                'Pillzy',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                  letterSpacing: 2.0,
                ),
              ),

              const SizedBox(height: 14),

              // ── TAGLINE ───────────────────────────────────────────
              Text(
                'Your Health, Our Priority',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.teal.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),

              const Spacer(flex: 2),

              // ── WELCOME QUOTE ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      size: 40,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '"Health is a state of complete physical, mental and social well-being, not merely the absence of disease or infirmity."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '— World Health Organization',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // ── GET STARTED BUTTON ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.teal.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageScreen(savedProfile: null),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
