import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'medicine_details_screen.dart';
import 'camera_verification_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:fl_chart/fl_chart.dart';
// import '../main.dart'; // Removed unused import

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const HomeScreen({super.key, required this.profileData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _adherenceRecords = [];
  bool _isLoading = true;
  late Map<String, dynamic> _currentProfile;
  Timer? _webTimer;
  final Set<String> _alertedTimes = {};

  @override
  void initState() {
    super.initState();
    _currentProfile = Map<String, dynamic>.from(widget.profileData);
    _fetchMedicines();
    if (kIsWeb) {
      _startWebTimer();
    }

    // Listen for notification action clicks
    NotificationService.onNotificationClick.stream.listen((actionId) {
      if (actionId == 'action_taken') {
        _handleNotificationAction();
      }
    });
  }

  void _handleNotificationAction() async {
    // Open camera for the first medicine in the list as a fallback or a generic verification
    if (_medicines.isNotEmpty) {
      _handleLogAdherence(_medicines.first, 'taken');
    } else {
      // Just open camera if no medicines are loaded yet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraVerificationScreen(profileData: _currentProfile),
        ),
      );
    }
  }

  @override
  void dispose() {
    _webTimer?.cancel();
    super.dispose();
  }

  void _startWebTimer() {
    _webTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkMedicinesForAlert();
    });
  }

  void _checkMedicinesForAlert() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    // Format should be "H:MM AM/PM" or "HH:MM AM/PM"
    final currentTimeStr = "$displayHour:${minute.toString().padLeft(2, '0')} $period";
    final currentTimeStrWithZero = "${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period";
    
    for (var med in _medicines) {
      final times = med['times'] as List<dynamic>? ?? [];
      for (var t in times) {
        final medTime = (t as String).split(': ').last.trim();
        
        // Match both formats (with or without leading zero)
        if (medTime == currentTimeStr || medTime == currentTimeStrWithZero) {
          final alertKey = "${med['id']}_$medTime";
          if (!_alertedTimes.contains(alertKey)) {
            _alertedTimes.add(alertKey);
            
            // Trigger System Notification on Web
            NotificationService.showImmediateNotification(
              id: med['id'].hashCode,
              title: "Time for ${med['name']}",
              body: "Dosage: ${med['dosage']}",
            );
            
            _showWebAlert(med, medTime);
          }
        }
      }
    }
    
    // Clear old alerted times every hour
    if (minute == 0) _alertedTimes.clear();
  }

  void _showWebAlert(Map<String, dynamic> medicine, String time) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.alarm_on_rounded, color: Colors.teal, size: 28),
            const SizedBox(width: 10),
            const Text('Medicine Reminder'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time for: ${medicine['name']}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Dosage: ${medicine['dosage']}'),
            const SizedBox(height: 4),
            Text('Scheduled: $time'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogAdherence(medicine, 'missed');
            },
            child: const Text('Skip', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleLogAdherence(medicine, 'taken');
            },
            child: const Text('Taken'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchMedicines() async {
    final userId = _currentProfile['email'] as String? ?? 'guest';
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMedicines(userId);
      if (mounted) {
        setState(() {
          _medicines = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
        _scheduleAllNotifications();
      }
    } catch (e) {
      debugPrint("Error fetching medicines: $e");
    } finally {
      _fetchProgress();
    }
  }

  Future<void> _fetchProgress() async {
    final userId = _currentProfile['email'] as String? ?? 'guest';
    try {
      final records = await ApiService.getProgress(userId);
      if (mounted) {
        setState(() {
          _adherenceRecords = List<Map<String, dynamic>>.from(records);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching progress: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleAllNotifications() async {
    if (ApiService.isWeb) return;
    await NotificationService.cancelAll();
    for (var med in _medicines) {
      final times = med['times'] as List<dynamic>? ?? [];
      for (var t in times) {
        final timeStr = (t as String).split(': ').last;
        try {
          final timeParts = timeStr.split(' ');
          final hhmm = timeParts[0].split(':');
          int hour = int.parse(hhmm[0]);
          int minute = int.parse(hhmm[1]);
          if (timeParts[1] == 'PM' && hour < 12) hour += 12;
          if (timeParts[1] == 'AM' && hour == 12) hour = 0;

          final now = DateTime.now();
          var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }

          await NotificationService.scheduleNotification(
            id: ((med['id']?.hashCode ?? med['name'].hashCode) + t.hashCode).abs(),
            title: 'Time for ${med['name']}',
            body: 'Dosage: ${med['dosage']}',
            scheduledTime: scheduledTime,
          );
        } catch (e) {
          debugPrint("Error scheduling for $t: $e");
        }
      }
    }
  }

  Future<void> _openMedicineScreen() async {
    final langCode = _currentProfile['languageCode'] as String? ?? 'en';
    final userId = _currentProfile['email'] as String? ?? 'guest';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineDetailsScreen(languageCode: langCode),
      ),
    );

    if (result != null) {
      final medicineData = Map<String, dynamic>.from(result);
      setState(() => _isLoading = true);

      String photoUrl = "";
      final localPhoto = medicineData['photo'] as String? ?? '';
      final photoBytes = medicineData['photoBytes'] as Uint8List?;
      
      if (localPhoto.isNotEmpty && !localPhoto.startsWith('http')) {
        final uploadedUrl = await ApiService.uploadImage(localPhoto, bytes: photoBytes);
        if (uploadedUrl != null) photoUrl = uploadedUrl;
      } else {
        photoUrl = localPhoto;
      }
      
      final success = await ApiService.addMedicine(
        name: medicineData['name'] ?? '',
        dosage: medicineData['dosage'] ?? '',
        time: medicineData['time'] ?? '',
        userId: userId,
        frequency: medicineData['frequency'] ?? '',
        times: medicineData['times'] ?? [],
        photo: photoUrl,
      );

      if (success) {
        _fetchMedicines();
      } else {
        if (mounted) {
          setState(() {
            _medicines.add({...medicineData, 'photo': photoUrl});
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _editMedicine(Map<String, dynamic> medicine) async {
    final langCode = _currentProfile['languageCode'] as String? ?? 'en';
    final userId = _currentProfile['email'] as String? ?? 'guest';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineDetailsScreen(
          languageCode: langCode,
          initialMedicine: medicine,
        ),
      ),
    );

    if (result != null) {
      final updatedData = Map<String, dynamic>.from(result);
      if (mounted) {
        setState(() => _isLoading = true);
      }

      String photoUrl = updatedData['photo'] ?? '';
      if (photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
        final uploadedUrl = await ApiService.uploadImage(photoUrl);
        if (uploadedUrl != null) photoUrl = uploadedUrl;
      }

      final success = await ApiService.updateMedicine(
        medId: medicine['id'],
        name: updatedData['name'] ?? '',
        dosage: updatedData['dosage'] ?? '',
        time: updatedData['time'] ?? '',
        userId: userId,
        frequency: updatedData['frequency'] ?? '',
        times: updatedData['times'] ?? [],
        photo: photoUrl,
      );

      if (success) {
        _fetchMedicines();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleLogAdherence(Map<String, dynamic> medicine, String status) async {
    final userId = _currentProfile['email'] as String? ?? 'guest';
    final medId = medicine['id'] as String? ?? '';
    final medName = medicine['name'] as String? ?? 'Medicine';

    if (status == 'taken') {
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CameraVerificationScreen(profileData: _currentProfile),
        ),
      );
      if (verified != true) return;
    }

    final success = await ApiService.logAdherence(
      userId: userId,
      medicineId: medId,
      medicineName: medName,
      status: status,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged: $medName as $status'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
      _fetchProgress();
    }
  }

  Future<void> _deleteMedicine(String medId) async {
    final success = await ApiService.deleteMedicine(medId);
    if (success) {
      _fetchMedicines();
    }
  }

  final Map<String, Map<String, String>> translations = {
    'en': {
      'home': 'Home', 'profile': 'Profile', 'progress': 'Progress', 'shop': 'Shop',
      'welcome': 'Welcome back',
      'upcoming': 'My Medications', 'no_meds': 'No medications added yet.',
      'next_dose': 'Next dose',
      'progress_title': 'Your Progress',
      'progress_sub': 'Track your medication adherence here.',
      'shop_title': 'Med Shop',
      'shop_sub': 'Browse and order medications.',
      'add_med': 'Add Medicine',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
    },
    'ta': {
      'home': 'முகப்பு', 'profile': 'சுயவிவரம்', 'progress': 'முன்னேற்றம்', 'shop': 'கடை',
      'welcome': 'மீண்டும் வரவேற்கிறோம்',
      'upcoming': 'என் மருந்துகள்', 'no_meds': 'மருந்துகள் எதுவும் சேர்க்கப்படவில்லை.',
      'next_dose': 'அடுத்த டோஸ்',
      'progress_title': 'உங்கள் முன்னேற்றம்',
      'progress_sub': 'இங்கே உங்கள் மருந்து இணக்கத்தை கண்காணிக்கவும்.',
      'shop_title': 'மருந்து கடை',
      'shop_sub': 'மருந்துகளை உலாவி ஆர்டர் செய்யுங்கள்.',
      'add_med': 'மருந்து சேர்',
      'logout': 'வெளியேறு',
      'logout_confirm': 'நீங்கள் வெளியேற விரும்புகிறீர்களா?',
      'cancel': 'ரத்து செய்',
    },
    'hi': {
      'home': 'होम', 'profile': 'प्रोफ़ाइल', 'progress': 'प्रगति', 'shop': 'शॉप',
      'welcome': 'वापस स्वागत है',
      'upcoming': 'मेरी दवाइयाँ', 'no_meds': 'कोई दवा नहीं जोड़ी गई।',
      'next_dose': 'अगली खुराक',
      'progress_title': 'आपकी प्रगति',
      'progress_sub': 'यहाँ अपनी दवाई अनुपालन ट्रैक करें।',
      'shop_title': 'मेड शॉप',
      'shop_sub': 'दवाइयाँ ब्राउज़ करें और ऑर्डर करें।',
      'add_med': 'दवा जोड़ें',
      'logout': 'लॉगआउट',
      'logout_confirm': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
    },
    'te': {
      'home': 'హోమ్', 'profile': 'ప్రొఫైల్', 'progress': 'పురోగతి', 'shop': 'షాప్',
      'welcome': 'మళ్ళీ స్వాగతం',
      'upcoming': 'నా మందులు', 'no_meds': 'మందులు ఏవీ జోడించబడలేదు.',
      'next_dose': 'తదుపరి మోతాదు',
      'progress_title': 'మీ పురోగతి',
      'progress_sub': 'ఇక్కడ మీ మందుల అనుపాలనను ట్రాక్ చేయండి.',
      'shop_title': 'మెడ్ షాప్',
      'shop_sub': 'మందులను బ్రౌజ్ చేసి ఆర్డర్ చేయండి.',
      'add_med': 'మందు జోడించు',
      'logout': 'లాగ్అవుట్',
      'logout_confirm': 'మీరు నిజంగా లాగ్అవుట్ చేయాలనుకుంటున్నారా?',
      'cancel': 'రద్దు చేయి',
    },
    'bn': {
      'home': 'হোম', 'profile': 'প্রোফাইল', 'progress': 'অগ্রগতি', 'shop': 'শপ',
      'welcome': 'আবার স্বাগতম',
      'upcoming': 'আমার ওষুধ', 'no_meds': 'কোনো ওষুধ যোগ করা হয়নি।',
      'next_dose': 'পরবর্তী ডোজ',
      'progress_title': 'আপনার অগ্রগতি',
      'progress_sub': 'এখানে ওষুধ মেনে চলার অগ্রগতি ট্র্যাক করুন।',
      'shop_title': 'মেড শপ',
      'shop_sub': 'ওষুধ ব্রাউজ করুন এবং অর্ডার করুন।',
      'add_med': 'ওষুধ যোগ করুন',
      'logout': 'লগআউট',
      'logout_confirm': 'আপনি কি সত্যিই লগআউট করতে চান?',
      'cancel': 'বাতিল',
    },
    'mr': {
      'home': 'होम', 'profile': 'प्रोफाइल', 'progress': 'प्रगती', 'shop': 'शॉप',
      'welcome': 'पुन्हा स्वागत',
      'upcoming': 'माझी औषधे', 'no_meds': 'कोणतीही औषधे जोडली नाहीत.',
      'next_dose': 'पुढील डोस',
      'progress_title': 'तुमची प्रगती',
      'progress_sub': 'येथे तुमच्या औषध अनुपालनाचा मागोवा घ्या.',
      'shop_title': 'मेड शॉप',
      'shop_sub': 'औषधे ब्राउझ करा आणि ऑर्डर करा.',
      'add_med': 'औषध जोडा',
      'logout': 'लॉगआउट',
      'logout_confirm': 'तुम्हाला खरोखर लॉगआउट करायचे आहे का?',
      'cancel': 'रद्द करा',
    },
  };

  @override
  Widget build(BuildContext context) {
    final langCode = _currentProfile['languageCode'] as String? ?? 'en';
    final lang = translations[langCode] ?? translations['en']!;
    final name = (_currentProfile['name'] as String?)?.trim() ?? '';

    final pages = [
      _HomeTab(
        lang: lang,
        profileData: _currentProfile,
        medicines: _medicines,
        onAddMedicine: _openMedicineScreen,
        onEditMedicine: _editMedicine,
        onDeleteMedicine: _deleteMedicine,
        onLogAdherence: _handleLogAdherence,
      ),
      ProfileScreen(
        profileData: _currentProfile,
        onProfileUpdate: (updated) async {
          setState(() => _currentProfile = updated);
          await ApiService.updateProfile(updated);
        },
      ),
      _ProgressTab(
        lang: lang,
        medicines: _medicines,
        adherenceRecords: _adherenceRecords,
      ),
      _ShopTab(lang: lang),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 10),
            const Text('Pillzy',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: Colors.white),
            tooltip: 'Schedule 2 Min Test',
            onPressed: () {
              final testTime = DateTime.now().add(const Duration(minutes: 2));
              NotificationService.scheduleNotification(
                id: 999,
                title: "2 Minute Test!",
                body: "Time is up! Your 2-minute test worked.",
                scheduledTime: testTime,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Test scheduled for 2 mins from now.")),
              );
            },
          ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.web_rounded, color: Colors.white),
              tooltip: 'Test Web Alert',
              onPressed: () {
                debugPrint("Web Alert Button Clicked!");
                if (_medicines.isNotEmpty) {
                  _showWebAlert(_medicines.first, "TEST TIME");
                } else {
                  _showWebAlert({
                    'id': 'test_id',
                    'name': 'Test Medicine', 
                    'dosage': '1 pill'
                  }, "NOW");
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.notification_important_rounded, color: Colors.white),
            tooltip: 'Test Mobile Notification',
            onPressed: () {
              NotificationService.showImmediateNotification(
                id: 12345,
                title: "Pillzy Test Alert",
                body: "If you see this, notifications are working!",
              );
            },
          ),
          if (name.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(name.split(' ').first,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_rounded), label: lang['home']!),
          NavigationDestination(icon: const Icon(Icons.person_rounded), label: lang['profile']!),
          NavigationDestination(icon: const Icon(Icons.bar_chart_rounded), label: lang['progress']!),
          NavigationDestination(icon: const Icon(Icons.local_pharmacy_rounded), label: lang['shop']!),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, String> lang;
  final Map<String, dynamic> profileData;
  final List<Map<String, dynamic>> medicines;
  final VoidCallback onAddMedicine;
  final Function(Map<String, dynamic>) onEditMedicine;
  final Function(String) onDeleteMedicine;
  final Function(Map<String, dynamic>, String) onLogAdherence;

  const _HomeTab({
    required this.lang,
    required this.profileData,
    required this.medicines,
    required this.onAddMedicine,
    required this.onEditMedicine,
    required this.onDeleteMedicine,
    required this.onLogAdherence,
  });

  @override
  Widget build(BuildContext context) {
    final name = (profileData['name'] as String?)?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty) ...[
            Text('${lang['welcome']!}, $name 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(lang['upcoming']!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onAddMedicine,
                icon: const Icon(Icons.add_circle_rounded, size: 18),
                label: Flexible(child: Text(lang['add_med']!, overflow: TextOverflow.ellipsis)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: medicines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medication_rounded, size: 56, color: Colors.teal.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(lang['no_meds']!, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: medicines.length,
                    itemBuilder: (_, i) => _MedCard(
                      medicine: medicines[i],
                      nextDoseLabel: lang['next_dose']!,
                      onEdit: onEditMedicine,
                      onDelete: onDeleteMedicine,
                      onLogAdherence: onLogAdherence,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatCard(icon: Icons.check_circle_outline_rounded, label: '7', sublabel: 'Days streak', color: Colors.green),
                const SizedBox(width: 8),
                _StatCard(icon: Icons.medication_rounded, label: '${medicines.length}', sublabel: 'Active meds', color: Colors.teal),
                const SizedBox(width: 8),
                _StatCard(icon: Icons.notifications_active_rounded, label: '1', sublabel: 'Alert today', color: Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final String nextDoseLabel;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;
  final Function(Map<String, dynamic>, String) onLogAdherence;

  const _MedCard({
    required this.medicine,
    required this.nextDoseLabel,
    required this.onEdit,
    required this.onDelete,
    required this.onLogAdherence,
  });

  @override
  Widget build(BuildContext context) {
    final photoPath = medicine['photo'] as String? ?? '';
    final times = medicine['times'] as List<dynamic>?;
    final timeString = medicine['time'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.teal.shade50,
              backgroundImage: photoPath.isNotEmpty
                  ? (photoPath.startsWith('http')
                      ? NetworkImage(photoPath)
                      : (kIsWeb ? const AssetImage('assets/pill_icon.png') : NetworkImage(photoPath))) as ImageProvider
                  : null,
              child: photoPath.isEmpty
                  ? const Icon(Icons.medication, color: Colors.teal, size: 26)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medicine['name'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 2),
                  Text(
                    '${medicine['dosage'] ?? ''}  •  ${medicine['frequency'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  if (times != null && times.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: times.map<Widget>((t) {
                        final parts = (t as String).split(': ');
                        final slotLabel = parts.length == 2 ? parts[0] : '';
                        final slotTime = parts.length == 2 ? parts[1] : t;
                        final color = _slotColor(slotLabel);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.4)),
                          ),
                          child: IntrinsicWidth(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_slotIcon(slotLabel), size: 12, color: color),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    slotLabel.isNotEmpty ? '$slotLabel · $slotTime' : slotTime,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else if (timeString.isNotEmpty)
                    Text('$nextDoseLabel: $timeString',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  onPressed: () => onLogAdherence(medicine, 'taken'),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  tooltip: 'Mark as Taken',
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit(medicine);
                    } else if (val == 'delete') {
                      onDelete(medicine['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.teal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _slotColor(String label) {
    final l = label.toLowerCase();
    if (l.contains('morning') || l.contains('காலை') || l.contains('सुबह') ||
        l.contains('ఉదయం') || l.contains('সকাল') || l.contains('सकाळ')) {
      return const Color(0xFFF59E0B);
    }
    if (l.contains('afternoon') || l.contains('மதியம்') || l.contains('दोपहर') ||
        l.contains('మధ్యాహ్నం') || l.contains('দুপুর') || l.contains('दुपार')) {
      return const Color(0xFF10B981);
    }
    if (l.contains('night') || l.contains('இரவு') || l.contains('रात') ||
        l.contains('రాత్రి') || l.contains('রাত') || l.contains('रात्र')) {
      return const Color(0xFF6366F1);
    }
    return Colors.teal;
  }

  IconData _slotIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('morning') || l.contains('காலை') || l.contains('सुबह') ||
        l.contains('ఉదయం') || l.contains('সকাল') || l.contains('सकाळ')) {
      return Icons.wb_sunny_rounded;
    }
    if (l.contains('afternoon') || l.contains('மதியம்') || l.contains('दोपहर') ||
        l.contains('మధ్యాహ్నం') || l.contains('দুপুর') || l.contains('दुपार')) {
      return Icons.wb_cloudy_rounded;
    }
    if (l.contains('night') || l.contains('இரவு') || l.contains('रात') ||
        l.contains('రాత్రి') || l.contains('রাত') || l.contains('रात्र')) {
      return Icons.nightlight_round;
    }
    return Icons.schedule_rounded;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          Text(sublabel,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── PLACEHOLDER TAB ───────────────────────────────────────────────────────────
class _ProgressTab extends StatelessWidget {
  final Map<String, String> lang;
  final List<Map<String, dynamic>> medicines;
  final List<Map<String, dynamic>> adherenceRecords;
  const _ProgressTab({
    required this.lang,
    required this.medicines,
    required this.adherenceRecords,
  });

  @override
  Widget build(BuildContext context) {
    int taken = adherenceRecords.where((r) => r['status'] == 'taken').length;
    int missed = adherenceRecords.where((r) => r['status'] == 'missed').length;
    int total = taken + missed;
    double takenPct = total == 0 ? 0 : (taken / total);
    String rate = "${(takenPct * 100).toInt()}%";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang['progress_title']!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(lang['progress_sub']!,
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          
          // ── PIE CHART CARD ──────────────────────────────────────────────
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 50,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                              color: Colors.teal,
                              value: total == 0 ? 1 : taken.toDouble(),
                              title: '',
                              radius: 25,
                              badgeWidget: total == 0 ? null : _buildBadge(Icons.check, Colors.white, Colors.teal),
                              badgePositionPercentageOffset: 0.98,
                            ),
                            PieChartSectionData(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              value: total == 0 ? 0 : missed.toDouble(),
                              title: '',
                              radius: 20,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(rate, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const Text('Success', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.teal, 'Taken', '$taken'),
                      const SizedBox(height: 12),
                      _buildLegendItem(Colors.redAccent, 'Missed', '$missed'),
                      const SizedBox(height: 12),
                      _buildLegendItem(Colors.grey, 'Total', '$total'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (adherenceRecords.isEmpty)
            const Text('No recent activity recorded.',
                style: TextStyle(color: Colors.grey))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: adherenceRecords.length > 5 ? 5 : adherenceRecords.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = adherenceRecords[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: record['status'] == 'taken'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    child: Icon(
                      record['status'] == 'taken' ? Icons.check : Icons.close,
                      color: record['status'] == 'taken' ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(record['medicine_name'] ?? 'Unknown'),
                  subtitle: Text(record['timestamp']?.split('T')[0] ?? ''),
                  trailing: Text(
                    record['status']?.toUpperCase() ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: record['status'] == 'taken' ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, color: iconColor, size: 12),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _ShopTab extends StatelessWidget {
  final Map<String, String> lang;
  const _ShopTab({required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(lang['shop_title']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(lang['shop_sub']!, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        _buildShopItem('Paracetamol', '₹45', 'Fever & Pain Relief'),
        _buildShopItem('Vitamin C', '₹120', 'Immunity Booster'),
        _buildShopItem('Amoxicillin', '₹85', 'Antibiotic'),
        _buildShopItem('Omeprazole', '₹60', 'Acidity Relief'),
      ],
    );
  }

  Widget _buildShopItem(String name, String price, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: const Icon(Icons.shopping_bag_outlined, color: Colors.teal),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 4),
            const Text('Buy', style: TextStyle(fontSize: 10, color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
