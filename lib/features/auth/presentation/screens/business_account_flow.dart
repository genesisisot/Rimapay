import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';

enum BusinessAccountStep {
  businessTypeSelection,
  bnInfo,
  llcInfo,
  otpVerification,
  bnDocuments,
  llcDocuments,
  directorsInfo,
  ownerVerification,
  llcOwnerVerification,
  verificationLoading,
  setPin,
}

enum BusinessType { BN, LLC }

class Director {
  String id;
  String name;
  String idType;
  String bvn;
  bool photoUploaded;
  bool idUploaded;

  Director({
    required this.id,
    this.name = '',
    this.idType = 'NIN',
    this.bvn = '',
    this.photoUploaded = false,
    this.idUploaded = false,
  });
}

class BusinessInfo {
  String businessName;
  BusinessType? businessType;
  String cacNumber;
  String tin;
  String businessAddress;
  String phoneNumber;
  String emailAddress;
  String ownerBvn;
  List<Director> directors;
  bool tinApplicable;

  BusinessInfo({
    this.businessName = '',
    this.businessType,
    this.cacNumber = '',
    this.tin = '',
    this.businessAddress = '',
    this.phoneNumber = '',
    this.emailAddress = '',
    this.ownerBvn = '',
    this.directors = const [],
    this.tinApplicable = false,
  });
}

class BusinessAccountFlow extends StatefulWidget {


  const BusinessAccountFlow({
    super.key,

  });

  @override
  State<BusinessAccountFlow> createState() => _BusinessAccountFlowState();
}

