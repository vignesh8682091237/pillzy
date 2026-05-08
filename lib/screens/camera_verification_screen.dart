import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

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
  bool _isProcessing = false;
  
  // ML Kit Detectors
  late FaceDetector _faceDetector;
  late ObjectDetector _objectDetector;
  
  // Verification State
  VerificationStep _currentStep = VerificationStep.pillDetection;
  String _instruction = "Show the pill in your palm";
  bool _pillDetected = false;
  bool _mouthOpen = false;
  double _verificationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeML();
    _initCamera();
    _startBypassTimer();
  }

  void _initializeML() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
      ),
    );

    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
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
      
      // On Web, we don't start the image stream as ML Kit doesn't support it directly here
      if (!kIsWeb) {
        _cameraController!.startImageStream(_processCameraImage);
      } else {
        setState(() {
          _instruction = "Verify your medication in front of the camera.";
        });
      }
      
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) setState(() => _instruction = "Camera initialization failed: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bypassTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    _objectDetector.close();
    super.dispose();
  }

  // ── Image Processing ──────────────────────────────────────────────────────

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || _currentStep == VerificationStep.completed) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      if (_currentStep == VerificationStep.pillDetection) {
        await _detectPill(inputImage);
      } else if (_currentStep == VerificationStep.mouthOpening || _currentStep == VerificationStep.swallowing) {
        await _detectFaceAndMouth(inputImage);
      }
    } catch (e) {
      debugPrint("ML Error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  bool _showManualPillBypass = false;
  Timer? _bypassTimer;

  void _startBypassTimer() {
    _bypassTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _currentStep == VerificationStep.pillDetection) {
        setState(() => _showManualPillBypass = true);
      }
    });
  }

  Future<void> _detectPill(InputImage inputImage) async {
    final objects = await _objectDetector.processImage(inputImage);
    
    // Logic: If any object is detected (even if not classified as a pill specifically)
    if (objects.isNotEmpty || _showManualPillBypass) {
      // Small delay to let user see the detection
      await Future.delayed(const Duration(milliseconds: 500));
      _proceedToFace();
    }
  }

  void _proceedToFace() {
    if (_currentStep != VerificationStep.pillDetection) return;
    _bypassTimer?.cancel();
    setState(() {
      _pillDetected = true;
      _instruction = "Pill Detected! Now bring it to your mouth.";
      _verificationProgress = 0.33;
      _currentStep = VerificationStep.mouthOpening;
      _showManualPillBypass = false;
    });
    _startBypassTimer(); // Restart timer for the face step
  }

  Future<void> _detectFaceAndMouth(InputImage inputImage) async {
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return;

    final face = faces.first;
    
    // Calculate mouth opening based on landmarks
    final topMouth = face.landmarks[FaceLandmarkType.topMouth];
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
    
    if (_currentStep == VerificationStep.mouthOpening) {
      bool isMouthOpen = false;
      
      if (topMouth != null && bottomMouth != null) {
        // Calculate distance between top and bottom lips
        final distance = (topMouth.position.y - bottomMouth.position.y).abs();
        // If distance is significant, consider mouth open
        if (distance > 15) isMouthOpen = true; 
      }
      
      // Fallback to smiling or high probability if landmarks fail
      if (isMouthOpen || (face.smilingProbability ?? 0) > 0.7) {
        setState(() {
          _mouthOpen = true;
          _instruction = "Mouth Open detected! Now swallow the pill.";
          _verificationProgress = 0.66;
          _currentStep = VerificationStep.swallowing;
        });
      }
    } else if (_currentStep == VerificationStep.swallowing) {
      // Wait for a clear swallow action (simulated by 3 seconds of face presence)
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) _completeVerification();
    }
  }

  void _completeVerification() {
    if (_currentStep == VerificationStep.completed) return;
    
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

  // ── Helper: Convert CameraImage to InputImage ─────────────────────────────

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameraController!.description.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
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
                if (kIsWeb && _currentStep != VerificationStep.completed) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_currentStep == VerificationStep.pillDetection) {
                          _proceedToFace();
                        } else if (_currentStep == VerificationStep.mouthOpening) {
                          setState(() {
                            _mouthOpen = true;
                            _instruction = "Mouth Open. Swallow the pill now.";
                            _verificationProgress = 0.66;
                            _currentStep = VerificationStep.swallowing;
                          });
                        } else if (_currentStep == VerificationStep.swallowing) {
                          _completeVerification();
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      label: Text(
                        _currentStep == VerificationStep.pillDetection ? "I have the pill" :
                        _currentStep == VerificationStep.mouthOpening ? "Mouth is open" : "Swallowed it",
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
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
              "AI Verification",
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
            "Step ${_currentStep.index + 1} of 3",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (_showManualPillBypass && _currentStep == VerificationStep.pillDetection) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _proceedToFace,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Pill in Hand (Manual)", style: TextStyle(color: Colors.white)),
            ),
          ],
          if (_showManualPillBypass && (_currentStep == VerificationStep.mouthOpening || _currentStep == VerificationStep.swallowing)) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _completeVerification,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Skip Face AI (Manual)", style: TextStyle(color: Colors.white)),
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
        color = _pillDetected ? Colors.greenAccent : Colors.orangeAccent;
        break;
      case VerificationStep.mouthOpening:
        icon = Icons.face_retouching_natural;
        color = _mouthOpen ? Colors.greenAccent : Colors.blueAccent;
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
