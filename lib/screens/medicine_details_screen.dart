import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final String languageCode;
  final Map<String, dynamic>? initialMedicine;
  const MedicineDetailsScreen({super.key, required this.languageCode, this.initialMedicine});

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  XFile? _medicinePhoto;
  Uint8List? _photoBytes;
  String? _photoError;
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String? _selectedFrequency;

  // Dynamic time slots
  List<_TimeSlot> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialMedicine != null) {
      final med = widget.initialMedicine!;
      _nameController.text = med['name'] ?? '';
      _dosageController.text = med['dosage'] ?? '';
      _selectedFrequency = med['frequency'];
      
      // Initialize time slots from existing data
      if (_selectedFrequency != null) {
        final lang = translations[widget.languageCode] ?? translations['en']!;
        _updateTimeSlots(_selectedFrequency!, lang);
        
        // Restore specific times if they exist
        final existingTimes = med['times'] as List<dynamic>? ?? [];
        for (int i = 0; i < _timeSlots.length && i < existingTimes.length; i++) {
          final timeStr = (existingTimes[i] as String).split(': ').last;
          try {
            final parts = timeStr.split(' ');
            final hhmm = parts[0].split(':');
            int hour = int.parse(hhmm[0]);
            int minute = int.parse(hhmm[1]);
            if (parts[1] == 'PM' && hour < 12) hour += 12;
            if (parts[1] == 'AM' && hour == 12) hour = 0;
            _timeSlots[i].selected = TimeOfDay(hour: hour, minute: minute);
          } catch (e) {
            debugPrint("Error loading medicine: $e");
          }
        }
      }
    }
  }

  static const Map<String, Map<String, String>> translations = {
    'en': {
      'title': 'Medicine Details',
      'photo_label': 'Medicine Photo',
      'photo_hint': 'Tap to upload medicine image\nJPG/PNG • Max 5 MB',
      'photo_change': 'Change',
      'photo_error': 'Only JPG/PNG files under 5 MB are allowed.',
      'med_name': 'Medicine Name',
      'dosage': 'Dosage (e.g. 500mg, 1 tablet)',
      'frequency': 'Frequency',
      'freq_once': 'Once a day',
      'freq_twice': 'Twice a day',
      'freq_thrice': 'Three times a day',
      'freq_custom': 'As needed',
      'save': 'Save Medicine',
      'required': 'Please fill all required fields.',
      'times_title': 'Schedule Times',
      'morning': 'Morning',
      'afternoon': 'Afternoon',
      'night': 'Night',
      'time1': 'Time 1',
      'time2': 'Time 2',
      'pick_time': 'Set time',
      'photo_source_title': 'Select Photo Source',
      'photo_camera': 'Camera',
      'photo_gallery': 'Gallery',
      'cancel': 'Cancel',
    },
    'ta': {
      'title': 'மருந்து விவரங்கள்',
      'photo_label': 'மருந்து புகைப்படம்',
      'photo_hint': 'மருந்து படத்தை பதிவேற்ற தட்டவும்\nJPG/PNG • அதிகபட்சம் 5 MB',
      'photo_change': 'மாற்று',
      'photo_error': 'JPG/PNG கோப்புகள் மட்டுமே, 5 MB க்கு குறைவாக.',
      'med_name': 'மருந்தின் பெயர்',
      'dosage': 'மோதரை (எ.கா. 500mg, 1 மாத்திரை)',
      'frequency': 'அதிர்வெண்',
      'freq_once': 'ஒரு நாளில் ஒருமுறை',
      'freq_twice': 'ஒரு நாளில் இருமுறை',
      'freq_thrice': 'ஒரு நாளில் மூன்று முறை',
      'freq_custom': 'தேவைப்படும்போது',
      'save': 'மருந்தை சேமிக்க',
      'required': 'அனைத்து புலங்களையும் நிரப்பவும்.',
      'times_title': 'நேர அட்டவணை',
      'morning': 'காலை',
      'afternoon': 'மதியம்',
      'night': 'இரவு',
      'time1': 'நேரம் 1',
      'time2': 'நேரம் 2',
      'pick_time': 'நேரம் அமை',
      'photo_source_title': 'புகைப்பட மூலத்தை தேர்ந்தெடு',
      'photo_camera': 'கேமரா',
      'photo_gallery': 'கேலரி',
      'cancel': 'ரத்து செய்',
    },
    'hi': {
      'title': 'दवा विवरण',
      'photo_label': 'दवा की फ़ोटो',
      'photo_hint': 'दवा की छवि अपलोड करने के लिए टैप करें\nJPG/PNG • अधिकतम 5 MB',
      'photo_change': 'बदलें',
      'photo_error': 'केवल JPG/PNG फ़ाइलें, 5 MB से कम।',
      'med_name': 'दवा का नाम',
      'dosage': 'खुराक (जैसे 500mg, 1 टैबलेट)',
      'frequency': 'आवृत्ति',
      'freq_once': 'दिन में एक बार',
      'freq_twice': 'दिन में दो बार',
      'freq_thrice': 'दिन में तीन बार',
      'freq_custom': 'आवश्यकतानुसार',
      'save': 'दवा सहेजें',
      'required': 'कृपया सभी फ़ील्ड भरें।',
      'times_title': 'समय निर्धारण',
      'morning': 'सुबह',
      'afternoon': 'दोपहर',
      'night': 'रात',
      'time1': 'समय 1',
      'time2': 'समय 2',
      'pick_time': 'समय सेट करें',
      'photo_source_title': 'फ़ोटो स्रोत चुनें',
      'photo_camera': 'कैमरा',
      'photo_gallery': 'गैलरी',
      'cancel': 'रद्द करें',
    },
    'te': {
      'title': 'మందు వివరాలు',
      'photo_label': 'మందు ఫోటో',
      'photo_hint': 'మందు చిత్రాన్ని అప్‌లోడ్ చేయడానికి నొక్కండి\nJPG/PNG • గరిష్టం 5 MB',
      'photo_change': 'మార్చు',
      'photo_error': 'JPG/PNG ఫైళ్లు మాత్రమే, 5 MB కంటే తక్కువ.',
      'med_name': 'మందు పేరు',
      'dosage': 'మోతాదు (ఉదా. 500mg, 1 టాబ్లెట్)',
      'frequency': 'తరచుదనం',
      'freq_once': 'రోజుకు ఒకసారి',
      'freq_twice': 'రోజుకు రెండుసార్లు',
      'freq_thrice': 'రోజుకు మూడుసార్లు',
      'freq_custom': 'అవసరమైనప్పుడు',
      'save': 'మందు సేవ్ చేయండి',
      'required': 'దయచేసి అన్ని ఫీల్డ్‌లు నింపండి.',
      'times_title': 'సమయ షెడ్యూల్',
      'morning': 'ఉదయం',
      'afternoon': 'మధ్యాహ్నం',
      'night': 'రాత్రి',
      'time1': 'సమయం 1',
      'time2': 'సమయం 2',
      'pick_time': 'సమయం సెట్ చేయండి',
      'photo_source_title': 'ఫోటో మూలాన్ని ఎంచుకోండి',
      'photo_camera': 'కెమెరా',
      'photo_gallery': 'గ్యాలరీ',
      'cancel': 'రద్దు చేయి',
    },
    'bn': {
      'title': 'ওষুধের বিবরণ',
      'photo_label': 'ওষুধের ছবি',
      'photo_hint': 'ওষুধের ছবি আপলোড করতে ট্যাপ করুন\nJPG/PNG • সর্বোচ্চ 5 MB',
      'photo_change': 'পরিবর্তন',
      'photo_error': 'শুধুমাত্র JPG/PNG, 5 MB এর কম।',
      'med_name': 'ওষুধের নাম',
      'dosage': 'ডোজ (যেমন 500mg, ১ ট্যাবলেট)',
      'frequency': 'কতবার',
      'freq_once': 'দিনে একবার',
      'freq_twice': 'দিনে দুইবার',
      'freq_thrice': 'দিনে তিনবার',
      'freq_custom': 'প্রয়োজন মতো',
      'save': 'ওষুধ সেভ করুন',
      'required': 'অনুগ্রহ করে সব ক্ষেত্র পূরণ করুন।',
      'times_title': 'সময়সূচি',
      'morning': 'সকাল',
      'afternoon': 'দুপুর',
      'night': 'রাত',
      'time1': 'সময় ১',
      'time2': 'সময় ২',
      'pick_time': 'সময় সেট করুন',
      'photo_source_title': 'ছবির উৎস নির্বাচন করুন',
      'photo_camera': 'ক্যামেরা',
      'photo_gallery': 'গ্যালারি',
      'cancel': 'বাতিল',
    },
    'mr': {
      'title': 'औषध तपशील',
      'photo_label': 'औषधाचा फोटो',
      'photo_hint': 'औषधाची प्रतिमा अपलोड करण्यासाठी टॅप करा\nJPG/PNG • कमाल 5 MB',
      'photo_change': 'बदला',
      'photo_error': 'फक्त JPG/PNG, 5 MB पेक्षा कमी.',
      'med_name': 'औषधाचे नाव',
      'dosage': 'डोस (उदा. 500mg, 1 टॅबलेट)',
      'frequency': 'वारंवारता',
      'freq_once': 'दिवसातून एकदा',
      'freq_twice': 'दिवसातून दोनदा',
      'freq_thrice': 'दिवसातून तीनदा',
      'freq_custom': 'गरजेनुसार',
      'save': 'औषध सेव्ह करा',
      'required': 'कृपया सर्व फील्ड भरा.',
      'times_title': 'वेळ निर्धारण',
      'morning': 'सकाळ',
      'afternoon': 'दुपार',
      'night': 'रात्र',
      'time1': 'वेळ १',
      'time2': 'वेळ २',
      'pick_time': 'वेळ सेट करा',
      'photo_source_title': 'फोटो स्रोत निवडा',
      'photo_camera': 'कॅमेरा',
      'photo_gallery': 'गॅलरी',
      'cancel': 'रद्द करा',
    },
  };

  // ── Build time slots based on selected frequency ─────────────────────────────
  void _updateTimeSlots(String freqKey, Map<String, String> lang) {
  List<_TimeSlot> slots = [];

  if (freqKey == 'once') {
    slots = [
      _TimeSlot(
        label: lang['time1']!,
        icon: Icons.access_time_rounded,
        color: const Color(0xFF2D7DD2),
        preset: TimeOfDay.now(),
      ),
    ];
  } 
  else if (freqKey == 'twice') {
    slots = [
      _TimeSlot(
        label: lang['time1']!,
        icon: Icons.access_time_rounded,
        color: const Color(0xFF2D7DD2),
        preset: TimeOfDay.now(),
      ),
      _TimeSlot(
        label: lang['time2']!,
        icon: Icons.access_time_rounded,
        color: const Color(0xFF10B981),
        preset: TimeOfDay.now(),
      ),
    ];
  } 
  else if (freqKey == 'thrice') {
    slots = [
      _TimeSlot(
        label: lang['time1']!,
        icon: Icons.access_time_rounded,
        color: const Color(0xFF2D7DD2),
        preset: TimeOfDay.now(),
      ),
      _TimeSlot(
        label: lang['time2']!,
        icon: Icons.access_time_rounded,
        color: const Color(0xFF10B981),
        preset: TimeOfDay.now(),
      ),
      _TimeSlot(
        label: lang['night']!,
        icon: Icons.access_time_rounded,
        color: const Color(0xFF6366F1),
        preset: TimeOfDay.now(),
      ),
    ];
  } 
  else {
    slots = [];
  }

  for (final s in slots) {
    s.selected = s.preset;
  }

  setState(() => _timeSlots = slots);
}

  // ── Photo picker ──────────────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final lang = translations[widget.languageCode] ?? translations['en']!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text(lang['photo_source_title']!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sourceBtn(Icons.camera_alt_rounded, lang['photo_camera']!,
                      const Color(0xFF2D7DD2), () => Navigator.pop(ctx, ImageSource.camera)),
                  _sourceBtn(Icons.photo_library_rounded, lang['photo_gallery']!,
                      Colors.indigo, () => Navigator.pop(ctx, ImageSource.gallery)),
                ],
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lang['cancel']!, style: const TextStyle(color: Colors.grey)),
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
      setState(() { _photoError = lang['photo_error']; _medicinePhoto = null; });
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      setState(() { _photoError = lang['photo_error']; _medicinePhoto = null; });
      return;
    }
    setState(() { 
      _medicinePhoto = picked; 
      _photoBytes = bytes;
      _photoError = null; 
    });
  }

  Widget _sourceBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return PopScope(
      canPop: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Time picker for a single slot ────────────────────────────────────────────
  Future<void> _pickTimeForSlot(_TimeSlot slot) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: slot.selected ?? slot.preset,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) setState(() => slot.selected = picked);
  }

  // ── Save ──────────────────────────────────────────────────────────────────────
  void _handleSave() {
    final lang = translations[widget.languageCode] ?? translations['en']!;

    if (_nameController.text.trim().isEmpty ||
        _dosageController.text.trim().isEmpty ||
        _selectedFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang['required']!), backgroundColor: Colors.red),
      );
      return;
    }

    final allTimesSet = _timeSlots.every((s) => s.selected != null);
    if (_timeSlots.isNotEmpty && !allTimesSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang['required']!), backgroundColor: Colors.red),
      );
      return;
    }

    final timeStrings = _timeSlots
        .map((s) => '${s.label}: ${s.selected!.format(context)}')
        .toList();

    Navigator.pop(context, {
      'photo': _medicinePhoto?.path ?? '',
      'photoBytes': _photoBytes,
      'name': _nameController.text.trim(),
      'dosage': _dosageController.text.trim(),
      'frequency': _selectedFrequency ?? '',
      'time': timeStrings.isEmpty ? 'As needed' : timeStrings.join(' | '),
      'times': timeStrings,
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = translations[widget.languageCode] ?? translations['en']!;

    final freqOptions = {
      'once': lang['freq_once']!,
      'twice': lang['freq_twice']!,
      'thrice': lang['freq_thrice']!,
      'custom': lang['freq_custom']!,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D7DD2),
        foregroundColor: Colors.white,
        title: Text(lang['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _photoError != null ? Colors.red : const Color(0xFF2D7DD2),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D7DD2).withValues(alpha: 0.15),
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                    image: _medicinePhoto != null
                        ? DecorationImage(
                            image: kIsWeb 
                                ? MemoryImage(_photoBytes!)
                                : NetworkImage(_medicinePhoto!.path), // Fallback for mobile
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _medicinePhoto == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.medication_rounded, size: 44, color: Color(0xFF2D7DD2)),
                            const SizedBox(height: 6),
                            Text(lang['photo_label']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF2D7DD2), fontWeight: FontWeight.w600)),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D7DD2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(lang['photo_change']!,
                                style: const TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ),
                ),
              ),
            ),
            if (_photoError != null) ...[
              const SizedBox(height: 8),
              Center(child: Text(_photoError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
            ],
            const SizedBox(height: 6),
            Center(
              child: Text(lang['photo_hint']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),

            const SizedBox(height: 28),

            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    _label(lang['med_name']!),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: _inputDeco(hint: 'e.g. Paracetamol', icon: Icons.medication_liquid_rounded),
                    ),

                    const SizedBox(height: 20),

                    _label(lang['dosage']!),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dosageController,
                      decoration: _inputDeco(hint: 'e.g. 500mg', icon: Icons.scale_rounded),
                    ),

                    const SizedBox(height: 20),

                    _label(lang['frequency']!),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFrequency,
                      decoration: _inputDeco(hint: lang['freq_once']!, icon: Icons.repeat_rounded),
                      items: freqOptions.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedFrequency = v);
                        _updateTimeSlots(v, lang);
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (_timeSlots.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.schedule_rounded, color: Color(0xFF2D7DD2), size: 20),
                        const SizedBox(width: 8),
                        Text(lang['times_title']!,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: Color(0xFF2D7DD2))),
                      ]),
                      const SizedBox(height: 16),
                      ..._timeSlots.map((slot) => _buildTimeSlotRow(slot, context)),
                    ],
                  ),
                ),
              ),
            ],

            if (_selectedFrequency == 'custom') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No fixed schedule — take as needed.',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 32),

            // ── SAVE BUTTON ──────────────────────────────────────────────────
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7DD2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF2D7DD2).withValues(alpha: 0.4),
              ),
              onPressed: _handleSave,
              child: Text(lang['save']!,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Single time-slot row ──────────────────────────────────────────────────────
  Widget _buildTimeSlotRow(_TimeSlot slot, BuildContext context) {
    final isSet = slot.selected != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _pickTimeForSlot(slot),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSet ? slot.color.withValues(alpha: 0.08) : const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSet ? slot.color.withValues(alpha: 0.5) : Colors.grey.shade300,
              width: isSet ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: slot.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(slot.icon, color: slot.color, size: 22),
              ),
              const SizedBox(width: 14),
              // Label + sub-label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.label,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: slot.color)),
                    if (isSet)
                      Text(
                        _friendlyTime(slot.selected!),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              // Time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSet ? slot.color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSet ? slot.selected!.format(context) : '-- : --',
                  style: TextStyle(
                    color: isSet ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Friendly description of the time of day
  String _friendlyTime(TimeOfDay t) {
    if (t.hour >= 5 && t.hour < 12) return 'Good Morning ☀️';
    if (t.hour >= 12 && t.hour < 17) return 'Afternoon 🌤';
    if (t.hour >= 17 && t.hour < 21) return 'Evening 🌇';
    return 'Night 🌙';
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: Color(0xFF4A5568), letterSpacing: 0.3));

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF2D7DD2), size: 20),
      filled: true,
      fillColor: const Color(0xFFF4F6FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2D7DD2), width: 2)),
    );
  }
}

// ── Time slot model ──────────────────────────────────────────────────────────
class _TimeSlot {
  final String label;
  final IconData icon;
  final Color color;
  final TimeOfDay preset;
  TimeOfDay? selected;

  _TimeSlot({
    required this.label,
    required this.icon,
    required this.color,
    required this.preset,
  });
}