class _BusinessAccountFlowState extends State<BusinessAccountFlow>
    with TickerProviderStateMixin {
  BusinessAccountStep _currentStep = BusinessAccountStep.businessTypeSelection;
  final BusinessInfo _businessInfo = BusinessInfo();
  final List<String> _otp = List.filled(6, '');
  final List<String> _pin = List.filled(4, '');
  String _password = '';
  String _confirmPassword = '';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _completedLiveness = false;
  
  // Camera related
  CameraController? _cameraController;
  bool _cameraActive = false;
  File? _capturedImage;
  String? _cameraError;
  bool _permissionDenied = false;
  final bool _uploadingPhoto = false;
  
  // RC Number lookup
  final bool _rcLookupLoading = false;
  final String _rcLookupStatus = 'idle'; // idle, loading, success, error, not-found
  final String _rcInputValue = '';
  
  // Document uploads
  final Map<String, bool> _bnDocs = {
    'cacCertificate': false,
    'bnForm': false,
    'ownerID': false,
    'utilityBill': false,
    'passportPhoto': false,
  };
  
  final Map<String, bool> _llcDocs = {
    'cacIncorporation': false,
    'cacStatusReport': false,
    'memorandumArticles': false,
    'directorIDs': false,
    'directorPhotos': false,
    'boardResolution': false,
    'utilityBill': false,
  };
  
  // Verification progress
  double _verificationProgress = 0.0;
  Timer? _verificationTimer;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _cameraController?.dispose();
    _verificationTimer?.cancel();
    super.dispose();
  }

  int _getStepNumber() {
    if (_businessInfo.businessType == BusinessType.BN) {
      const bnSteps = [
        BusinessAccountStep.businessTypeSelection,
        BusinessAccountStep.bnInfo,
        BusinessAccountStep.otpVerification,
        BusinessAccountStep.bnDocuments,
        BusinessAccountStep.ownerVerification,
        BusinessAccountStep.verificationLoading,
        BusinessAccountStep.setPin,
      ];
      return bnSteps.indexOf(_currentStep) + 1;
    } else if (_businessInfo.businessType == BusinessType.LLC) {
      const llcSteps = [
        BusinessAccountStep.businessTypeSelection,
        BusinessAccountStep.llcInfo,
        BusinessAccountStep.otpVerification,
        BusinessAccountStep.llcDocuments,
        BusinessAccountStep.directorsInfo,
        BusinessAccountStep.llcOwnerVerification,
        BusinessAccountStep.verificationLoading,
        BusinessAccountStep.setPin,
      ];
      return llcSteps.indexOf(_currentStep) + 1;
    }
    return 1;
  }

  int _getTotalSteps() {
    if (_businessInfo.businessType == BusinessType.BN) return 7;
    if (_businessInfo.businessType == BusinessType.LLC) return 8;
    return 7;
  }

  void _handleBusinessTypeSelection(BusinessType type) {
    setState(() {
      _businessInfo.businessType = type;
      _currentStep = type == BusinessType.BN 
          ? BusinessAccountStep.bnInfo 
          : BusinessAccountStep.llcInfo;
    });
  }

  void _handleBusinessInfoSubmit() {
    setState(() {
      _currentStep = BusinessAccountStep.otpVerification;
    });
  }

  void _handleOtpSubmit() {
    setState(() {
      _isLoading = true;
    });
    
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _currentStep = _businessInfo.businessType == BusinessType.BN
            ? BusinessAccountStep.bnDocuments
            : BusinessAccountStep.llcDocuments;
      });
    });
  }

  void _startVerificationLoading() {
    setState(() {
      _currentStep = BusinessAccountStep.verificationLoading;
      _verificationProgress = 0.0;
    });
    
    _verificationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _verificationProgress += 2;
        if (_verificationProgress >= 100) {
          timer.cancel();
          _currentStep = BusinessAccountStep.setPin;
        }
      });
    });
  }

  // Camera functions
  Future<void> _startCamera() async {
    setState(() {
      _cameraError = null;
      _permissionDenied = false;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera found on this device. You can upload a photo instead.';
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      
      setState(() {
        _cameraActive = true;
        _cameraError = null;
      });
    } catch (e) {
      setState(() {
        _cameraActive = false;
        _permissionDenied = true;
        _cameraError = 'Camera permission was denied. You can upload a photo instead.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _cameraError = 'Camera not ready. Please try again.';
      });
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(image.path);
        _cameraActive = false;
      });
      _cameraController?.dispose();
      _cameraController = null;
    } catch (e) {
      setState(() {
        _cameraError = 'Unable to capture photo. Please try again.';
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _cameraError = null;
      _permissionDenied = false;
    });
    _startCamera();
  }

  Future<void> _handleFileUpload() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
          _cameraError = null;
        });
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to pick image. Please try again.';
      });
    }
  }

  void _addDirector() {
    if (_businessInfo.directors.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 directors allowed')),
      );
      return;
    }
    
    setState(() {
      _businessInfo.directors = [
        ..._businessInfo.directors,
        Director(id: DateTime.now().millisecondsSinceEpoch.toString()),
      ];
    });
  }

  void _removeDirector(String id) {
    setState(() {
      _businessInfo.directors = _businessInfo.directors
          .where((director) => director.id != id)
          .toList();
    });
  }

  void _updateDirector(String id, String field, dynamic value) {
    setState(() {
      final index = _businessInfo.directors.indexWhere((d) => d.id == id);
      if (index != -1) {
        final director = _businessInfo.directors[index];
        switch (field) {
          case 'name':
            director.name = value;
            break;
          case 'idType':
            director.idType = value;
            break;
          case 'bvn':
            director.bvn = value;
            break;
          case 'photoUploaded':
            director.photoUploaded = value;
            break;
          case 'idUploaded':
            director.idUploaded = value;
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Onboarding2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header with back button and progress
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: (){
                            context.pop();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        // Progress indicator
                        Text(
                          'Step ${_getStepNumber()} of ${_getTotalSteps()}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 
                                     MediaQuery.of(context).padding.top - 
                                     MediaQuery.of(context).padding.bottom - 
                                     80,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStepContent(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case BusinessAccountStep.businessTypeSelection:
        return _buildBusinessTypeSelection();
      case BusinessAccountStep.bnInfo:
        return _buildBNInfoStep();
      case BusinessAccountStep.llcInfo:
        return _buildLLCInfoStep();
      case BusinessAccountStep.otpVerification:
        return _buildOtpVerificationStep();
      case BusinessAccountStep.bnDocuments:
        return _buildBNDocumentsStep();
      case BusinessAccountStep.llcDocuments:
        return _buildLLCDocumentsStep();
      case BusinessAccountStep.directorsInfo:
        return _buildDirectorsInfo();
      case BusinessAccountStep.ownerVerification:
        return _buildOwnerVerification();
      case BusinessAccountStep.llcOwnerVerification:
        return _buildLLCOwnerVerification();
      case BusinessAccountStep.verificationLoading:
        return _buildVerificationLoadingStep();
      case BusinessAccountStep.setPin:
        return _buildSetPin();
      default:
        return Container();
    }
  }

  Widget _buildBusinessTypeSelection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.business,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Business Type Selection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What type of business are you registering?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Business type options
            _buildBusinessTypeCard(
              'Business Name (BN)',
              'For sole proprietorships',
              Icons.business,
              () => _handleBusinessTypeSelection(BusinessType.BN),
            ),
            const SizedBox(height: 12),
            _buildBusinessTypeCard(
              'Limited Liability Company',
              'For incorporated companies',
              Icons.corporate_fare,
              () => _handleBusinessTypeSelection(BusinessType.LLC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTypeCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBNInfoStep() {
    return _buildInfoForm('Business Name Registration', 'BN');
  }

  Widget _buildLLCInfoStep() {
    return _buildInfoForm('Company Registration', 'LLC');
  }

  Widget _buildInfoForm(String title, String type) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.business,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your ${type == 'BN' ? 'business' : 'company'} information',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Form fields
            _buildFormField(
              'Business Name *',
              _businessInfo.businessName,
              (value) => setState(() => _businessInfo.businessName = value),
              Icons.business,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'CAC Registration Number *',
              _businessInfo.cacNumber,
              (value) => setState(() => _businessInfo.cacNumber = value),
              Icons.credit_card,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'Business Address *',
              _businessInfo.businessAddress,
              (value) => setState(() => _businessInfo.businessAddress = value),
              Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'Business Phone *',
              _businessInfo.phoneNumber,
              (value) => setState(() => _businessInfo.phoneNumber = value),
              Icons.phone,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'Business Email *',
              _businessInfo.emailAddress,
              (value) => setState(() => _businessInfo.emailAddress = value),
              Icons.email,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              'Owner BVN *',
              _businessInfo.ownerBvn,
              (value) => setState(() => _businessInfo.ownerBvn = value),
              Icons.security,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinueBusinessInfo() ? _handleBusinessInfoSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B252),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canContinueBusinessInfo() {
    return _businessInfo.businessName.isNotEmpty &&
           _businessInfo.cacNumber.isNotEmpty &&
           _businessInfo.businessAddress.isNotEmpty &&
           _businessInfo.phoneNumber.isNotEmpty &&
           _businessInfo.emailAddress.isNotEmpty &&
           _businessInfo.ownerBvn.isNotEmpty;
  }

  Widget _buildFormField(
    String label,
    String value,
    Function(String) onChanged,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: Colors.white.withOpacity(0.6),
              size: 16,
            ),
            fillColor: Colors.white.withOpacity(0.2),
            filled: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF00B252),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationStep() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verify Phone Number',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${_businessInfo.phoneNumber}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // OTP input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  height: 40,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      fillColor: Colors.white.withOpacity(0.2),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF00B252),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _otp[index] = value;
                      });
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).nextFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _otp.any((digit) => digit.isEmpty) 
                    ? null 
                    : _handleOtpSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B252),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBNDocumentsStep() {
    return _buildDocumentsStep('BN Documents', _bnDocs, () {
      setState(() {
        _currentStep = BusinessAccountStep.ownerVerification;
      });
    });
  }

  Widget _buildLLCDocumentsStep() {
    return _buildDocumentsStep('LLC Documents', _llcDocs, () {
      setState(() {
        _currentStep = BusinessAccountStep.directorsInfo;
      });
    });
  }

  Widget _buildDocumentsStep(String title, Map<String, bool> docs, VoidCallback onContinue) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.upload_file,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload required documents for verification',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Document upload items
            ...docs.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDocumentItem(entry.key, entry.value, docs),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: docs.values.every((uploaded) => uploaded) ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B252),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String key, bool uploaded, Map<String, bool> docs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getDocumentName(key),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (uploaded)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00B252),
              size: 20,
            )
          else
            GestureDetector(
              onTap: () {
                setState(() {
                  docs[key] = true;
                });
              },
              child: Text(
                'Upload',
                style: TextStyle(
                  color: const Color(0xFF00B252),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getDocumentName(String key) {
    switch (key) {
      case 'cacCertificate':
        return 'CAC Certificate';
      case 'bnForm':
        return 'BN Form (Optional)';
      case 'ownerID':
        return 'Owner ID';
      case 'utilityBill':
        return 'Utility Bill';
      case 'passportPhoto':
        return 'Passport Photo';
      case 'cacIncorporation':
        return 'CAC Incorporation';
      case 'cacStatusReport':
        return 'Status Report';
      case 'memorandumArticles':
        return 'Memorandum & Articles';
      case 'boardResolution':
        return 'Board Resolution';
      default:
        return key;
    }
  }

  Widget _buildDirectorsInfo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.people,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Directors Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add information for company directors (minimum 1, maximum 5)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Directors list
            ..._businessInfo.directors.asMap().entries.map((entry) {
              final index = entry.key;
              final director = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDirectorCard(director, index),
              );
            }),
            // Add director button
            if (_businessInfo.directors.length < 5)
              GestureDetector(
                onTap: _addDirector,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        color: Color(0xFF00B252),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Director',
                        style: TextStyle(
                          color: const Color(0xFF00B252),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinueDirectors() ? () {
                  setState(() {
                    _currentStep = BusinessAccountStep.llcOwnerVerification;
                  });
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B252),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Verification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canContinueDirectors() {
    return _businessInfo.directors.isNotEmpty &&
           _businessInfo.directors.every((director) =>
               director.name.isNotEmpty &&
               director.bvn.isNotEmpty &&
               director.photoUploaded &&
               director.idUploaded);
  }

  Widget _buildDirectorCard(Director director, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Director ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_businessInfo.directors.length > 1)
                GestureDetector(
                  onTap: () => _removeDirector(director.id),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFormField(
            'Full Name *',
            director.name,
            (value) => _updateDirector(director.id, 'name', value),
            Icons.person,
          ),
          const SizedBox(height: 12),
          _buildFormField(
            'BVN *',
            director.bvn,
            (value) => _updateDirector(director.id, 'bvn', value),
            Icons.security,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _updateDirector(director.id, 'photoUploaded', true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: director.photoUploaded 
                          ? const Color(0xFF00B252).withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: director.photoUploaded 
                            ? const Color(0xFF00B252)
                            : Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      director.photoUploaded ? '✓ Photo Uploaded' : 'Upload Photo',
                      style: TextStyle(
                        color: director.photoUploaded 
                            ? const Color(0xFF00B252)
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _updateDirector(director.id, 'idUploaded', true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: director.idUploaded 
                          ? const Color(0xFF00B252).withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: director.idUploaded 
                            ? const Color(0xFF00B252)
                            : Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      director.idUploaded ? '✓ ID Uploaded' : 'Upload ID',
                      style: TextStyle(
                        color: director.idUploaded 
                            ? const Color(0xFF00B252)
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerVerification() {
    return _buildVerificationStep('Identity Verification', 'Take a selfie to verify your identity', () {
      if (_capturedImage != null) {
        setState(() {
          _completedLiveness = true;
        });
        _startVerificationLoading();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture or upload your photo first')),
        );
      }
    });
  }

  Widget _buildLLCOwnerVerification() {
    return _buildVerificationStep('Owner Identity Verification', 'Take a selfie to verify the primary owner\'s identity', () {
      if (_capturedImage != null) {
        setState(() {
          _completedLiveness = true;
        });
        _startVerificationLoading();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture or upload your photo first')),
        );
      }
    });
  }

  Widget _buildVerificationStep(String title, String subtitle, VoidCallback onContinue) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Camera/Photo section
            if (!_cameraActive && _capturedImage == null)
              _buildCameraPrompt()
            else if (_cameraActive)
              _buildCameraView()
            else if (_capturedImage != null)
              _buildCapturedPhoto(onContinue),
            // Error handling
            if (_cameraError != null)
              _buildCameraError(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to take your photo?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure you\'re in good lighting and your face is clearly visible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B252),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Start Camera'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00B252),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _cameraController != null && _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B252)),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _capturePhoto,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B252),
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: const Icon(Icons.camera_alt, size: 24),
        ),
      ],
    );
  }

  Widget _buildCapturedPhoto(VoidCallback onContinue) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00B252),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _capturedImage!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _retakePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retake'),
            ),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCameraError() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Camera Error',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _cameraError!,
            style: TextStyle(
              color: Colors.red.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _handleFileUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_uploadingPhoto ? 'Uploading...' : 'Upload Photo Instead'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationLoadingStep() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verifying Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we verify your business information and documents',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Progress indicator
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: _verificationProgress / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B252)),
                  ),
                  Center(
                    child: Text(
                      '${_verificationProgress.round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00B252),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetPin() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up your account password for secure access',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Password fields
            _buildPasswordField(
              'Password *',
              _password,
              (value) => setState(() => _password = value),
              _showPassword,
              () => setState(() => _showPassword = !_showPassword),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              'Confirm Password *',
              _confirmPassword,
              (value) => setState(() => _confirmPassword = value),
              _showConfirmPassword,
              () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSetPassword() ? _handleSetPassword : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B252),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Complete Registration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    String value,
    Function(String) onChanged,
    bool obscureText,
    VoidCallback onToggleVisibility,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          obscureText: obscureText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            suffixIcon: GestureDetector(
              onTap: onToggleVisibility,
              child: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
            ),
            fillColor: Colors.white.withOpacity(0.2),
            filled: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF00B252),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _canSetPassword() {
    return _password.length >= 8 && _password == _confirmPassword;
  }

  void _handleSetPassword() {
    if (!_canSetPassword()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters and match')),
      );
      return;
    }
    
    // // Complete registration
    // widget.onSuccess({
    //   'businessInfo': _businessInfo,
    //   'accountType': 'business',
    //   'tierLevel': 'Business',
    //   'isVerified': false,
    //   'bvnVerified': true,
    // });
  }
}
