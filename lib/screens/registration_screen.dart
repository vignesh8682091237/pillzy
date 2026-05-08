import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  final String languageCode;
  final Map<String, dynamic>? initialProfile;
  const RegistrationScreen({super.key, required this.languageCode, this.initialProfile});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  XFile? _uploadedPhoto;
  Uint8List? _photoBytes;
  String? _photoError;
  int? _calculatedAge; // auto-calculated from DOB

  // Controllers
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyEmailController = TextEditingController();
  final _emergencyAddressController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedRelationship;
  String? _emergencyGender;

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      final p = widget.initialProfile!;
      _nameController.text = p['name'] ?? '';
      _dobController.text = p['dob'] ?? '';
      _emailController.text = p['email'] ?? '';
      _phoneController.text = p['phone'] ?? '';
      _addressController.text = p['address'] ?? '';
      _emergencyNameController.text = p['emergency_name'] ?? '';
      _emergencyPhoneController.text = p['emergency_phone'] ?? '';
      _emergencyEmailController.text = p['emergency_email'] ?? '';
      _emergencyAddressController.text = p['emergency_address'] ?? '';
      _selectedGender = p['gender'];
      _selectedBloodGroup = p['blood_group'];
      _selectedRelationship = p['emergency_relationship'];
      _emergencyGender = p['emergency_gender'];
      _calculatedAge = _calculateAge(_dobController.text);
    }
  }

  final Map<String, Map<String, String>> translations = {
    'en': {
      'title': 'Registration',
      'edit_title': 'Edit Profile',
      'patient_details': 'Patient Details',
      'name': 'Full Name',
      'age_label': 'Age (auto-calculated)',
      'gender': 'Gender',
      'dob': 'Date of Birth (DD/MM/YYYY)',
      'blood_group': 'Blood Group',
      'email': 'Email ID',
      'phone': 'Phone Number',
      'address': 'Full Address',
      'photo_guide': 'Upload Passport Photo (Optional)',
      'photo_hint': 'Tap to choose — Camera or Gallery',
      'photo_change': 'Change Photo',
      'photo_source_title': 'Select Photo Source',
      'photo_camera': 'Camera',
      'photo_gallery': 'Gallery',
      'photo_error_size': 'File must be between 120 KB and 5 MB.',
      'photo_error_type': 'Only JPG/PNG files are allowed.',
      'photo_required': 'Please upload a passport photo.',
      'emergency_details': 'Emergency Contact',
      'relationship': 'Relationship to Patient',
      'submit': 'Save Profile',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'parent': 'Parent',
      'child': 'Child',
      'spouse': 'Spouse',
      'sibling': 'Sibling',
      'required': 'This field is required.',
      'invalid_email': 'Enter a valid email address.',
      'invalid_phone': 'Enter a valid 10-digit phone number.',
      'invalid_dob': 'Enter date as DD/MM/YYYY.',
      'future_dob': 'Date of birth cannot be in the future.',
      'select_required': 'Please select an option.',
      'years': 'years',
      'cancel': 'Cancel',
    },
    'ta': {
      'title': 'பதிவு',
      'edit_title': 'சுயவிவரத்தைத் திருத்து',
      'patient_details': 'நோயாளி விவரங்கள்',
      'name': 'முழு பெயர்',
      'age_label': 'வயது (தானாக கணக்கிடப்படும்)',
      'gender': 'பாலினம்',
      'dob': 'பிறந்த தேதி (DD/MM/YYYY)',
      'blood_group': 'இரத்த வகை',
      'email': 'மின்னஞ்சல்',
      'phone': 'தொலைபேசி எண்',
      'address': 'முகவரி',
      'photo_guide': 'கடவுச்சீட்டு புகைப்படம் பதிவேற்று (விருப்பமானது)',
      'photo_hint': 'தட்டவும் — கேமரா அல்லது கேலரி',
      'photo_change': 'புகைப்படம் மாற்று',
      'photo_source_title': 'புகைப்பட மூலத்தை தேர்ந்தெடு',
      'photo_camera': 'கேமரா',
      'photo_gallery': 'கேலரி',
      'photo_error_size': 'கோப்பு 120 KB மற்றும் 5 MB இடையே இருக்க வேண்டும்.',
      'photo_error_type': 'JPG/PNG கோப்புகள் மட்டுமே அனுமதிக்கப்படுகின்றன.',
      'photo_required': 'தயவுசெய்து புகைப்படம் பதிவேற்றவும்.',
      'emergency_details': 'அவசர தொடர்பு',
      'relationship': 'உறவுமுறை',
      'submit': 'சேமிக்க',
      'male': 'ஆண்',
      'female': 'பெண்',
      'other': 'மற்றவை',
      'parent': 'பெற்றோர்',
      'child': 'குழந்தை',
      'spouse': 'வாழ்க்கைத்துணை',
      'sibling': 'உடன்பிறந்தவர்',
      'required': 'இந்த புலம் தேவை.',
      'invalid_email': 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்.',
      'invalid_phone': 'சரியான 10 இலக்க தொலைபேசி எண்ணை உள்ளிடவும்.',
      'invalid_dob': 'DD/MM/YYYY வடிவத்தில் உள்ளிடவும்.',
      'future_dob': 'பிறந்த தேதி எதிர்காலத்தில் இருக்க முடியாது.',
      'select_required': 'ஒரு விருப்பத்தை தேர்ந்தெடுக்கவும்.',
      'years': 'வயது',
      'cancel': 'ரத்து செய்',
    },
    'hi': {
      'title': 'पंजीकरण',
      'edit_title': 'प्रोफ़ाइल संपादित करें',
      'patient_details': 'रोगी का विवरण',
      'name': 'पूरा नाम',
      'age_label': 'आयु (स्वतः गणना)',
      'gender': 'लिंग',
      'dob': 'जन्म तिथि (DD/MM/YYYY)',
      'blood_group': 'रक्त समूह',
      'email': 'ईमेल',
      'phone': 'फ़ोन नंबर',
      'address': 'पता',
      'photo_guide': 'पासपोर्ट फ़ोटो अपलोड करें (वैकल्पिक)',
      'photo_hint': 'टैप करें — कैमरा या गैलरी',
      'photo_change': 'फ़ोटो बदलें',
      'photo_source_title': 'फ़ोटो स्रोत चुनें',
      'photo_camera': 'कैमरा',
      'photo_gallery': 'गैलरी',
      'photo_error_size': 'फ़ाइल 120 KB और 5 MB के बीच होनी चाहिए।',
      'photo_error_type': 'केवल JPG/PNG फ़ाइलें अनुमत हैं।',
      'photo_required': 'कृपया पासपोर्ट फ़ोटो अपलोड करें।',
      'emergency_details': 'आपातकालीन संपर्क',
      'relationship': 'रोगी से संबंध',
      'submit': 'प्रोफ़ाइल सहेजें',
      'male': 'पुरुष',
      'female': 'महिला',
      'other': 'अन्य',
      'parent': 'माता-पिता',
      'child': 'बच्चा',
      'spouse': 'जीवनसाथी',
      'sibling': 'भाई-बहन',
      'required': 'यह फ़ील्ड आवश्यक है।',
      'invalid_email': 'एक वैध ईमेल पता दर्ज करें।',
      'invalid_phone': 'एक वैध 10-अंकीय फ़ोन नंबर दर्ज करें।',
      'invalid_dob': 'DD/MM/YYYY प्रारूप में दर्ज करें।',
      'future_dob': 'जन्म तिथि भविष्य में नहीं हो सकती।',
      'select_required': 'कृपया एक विकल्प चुनें।',
      'years': 'वर्ष',
      'cancel': 'रद्द करें',
    },
    'te': {
      'title': 'నమోదు',
      'edit_title': 'ప్రొఫైల్‌ను సవరించండి',
      'patient_details': 'రోగి వివరాలు',
      'name': 'పూర్తి పేరు',
      'age_label': 'వయస్సు (స్వయంచాలకంగా)',
      'gender': 'లింగం',
      'dob': 'పుట్టిన తేదీ (DD/MM/YYYY)',
      'blood_group': 'రక్త వర్గం',
      'email': 'ఇమెయిల్',
      'phone': 'ఫోన్ నంబర్',
      'address': 'చిరునామా',
      'photo_guide': 'పాస్‌పోర్ట్ ఫోటో అప్‌లోడ్ చేయండి (ఐచ్ఛికం)',
      'photo_hint': 'నొక్కండి — కెమెరా లేదా గ్యాలరీ',
      'photo_change': 'ఫోటో మార్చండి',
      'photo_source_title': 'ఫోటో మూలాన్ని ఎంచుకోండి',
      'photo_camera': 'కెమెరా',
      'photo_gallery': 'గ్యాలరీ',
      'photo_error_size': 'ఫైల్ 120 KB మరియు 5 MB మధ్య ఉండాలి.',
      'photo_error_type': 'JPG/PNG ఫైళ్లు మాత్రమే అనుమతించబడతాయి.',
      'photo_required': 'దయచేసి పాస్‌పోర్ట్ ఫోటో అప్‌లోడ్ చేయండి.',
      'emergency_details': 'అత్యవసర సంప్రదింపు',
      'relationship': 'సంబంధం',
      'submit': 'సేవ్ చేయండి',
      'male': 'పురుషుడు',
      'female': 'స్త్రీ',
      'other': 'ఇతర',
      'parent': 'తల్లిదండ్రులు',
      'child': 'పిల్లలు',
      'spouse': 'జీవిత భాగస్వామి',
      'sibling': 'తోబుట్టువు',
      'required': 'ఈ ఫీల్డ్ అవసరం.',
      'invalid_email': 'చెల్లుబాటు అయ్యే ఇమెయిల్ చిరునామా నమోదు చేయండి.',
      'invalid_phone': 'చెల్లుబాటు అయ్యే 10-అంకెల ఫోన్ నంబర్ నమోదు చేయండి.',
      'invalid_dob': 'DD/MM/YYYY ఆకృతిలో నమోదు చేయండి.',
      'future_dob': 'పుట్టిన తేదీ భవిష్యత్తులో ఉండకూడదు.',
      'select_required': 'దయచేసి ఒక ఎంపిక చేయండి.',
      'years': 'సంవత్సరాలు',
      'cancel': 'రద్దు చేయి',
    },
    'bn': {
      'title': 'নিবন্ধন',
      'edit_title': 'প্রোফাইল সম্পাদনা করুন',
      'patient_details': 'রোগীর বিবরণ',
      'name': 'পুরো নাম',
      'age_label': 'বয়স (স্বয়ংক্রিয়)',
      'gender': 'লিঙ্গ',
      'dob': 'জন্ম তারিখ (DD/MM/YYYY)',
      'blood_group': 'রক্তের গ্রুপ',
      'email': 'ইমেইল',
      'phone': 'ফোন নম্বর',
      'address': 'ঠিকানা',
      'photo_guide': 'পাসপোর্ট ছবি আপলোড করুন (ঐচ্ছিক)',
      'photo_hint': 'ট্যাপ করুন — ক্যামেরা বা গ্যালারি',
      'photo_change': 'ছবি পরিবর্তন করুন',
      'photo_source_title': 'ছবির উৎস নির্বাচন করুন',
      'photo_camera': 'ক্যামেরা',
      'photo_gallery': 'গ্যালারি',
      'photo_error_size': 'ফাইলটি 120 KB এবং 5 MB এর মধ্যে হতে হবে।',
      'photo_error_type': 'শুধুমাত্র JPG/PNG ফাইল অনুমোদিত।',
      'photo_required': 'অনুগ্রহ করে পাসপোর্ট ছবি আপলোড করুন।',
      'emergency_details': 'জরুরী যোগাযোগ',
      'relationship': 'সম্পর্ক',
      'submit': 'সেভ করুন',
      'male': 'পুরুষ',
      'female': 'মহিলা',
      'other': 'অন্যান্য',
      'parent': 'অভিভাবক',
      'child': 'সন্তান',
      'spouse': 'স্বামী/স্ত্রী',
      'sibling': 'ভাই/বোন',
      'required': 'এই ক্ষেত্রটি প্রয়োজন।',
      'invalid_email': 'একটি বৈধ ইমেইল ঠিকানা লিখুন।',
      'invalid_phone': 'একটি বৈধ 10-সংখ্যার ফোন নম্বর লিখুন।',
      'invalid_dob': 'DD/MM/YYYY ফর্ম্যাটে লিখুন।',
      'future_dob': 'জন্ম তারিখ ভবিষ্যতে হতে পারে না।',
      'select_required': 'অনুগ্রহ করে একটি বিকল্প নির্বাচন করুন।',
      'years': 'বছর',
      'cancel': 'বাতিল',
    },
    'mr': {
      'title': 'नोंदणी',
      'edit_title': 'प्रोफाइल संपादित करा',
      'patient_details': 'रुग्णाचा तपशील',
      'name': 'पूर्ण नाव',
      'age_label': 'वय (स्वयं-गणना)',
      'gender': 'लिंग',
      'dob': 'जन्मतारीख (DD/MM/YYYY)',
      'blood_group': 'रक्तगट',
      'email': 'ईमेल',
      'phone': 'फोन नंबर',
      'address': 'पत्ता',
      'photo_guide': 'पासपोर्ट फोटो अपलोड करा (पर्यायी)',
      'photo_hint': 'टॅप करा — कॅमेरा किंवा गॅलरी',
      'photo_change': 'फोटो बदला',
      'photo_source_title': 'फोटो स्रोत निवडा',
      'photo_camera': 'कॅमेरा',
      'photo_gallery': 'गॅलरी',
      'photo_error_size': 'फाइल 120 KB आणि 5 MB दरम्यान असणे आवश्यक आहे.',
      'photo_error_type': 'फक्त JPG/PNG फाइल्स परवानगी आहेत.',
      'photo_required': 'कृपया पासपोर्ट फोटो अपलोड करा.',
      'emergency_details': 'आपत्कालीन संपर्क',
      'relationship': 'नाते',
      'submit': 'सेव्ह करा',
      'male': 'पुरुष',
      'female': 'महिला',
      'other': 'इतर',
      'parent': 'पालक',
      'child': 'मूल',
      'spouse': 'जोडीदार',
      'sibling': 'भाऊ/बहीण',
      'required': 'हे फील्ड आवश्यक आहे.',
      'invalid_email': 'वैध ईमेल पत्ता प्रविष्ट करा.',
      'invalid_phone': 'वैध 10-अंकी फोन नंबर प्रविष्ट करा.',
      'invalid_dob': 'DD/MM/YYYY स्वरूपात प्रविष्ट करा.',
      'future_dob': 'जन्मतारीख भविष्यात असू शकत नाही.',
      'select_required': 'कृपया एक पर्याय निवडा.',
      'years': 'वर्षे',
      'cancel': 'रद्द करा',
    },
  };

  // ── AGE CALCULATOR ───────────────────────────────────────────────────────────

  int? _calculateAge(String dob) {
    final parts = dob.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) return null;
    final birth = DateTime(year, month, day);
    final today = DateTime.now();
    if (birth.isAfter(today)) return null;
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }

  // ── PHOTO PICKER — Camera OR Gallery ────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final lang = translations[widget.languageCode] ?? translations['en']!;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lang['photo_source_title']!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: lang['photo_camera']!,
                    color: Colors.teal,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  _sourceButton(
                    icon: Icons.photo_library_rounded,
                    label: lang['photo_gallery']!,
                    color: Colors.indigo,
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lang['cancel']!,
                    style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.path.split('.').last.toLowerCase();

    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      setState(() {
        _photoError = lang['photo_error_type'];
        _uploadedPhoto = null;
      });
      return;
    }
    if (bytes.length < 120 * 1024 || bytes.length > 5 * 1024 * 1024) {
      setState(() {
        _photoError = lang['photo_error_size'];
        _uploadedPhoto = null;
      });
      return;
    }

    setState(() {
      _uploadedPhoto = picked;
      _photoBytes = bytes;
      _photoError = null;
    });
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Icon(icon, size: 34, color: color),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── FORM WIDGETS ─────────────────────────────────────────────────────────────

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged, {
    bool required = false,
    String? requiredError,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: (v) {
          onChanged(v);
          if (_submitted) setState(() {});
        },
        validator: required
            ? (v) => (v == null || v.isEmpty)
                ? (requiredError ?? 'Required')
                : null
            : null,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  // ── VALIDATORS ───────────────────────────────────────────────────────────────

  String? _validateRequired(String? value, String errorMsg) {
    if (value == null || value.trim().isEmpty) return errorMsg;
    return null;
  }

  String? _validateDob(String? value, String requiredMsg, String invalidMsg,
      String futureMsg) {
    if (value == null || value.trim().isEmpty) return requiredMsg;
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(value.trim())) return invalidMsg;
    final parts = value.trim().split('/');
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return invalidMsg;
    if (month < 1 || month > 12 || day < 1 || day > 31) return invalidMsg;
    if (year < 1900 || year > DateTime.now().year) return invalidMsg;
    final birth = DateTime(year, month, day);
    if (birth.isAfter(DateTime.now())) return futureMsg;
    return null;
  }

  String? _validateEmail(
      String? value, String requiredMsg, String invalidMsg) {
    if (value == null || value.trim().isEmpty) return requiredMsg;
    final regex = RegExp(r'^[\w.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return invalidMsg;
    return null;
  }

  String? _validatePhone(
      String? value, String requiredMsg, String invalidMsg) {
    if (value == null || value.trim().isEmpty) return requiredMsg;
    final digits = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final local = RegExp(r'^\d{10}$');
    final international = RegExp(r'^\+\d{10,15}$');
    if (!local.hasMatch(digits) && !international.hasMatch(digits)) {
      return invalidMsg;
    }
    return null;
  }

  // ── SUBMIT ───────────────────────────────────────────────────────────────────

  void _handleSubmit() {
    setState(() => _submitted = true);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final age = _calculateAge(_dobController.text) ?? 0;
    final profileData = {
      'languageCode': widget.languageCode,
      'name': _nameController.text.trim(),
      'age': age.toString(),
      'gender': _selectedGender ?? '',
      'dob': _dobController.text.trim(),
      'blood_group': _selectedBloodGroup ?? '',
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'photo': _uploadedPhoto?.path ?? '',
      'emergency_name': _emergencyNameController.text.trim(),
      'emergency_relationship': _selectedRelationship ?? '',
      'emergency_gender': _emergencyGender ?? '',
      'emergency_phone': _emergencyPhoneController.text.trim(),
      'emergency_email': _emergencyEmailController.text.trim(),
      'emergency_address': _emergencyAddressController.text.trim(),
    };

    // 1. Upload Photo first if exists
    final localPhoto = _uploadedPhoto?.path ?? '';
    if (localPhoto.isNotEmpty) {
      ApiService.uploadImage(localPhoto, bytes: _photoBytes).then((url) {
        final profileWithUrl = {...profileData, 'photo': url ?? ''};
        _registerAndNavigate(profileWithUrl);
      });
    } else {
      _registerAndNavigate(profileData);
    }
  }

  void _registerAndNavigate(Map<String, dynamic> profileData) {
    final isUpdate = widget.initialProfile != null;
    final action = isUpdate
        ? ApiService.updateUser(profileData)
        : ApiService.registerUser(profileData);

    action.then((response) async {
      if (!mounted) return;

      // Save profile for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_profile', jsonEncode(profileData));

      if (!mounted) return;

      if (isUpdate) {
        // Return to ProfileScreen with new data
        Navigator.pop(context, profileData);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(profileData: profileData),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyEmailController.dispose();
    _emergencyAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = translations[widget.languageCode] ?? translations['en']!;
    final genderOptions = [lang['male']!, lang['female']!, lang['other']!];
    final relationOptions = [
      lang['parent']!,
      lang['child']!,
      lang['spouse']!,
      lang['sibling']!,
      lang['other']!,
    ];

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initialProfile != null ? lang['edit_title']! : lang['title']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── PATIENT DETAILS ──────────────────────────────────────────────
                Text(lang['patient_details']!,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal)),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Full Name
                        _buildTextField(
                          lang['name']!,
                          _nameController,
                          validator: (v) =>
                              _validateRequired(v, lang['required']!),
                        ),

                        // DOB field + live age chip side-by-side
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                lang['dob']!,
                                _dobController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d/]')),
                                  LengthLimitingTextInputFormatter(10),
                                  _DobInputFormatter(),
                                ],
                                onChanged: (v) => setState(
                                    () => _calculatedAge = _calculateAge(v)),
                                validator: (v) => _validateDob(
                                  v,
                                  lang['required']!,
                                  lang['invalid_dob']!,
                                  lang['future_dob']!,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Age chip
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 56),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: _calculatedAge != null
                                        ? Colors.teal.withValues(alpha: 0.08)
                                        : Colors.grey.shade100,
                                    border: Border.all(
                                      color: _calculatedAge != null
                                          ? Colors.teal
                                          : Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _calculatedAge != null
                                          ? '$_calculatedAge ${lang['years']}'
                                          : lang['age_label']!,
                                      style: TextStyle(
                                        color: _calculatedAge != null
                                            ? Colors.teal.shade700
                                            : Colors.grey,
                                        fontWeight: _calculatedAge != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: _calculatedAge != null ? 15 : 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Gender + Blood Group
                        Row(children: [
                          Expanded(
                            child: _buildDropdown(
                              lang['gender']!,
                              genderOptions,
                              _selectedGender,
                              (v) => setState(() => _selectedGender = v),
                              required: true,
                              requiredError: lang['select_required'],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              lang['blood_group']!,
                              ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
                              _selectedBloodGroup,
                              (v) => setState(() => _selectedBloodGroup = v),
                              required: true,
                              requiredError: lang['select_required'],
                            ),
                          ),
                        ]),

                        // Email
                        _buildTextField(
                          lang['email']!,
                          _emailController,
                          type: TextInputType.emailAddress,
                          validator: (v) => _validateEmail(
                              v, lang['required']!, lang['invalid_email']!),
                        ),

                        // Phone
                        _buildTextField(
                          lang['phone']!,
                          _phoneController,
                          type: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d\+\-\s]')),
                          ],
                          validator: (v) => _validatePhone(
                              v, lang['required']!, lang['invalid_phone']!),
                        ),

                        // Address
                        _buildTextField(
                          lang['address']!,
                          _addressController,
                          validator: (v) =>
                              _validateRequired(v, lang['required']!),
                        ),

                        // ── PHOTO UPLOAD ─────────────────────────────────────────
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.07),
                              border: Border.all(
                                color: _photoError != null
                                    ? Colors.red
                                    : Colors.teal,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _uploadedPhoto != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: kIsWeb 
                                            ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                                            : Image.network(_uploadedPhoto!.path, fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(alpha: 0.85),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.edit,
                                                  size: 12, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(lang['photo_change']!,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.camera_alt_rounded,
                                                size: 28, color: Colors.teal),
                                            const SizedBox(width: 10),
                                            Icon(Icons.photo_library_rounded,
                                                size: 28,
                                                color: Colors.indigo.shade400),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(lang['photo_guide']!,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal)),
                                        const SizedBox(height: 4),
                                        Text(lang['photo_hint']!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        if (_photoError != null) ...[
                          const SizedBox(height: 6),
                          Text(_photoError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── EMERGENCY CONTACT ─────────────────────────────────────────────
                Text(lang['emergency_details']!,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent)),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildTextField(
                          lang['name']!,
                          _emergencyNameController,
                          validator: (v) =>
                              _validateRequired(v, lang['required']!),
                        ),
                        _buildDropdown(
                          lang['relationship']!,
                          relationOptions,
                          _selectedRelationship,
                          (v) => setState(() => _selectedRelationship = v),
                          required: true,
                          requiredError: lang['select_required'],
                        ),
                        _buildDropdown(
                          lang['gender']!,
                          genderOptions,
                          _emergencyGender,
                          (v) => setState(() => _emergencyGender = v),
                          required: true,
                          requiredError: lang['select_required'],
                        ),
                        _buildTextField(
                          lang['phone']!,
                          _emergencyPhoneController,
                          type: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d\+\-\s]')),
                          ],
                          validator: (v) => _validatePhone(
                              v, lang['required']!, lang['invalid_phone']!),
                        ),
                        _buildTextField(
                          lang['email']!,
                          _emergencyEmailController,
                          type: TextInputType.emailAddress,
                          validator: (v) => _validateEmail(
                              v, lang['required']!, lang['invalid_email']!),
                        ),
                        _buildTextField(
                          lang['address']!,
                          _emergencyAddressController,
                          validator: (v) =>
                              _validateRequired(v, lang['required']!),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _handleSubmit,
                  child: Text(lang['submit']!,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
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

// ── AUTO-FORMAT DOB: inserts "/" after DD and MM automatically ───────────────

class _DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Strip all slashes, keep only digits
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
