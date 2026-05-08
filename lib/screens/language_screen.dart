import 'package:flutter/material.dart';
import 'entry_screen.dart';

class LanguageScreen extends StatelessWidget {
  final Map<String, dynamic>? savedProfile;

  const LanguageScreen({super.key, this.savedProfile});

  @override
  Widget build(BuildContext context) {
    debugPrint("--- LANGUAGE SCREEN V2 LOADED ---");
    final List<Map<String, String>> languages = [
      {'name': 'English', 'code': 'en'},
      {'name': 'हिन्दी (Hindi)', 'code': 'hi'},
      {'name': 'தமிழ் (Tamil)', 'code': 'ta'},
      {'name': 'తెలుగు (Telugu)', 'code': 'te'},
      {'name': 'বাংলা (Bengali)', 'code': 'bn'},
      {'name': 'मরাठी (Marathi)', 'code': 'mr'},
    ];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Select Language',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade50,
                Colors.orange.shade100,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Please select your preferred language',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    itemCount: languages.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal,
                          elevation: 2,
                          shadowColor: Colors.teal.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.teal, width: 1.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        ),
                        onPressed: () {
                          final langCode = languages[index]['code']!;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EntryScreen(languageCode: langCode),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.language_rounded, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  languages[index]['name']!,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      );
                    },
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
