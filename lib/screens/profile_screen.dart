import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'registration_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> profileData;
  final Function(Map<String, dynamic>)? onProfileUpdate;
  const ProfileScreen({super.key, required this.profileData, this.onProfileUpdate});

  // All labels translated per language
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'title': 'My Profile',
      'patient_details': 'Patient Details',
      'emergency_details': 'Emergency Contact',
      'name': 'Full Name', 'age': 'Age', 'gender': 'Gender',
      'dob': 'Date of Birth', 'blood_group': 'Blood Group',
      'email': 'Email', 'phone': 'Phone', 'address': 'Address',
      'relationship': 'Relationship',
      'edit_btn': 'Edit Profile',
      'no_photo': 'No photo uploaded',
    },
    'ta': {
      'title': 'என் சுயவிவரம்',
      'patient_details': 'நோயாளி விவரங்கள்',
      'emergency_details': 'அவசர தொடர்பு',
      'name': 'முழு பெயர்', 'age': 'வயது', 'gender': 'பாலினம்',
      'dob': 'பிறந்த தேதி', 'blood_group': 'இரத்த வகை',
      'email': 'மின்னஞ்சல்', 'phone': 'தொலைபேசி', 'address': 'முகவரி',
      'relationship': 'உறவுமுறை',
      'edit_btn': 'சுயவிவரத்தைத் திருத்து',
      'no_photo': 'புகைப்படம் பதிவேற்றப்படவில்லை',
    },
    'hi': {
      'title': 'मेरी प्रोफ़ाइल',
      'patient_details': 'रोगी का विवरण',
      'emergency_details': 'आपातकालीन संपर्क',
      'name': 'पूरा नाम', 'age': 'आयु', 'gender': 'लिंग',
      'dob': 'जन्म तिथि', 'blood_group': 'रक्त समूह',
      'email': 'ईमेल', 'phone': 'फ़ोन', 'address': 'पता',
      'relationship': 'संबंध',
      'edit_btn': 'प्रोफ़ाइल संपादित करें',
      'no_photo': 'कोई फ़ोटो अपलोड नहीं',
    },
    'te': {
      'title': 'నా ప్రొఫైల్',
      'patient_details': 'రోగి వివరాలు',
      'emergency_details': 'అత్యవసర సంప్రదింపు',
      'name': 'పూర్తి పేరు', 'age': 'వయస్సు', 'gender': 'లింగం',
      'dob': 'పుట్టిన తేదీ', 'blood_group': 'రక్త వర్గం',
      'email': 'ఇమెయిల్', 'phone': 'ఫోన్', 'address': 'చిరునామా',
      'relationship': 'సంబంధం',
      'edit_btn': 'ప్రొఫైల్‌ను సవరించండి',
      'no_photo': 'ఫోటో అప్‌లోడ్ చేయబడలేదు',
    },
    'bn': {
      'title': 'আমার প্রোফাইল',
      'patient_details': 'রোগীর বিবরণ',
      'emergency_details': 'জরুরী যোগাযোগ',
      'name': 'পুরো নাম', 'age': 'বয়স', 'gender': 'লিঙ্গ',
      'dob': 'জন্ম তারিখ', 'blood_group': 'রক্তের গ্রুপ',
      'email': 'ইমেইল', 'phone': 'ফোন', 'address': 'ঠিকানা',
      'relationship': 'সম্পর্ক',
      'edit_btn': 'প্রোফাইল সম্পাদনা করুন',
      'no_photo': 'কোনো ছবি আপলোড হয়নি',
    },
    'mr': {
      'title': 'माझी प्रोफाइल',
      'patient_details': 'रुग्णाचा तपशील',
      'emergency_details': 'आपत्कालीन संपर्क',
      'name': 'पूर्ण नाव', 'age': 'वय', 'gender': 'लिंग',
      'dob': 'जन्मतारीख', 'blood_group': 'रक्तगट',
      'email': 'ईमेल', 'phone': 'फोन', 'address': 'पत्ता',
      'relationship': 'नाते',
      'edit_btn': 'प्रोफાઇલ संपादित करा',
      'no_photo': 'कोणताही फोटो अपलोड नाही',
    },
  };

  @override
  Widget build(BuildContext context) {
    final langCode = profileData['languageCode'] as String? ?? 'en';
    final lang = translations[langCode] ?? translations['en']!;
    final photoPath = profileData['photo'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── AVATAR HEADER ──
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 64,
                  backgroundColor: Colors.teal.shade100,
                  backgroundImage: photoPath.isNotEmpty
                      ? (photoPath.startsWith('http')
                          ? NetworkImage(photoPath)
                          : (kIsWeb ? const AssetImage('assets/pill_icon.png') : NetworkImage(photoPath))) as ImageProvider
                      : null,
                  child: photoPath.isEmpty
                      ? const Icon(Icons.person_rounded, size: 64, color: Colors.teal)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  profileData['name'] ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if ((profileData['blood_group'] as String?)?.isNotEmpty == true)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.redAccent.shade100),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profileData['blood_group'] ?? '',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegistrationScreen(
                          languageCode: langCode,
                          initialProfile: profileData,
                        ),
                      ),
                    );
                    if (updated != null && onProfileUpdate != null) {
                      onProfileUpdate!(updated);
                    }
                  },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(lang['edit_btn']!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── PATIENT DETAILS SECTION ──
          _SectionHeader(title: lang['patient_details']!, color: Colors.teal),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _InfoRow(label: lang['name']!, value: profileData['name']),
                _InfoRow(label: lang['age']!, value: profileData['age']),
                _InfoRow(label: lang['gender']!, value: profileData['gender']),
                _InfoRow(label: lang['dob']!, value: profileData['dob']),
                _InfoRow(label: lang['blood_group']!, value: profileData['blood_group']),
                _InfoRow(label: lang['email']!, value: profileData['email']),
                _InfoRow(label: lang['phone']!, value: profileData['phone']),
                _InfoRow(label: lang['address']!, value: profileData['address'], isLast: true),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // ── EMERGENCY CONTACT SECTION ──
          _SectionHeader(title: lang['emergency_details']!, color: Colors.redAccent),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _InfoRow(label: lang['name']!, value: profileData['emergency_name']),
                _InfoRow(label: lang['relationship']!, value: profileData['emergency_relationship']),
                _InfoRow(label: lang['gender']!, value: profileData['emergency_gender']),
                _InfoRow(label: lang['phone']!, value: profileData['emergency_phone']),
                _InfoRow(label: lang['email']!, value: profileData['emergency_email']),
                _InfoRow(label: lang['address']!, value: profileData['emergency_address'], isLast: true),
              ]),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title; final Color color;
  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 4, height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label; final String? value; final bool isLast;
  const _InfoRow({required this.label, this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final display = (value?.trim().isEmpty ?? true) ? '—' : value!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
              Expanded(child: Text(display, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
