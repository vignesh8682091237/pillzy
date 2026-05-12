import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

enum VerificationStep { pillDetection, mouthOpening, swallowing, completed }

class CameraVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const CameraVerificationScreen({super.key, required this.profileData});

  @override
  State<CameraVerificationScreen> createState() => _CameraVerificationScreenState();
}

class _CameraVerificationScreenState extends State<CameraVerificationScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitialized = false;
  
  // Verification State
  VerificationStep _currentStep = VerificationStep.pillDetection;
  String _instruction = "Show the pill in your palm";
  double _verificationProgress = 0.0;

  // Timers and logic control
  int _secondsElapsed = 0;
  Timer? _overallStepTimer;
  bool _canShowManualButton = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _startCurrentStepTimer();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _instruction = "No camera found");
        return;
      }

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        front, 
        ResolutionPreset.medium, 
        enableAudio: false,
        imageFormatGroup: kIsWeb ? ImageFormatGroup.jpeg : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) setState(() => _instruction = "Camera initialization failed: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overallStepTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startCurrentStepTimer() {
    _overallStepTimer?.cancel();
    _secondsElapsed = 0;
    _canShowManualButton = false;

    _overallStepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        _secondsElapsed++;
        
        // At 6 seconds, show the manual button (gives 4s for manual entry)
        if (_secondsElapsed >= 6) {
          _canShowManualButton = true;
        }

        // At 10 seconds, automatically move to the next stage (Total 30s for 3 steps)
        if (_secondsElapsed >= 10) {
          _handleAutoAdvance();
        }
      });
    });
  }

  void _handleAutoAdvance() {
    if (_currentStep == VerificationStep.completed) return;

    setState(() {
      if (_currentStep == VerificationStep.pillDetection) {
        _instruction = "Now bring it to your mouth.";
        _verificationProgress = 0.33;
        _currentStep = VerificationStep.mouthOpening;
      } else if (_currentStep == VerificationStep.mouthOpening) {
        _instruction = "Now swallow the pill.";
        _verificationProgress = 0.66;
        _currentStep = VerificationStep.swallowing;
      } else if (_currentStep == VerificationStep.swallowing) {
        _completeVerification();
        return;
      }
      
      // Reset timer for the next step
      _secondsElapsed = 0;
      _canShowManualButton = false;
    });
  }

  void _completeVerification() {
    if (_currentStep == VerificationStep.completed) return;
    
    _overallStepTimer?.cancel();
    setState(() {
      _currentStep = VerificationStep.completed;
      _instruction = "Verification Successful!";
      _verificationProgress = 1.0;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _cameraController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1080,
                  height: _cameraController!.value.previewSize?.width ?? 1920,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          // Glass Overlay
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildVerificationUI(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "Pillzy Verification",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 48), 
        ],
      ),
    );
  }

  Widget _buildVerificationUI() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepIcon(),
          const SizedBox(height: 20),
          Text(
            _instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _verificationProgress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                _currentStep == VerificationStep.completed ? Colors.greenAccent : Colors.tealAccent,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Time: ${_secondsElapsed}s",
            style: const TextStyle(color: Colors.tealAccent, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_canShowManualButton && _currentStep != VerificationStep.completed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleAutoAdvance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  _currentStep == VerificationStep.pillDetection ? "Next: Pill Detected" :
                  _currentStep == VerificationStep.mouthOpening ? "Next: Mouth Open" : "Finish Verification",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepIcon() {
    IconData icon;
    Color color;

    switch (_currentStep) {
      case VerificationStep.pillDetection:
        icon = Icons.medication_rounded;
        color = Colors.orangeAccent;
        break;
      case VerificationStep.mouthOpening:
        icon = Icons.face_retouching_natural;
        color = Colors.blueAccent;
        break;
      case VerificationStep.swallowing:
        icon = Icons.check_circle_outline;
        color = Colors.tealAccent;
        break;
      case VerificationStep.completed:
        icon = Icons.verified_user;
        color = Colors.greenAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 40),
    );
  }
}
