import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rimapay/Utils/Logics.dart';
import 'package:rimapay/core/Models/CountryStateLgaModel.dart';
import 'dart:developer';

import 'package:rimapay/core/Utils/En.dart';
import 'package:rimapay/core/services/GetPlaceDetailsService.dart';

// Enums
enum BusinessAccountStep {
  businessTypeSelection,
  bnInfo,
  llcInfo,
  otpVerification,
  // bnDocuments,
  // llcDocuments,
  ownerVerification,
  // directorsInfo,
  llcOwnerVerification,
  // verificationLoading,
  setPin,
}

enum BusinessType { bn, llc }

// Models
class BusinessInfo {
  String businessName = '';
  BusinessType? businessType;
  String cacNumber = '';
  String tin = '';
  String businessAddress = '';
  String phoneNumber = '';
  String emailAddress = '';
  String ownerBvn = '';
  String state = '';
  String lga = '';
  List<Director> directors = [];
  bool tinApplicable = true;
  double? currentLat;
  double? currentLng;
}

class Director {
  String id;
  String name = '';
  String idType = '';
  String bvn = '';
  bool photoUploaded = false;
  bool idUploaded = false;

  Director({required this.id});
}

class DocumentStatus {
  bool cacCertificate = false;
  bool bnForm = false;
  bool ownerID = false;
  bool utilityBill = false;
  bool passportPhoto = false;

  // LLC specific
  bool cacIncorporation = false;
  bool cacStatusReport = false;
  bool memorandumArticles = false;
  bool directorIDs = false;
  bool directorPhotos = false;
  bool boardResolution = false;
}

class BusinessAccountFlow extends ConsumerStatefulWidget {
  const BusinessAccountFlow({
    super.key,
  });

  @override
  ConsumerState<BusinessAccountFlow> createState() => _BusinessAccountFlowState();
}

class _BusinessAccountFlowState extends ConsumerState<BusinessAccountFlow> with TickerProviderStateMixin, WidgetsBindingObserver {
  BusinessAccountStep _currentStep = BusinessAccountStep.businessTypeSelection;
  final BusinessInfo _businessInfo = BusinessInfo();
  final List<String> _otp = List.filled(6, '');
  String _password = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  final bool _completedLiveness = false;
  bool _cameraActive = false;
  String? _capturedImage;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  String? _cameraError;
  bool _permissionDenied = false;
  bool _uploadingPhoto = false;
  bool _isGettingLocation = false;
  int _verificationProgress = 0;

  // RC Number lookup states
  final bool _rcLookupLoading = false;
  final String _rcLookupStatus = 'idle'; // idle, loading, success, error, not-found
  Map<String, dynamic>? _cacDetails;
  String _rcInputValue = '';

  // Document upload states
  final DocumentStatus _bnDocs = DocumentStatus();
  final DocumentStatus _llcDocs = DocumentStatus();

  // Address and location related fields
  final _addressController = TextEditingController();
  CountryStateLgaModel? selectedState;
  Local? selectedLga;
  List<Local>? locals;
  Prediction? selectedCoordinate;

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
      }
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  Future<void> _startCamera() async {
    setState(() {
      _cameraError = null;
      _permissionDenied = false;
    });

    final cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        setState(() {
          _permissionDenied = true;
          _cameraError = 'Camera permission was denied. You can upload a photo instead.';
        });
        return;
      }
    }

    try {
      if (_cameraController != null && !_cameraController!.value.isInitialized) {
        await _cameraController!.initialize();
      }
      setState(() {
        _cameraActive = true;
        _cameraError = null;
      });
    } catch (e) {
      setState(() {
        _cameraActive = false;
        _cameraError = 'Unable to access camera. You can upload a photo instead.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _cameraError = 'Camera not ready. Please restart the camera.';
      });
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = photo.path;
        _cameraActive = false;
      });
    } catch (e) {
      setState(() {
        _cameraError = 'Unable to capture photo. Please try again.';
      });
    }
  }

  Future<void> _captureDocs(String docKey) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _cameraError = 'Camera not ready. Please restart the camera.';
      });
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = photo.path;
        _uploadedDocuments[docKey] = _capturedImage!;
        _cameraActive = false;
      });
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

  Future<void> _uploadPhoto() async {
    setState(() {
      _uploadingPhoto = true;
      _cameraError = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (5MB limit)
        if (file.size > 5 * 1024 * 1024) {
          setState(() {
            _cameraError = 'Image size must be less than 5MB.';
            _uploadingPhoto = false;
          });
          return;
        }

        setState(() {
          _capturedImage = file.path!;
          _uploadingPhoto = false;
        });
      } else {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to upload image.';
        _uploadingPhoto = false;
      });
    }
  }

  final Map<String, String> _uploadedDocuments = {};

  Future<void> _uploadDocument(String docType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (10MB limit for documents)
        if (file.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must be less than 10MB.')),
          );
          return;
        }

        // setState(() {
        //   if (_businessType == 'BN') {
        //     _bnDocs[docType] = true;
        //   } else {
        //     _llcDocs[docType] = true;
        //   }
        // });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload document: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _addressController.dispose();
    super.dispose();
  }

  int _getStepNumber() {
    if (_businessInfo.businessType == BusinessType.bn) {
      const bnSteps = [
        BusinessAccountStep.businessTypeSelection,
        BusinessAccountStep.bnInfo,
        BusinessAccountStep.otpVerification,
        //  BusinessAccountStep.bnDocuments,
        BusinessAccountStep.ownerVerification,
        //BusinessAccountStep.verificationLoading,
        BusinessAccountStep.setPin,
      ];
      return bnSteps.indexOf(_currentStep) + 1;
    } else if (_businessInfo.businessType == BusinessType.llc) {
      const llcSteps = [
        BusinessAccountStep.businessTypeSelection,
        BusinessAccountStep.llcInfo,
        BusinessAccountStep.otpVerification,
        // BusinessAccountStep.llcDocuments,
        // BusinessAccountStep.directorsInfo,
        BusinessAccountStep.llcOwnerVerification,
        // BusinessAccountStep.verificationLoading,
        BusinessAccountStep.setPin,
      ];
      return llcSteps.indexOf(_currentStep) + 1;
    }
    return 1;
  }

  int _getTotalSteps() {
    if (_businessInfo.businessType == BusinessType.bn) return 5;
    if (_businessInfo.businessType == BusinessType.llc) return 5;
    return 5;
  }

  void _handleBusinessTypeSelection(BusinessType type) {
    setState(() {
      _businessInfo.businessType = type;
      _currentStep = type == BusinessType.bn ? BusinessAccountStep.bnInfo : BusinessAccountStep.llcInfo;
    });
  }

  void _handleBusinessInfoSubmit() {
    if (_businessInfo.businessName.trim().isEmpty ||
        _businessInfo.phoneNumber.trim().isEmpty ||
        _businessInfo.emailAddress.trim().isEmpty ||
        _businessInfo.ownerBvn.trim().isEmpty ||
        _businessInfo.cacNumber.trim().isEmpty) {
      return;
    }
    setState(() {
      _currentStep = BusinessAccountStep.otpVerification;
    });
  }

  void _handleBusinessLCCInfoSubmit() {
    if (_businessInfo.businessName.trim().isEmpty ||
        _businessInfo.phoneNumber.trim().isEmpty ||
        _businessInfo.emailAddress.trim().isEmpty ||
        (!_businessInfo.tinApplicable && _businessInfo.tin.trim().isEmpty) ||
        _businessInfo.cacNumber.trim().isEmpty) {
      return;
    }
    setState(() {
      _currentStep = BusinessAccountStep.otpVerification;
    });
  }

  void _handleOtpSubmit() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        _currentStep = _businessInfo.businessType == BusinessType.bn ? BusinessAccountStep.ownerVerification : BusinessAccountStep.llcOwnerVerification;
        //_businessInfo.businessType == BusinessType.bn ;
        //? BusinessAccountStep.bnDocuments : BusinessAccountStep.llcDocuments;
      });
    });
  }

  void _handleDocumentsSubmit() {
    setState(() {
      //_currentStep = _businessInfo.businessType == BusinessType.bn ? BusinessAccountStep.ownerVerification : BusinessAccountStep.directorsInfo;
    });
  }

  void _handleVerificationComplete() {
    setState(() {
      // _currentStep = BusinessAccountStep.verificationLoading;
      _currentStep = BusinessAccountStep.setPin;
      _verificationProgress = 0;
    });

    // Simulate verification progress
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _verificationProgress += 2;
      });

      if (_verificationProgress >= 100) {
        timer.cancel();
        setState(() {
          _currentStep = BusinessAccountStep.setPin;
        });
      }
    });
  }

  void _handlePinSet() {
    if (_password.length < 8 || _password != _confirmPassword) {
      return;
    }

    context.go("/business");
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled")),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied")),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied")),
      );
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Location handling methods (from personal flow)
  Future<void> _onLocateMePressed() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await getCurrentLocation();
      if (position != null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;

            String address = '';
            if (placemark.street?.isNotEmpty == true) {
              address += '${placemark.street}, ';
            }
            if (placemark.subLocality?.isNotEmpty == true) {
              address += '${placemark.subLocality}, ';
            }
            if (placemark.locality?.isNotEmpty == true) {
              address += '${placemark.locality}, ';
            }
            if (placemark.administrativeArea?.isNotEmpty == true) {
              address += '${placemark.administrativeArea}, ';
            }
            if (placemark.country?.isNotEmpty == true) {
              address += placemark.country!;
            }

            address = address.replaceAll(RegExp(r', $'), '');

            setState(() {
              _addressController.text = address;

              selectedCoordinate = Prediction(
                placeId: null,
                description: address,
                lat: position.latitude.toString(),
                lng: position.longitude.toString(),
              );
            });

            final locations = getCountryLocation();
            if (placemark.administrativeArea != null) {
              final service = ref.read(locationDetailsServiceProvider);
              final matchingState = service.findMatchingState(placemark.administrativeArea!, locations);
              if (matchingState != null) {
                setState(() {
                  selectedState = matchingState;

                  locals = matchingState.state?.locals;

                  if (placemark.subAdministrativeArea != null && locals != null) {
                    selectedLga = service.findMatchingLGA(placemark.subAdministrativeArea!, locals!);
                    if (selectedLga != null) {}
                  } else {
                    selectedLga = null;
                  }
                });
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location found successfully!")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Could not get address for your location")),
            );
          }
        } catch (e) {
          log("Error in reverse geocoding: $e");

          setState(() {
            _addressController.text = "Current Location (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)})";

            selectedCoordinate = Prediction(
              placeId: null,
              description: "Current Location",
              lat: position.latitude.toString(),
              lng: position.longitude.toString(),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location coordinates found!")),
          );
        }
      }
    } catch (e) {
      log("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get your location")),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Widget _buildBusinessTypeSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Header
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B252), Color(0xFF00A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Business Type Selection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'What type of business are you registering?',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Business Name (BN) Option
          GestureDetector(
            onTap: () => _handleBusinessTypeSelection(BusinessType.bn),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Color(0xFF2563EB),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Name (BN)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'For sole proprietorships',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Limited Liability Company (LLC) Option
          GestureDetector(
            onTap: () => _handleBusinessTypeSelection(BusinessType.llc),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Color(0xFF7C3AED),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Limited Liability Company',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'For incorporated companies',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  Widget _buildBNInfoStep() {
    final locations = getCountryLocation(); // You'll need to implement this

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Business Name Registration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your business information for BN registration',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business Name Field
          const Text(
            'Business Name *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _businessInfo.businessName = value;
              });
            },
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Enter registered business name',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.business_outlined,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              suffixIcon: _cacDetails != null
                  ? const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 16,
                    )
                  : null,
              fillColor: _cacDetails != null ? const Color(0xFFF0FDF4) : Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            readOnly: _cacDetails != null,
          ),
          const SizedBox(height: 16),

          // CAC Registration Number Field
          const Text(
            'CAC Registration Number *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _rcInputValue = value;
                _businessInfo.cacNumber = value;
              });
              // Add RC number lookup logic here
            },
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'BN1234567',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.credit_card_outlined,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              suffixIcon: _rcLookupLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B252)),
                        ),
                      ),
                    )
                  : _rcLookupStatus == 'success'
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 16,
                        )
                      : _rcLookupStatus == 'error' || _rcLookupStatus == 'not-found'
                          ? const Icon(
                              Icons.cancel,
                              color: Color(0xFFEF4444),
                              size: 16,
                            )
                          : null,
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _rcLookupStatus == 'success'
                      ? const Color(0xFF10B981)
                      : _rcLookupStatus == 'error' || _rcLookupStatus == 'not-found'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFE5E7EB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _rcLookupStatus == 'success'
                      ? const Color(0xFF10B981)
                      : _rcLookupStatus == 'error' || _rcLookupStatus == 'not-found'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF00B252),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLength: 9,
          ),

          // RC Number Status Messages
          if (_rcLookupStatus == 'success' && _cacDetails != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Business found and details auto-filled',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_rcLookupStatus == 'not-found')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.cancel,
                    color: Color(0xFFDC2626),
                    size: 12,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Business not found. Please verify your RC number or enter details manually',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Business Address Field with Google Places Autocomplete
          const Text(
            'Business Address *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),

          GooglePlacesAutoCompleteTextFormField(
            textEditingController: _addressController,
            googleAPIKey: GOOGLE_API_KEY, // Replace with your API key
            debounceTime: 600,
            onSuggestionClicked: (prediction) {
              _addressController.text = prediction.description ?? "";
              _addressController.selection = TextSelection.fromPosition(
                TextPosition(offset: prediction.description?.length ?? 0),
              );
            },
            countries: const ["ng"], // Nigeria only
            onChanged: (e) {
              if (e.trim().isEmpty) {
                setState(() {
                  selectedState = null;
                  selectedLga = null;
                });
              }
            },

            onPlaceDetailsWithCoordinatesReceived: (prediction) async {
              log("all here");
              log(prediction.toString());
              setState(() {
                selectedCoordinate = Prediction(
                  description: prediction.description,
                  lat: prediction.lat,
                  lng: prediction.lng,
                  placeId: prediction.placeId,
                );
              });
              if (prediction.placeId != null) {
                log("Place ID received: ${prediction.placeId}");

                final locationDetails = await ref.read(locationDetailsProvider(prediction.placeId ?? "").future);

                if (locationDetails != null) {
                  log("Location details: $locationDetails");

                  final locations = getCountryLocation();

                  final service = ref.read(locationDetailsServiceProvider);
                  final matchingState = service.findMatchingState(locationDetails.state, locations);

                  if (matchingState != null) {
                    setState(() {
                      selectedState = matchingState;
                      locals = matchingState.state?.locals;

                      if (locationDetails.localGovernment != null && locals != null) {
                        selectedLga = service.findMatchingLGA(locationDetails.localGovernment!, locals!);
                      } else {
                        selectedLga = null;
                      }
                    });
                  } else {
                    log("No matching state found for: ${locationDetails.state}");
                  }
                }
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter full business address',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              suffixIcon: _isGettingLocation
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: const CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B252)),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _onLocateMePressed,
                      icon: const Icon(
                        Icons.my_location,
                        color: Color(0xFF00B252),
                        size: 20,
                      ),
                      tooltip: "Use my current location",
                    ),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // State Dropdown
          const Text(
            'State *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<CountryStateLgaModel>(
            value: selectedState,
            onChanged: (value) {
              setState(() {
                selectedState = value;
                _businessInfo.state = value?.state?.name ?? '';
                locals = value?.state?.locals;
                selectedLga = null;
                _businessInfo.lga = '';
              });
            },
            decoration: InputDecoration(
              hintText: 'Select business state',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: locations.map((location) {
              return DropdownMenuItem<CountryStateLgaModel>(
                value: location,
                child: Text(
                  location.state?.name ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // LGA Dropdown
          const Text(
            'LGA *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<Local>(
            value: selectedLga,
            onChanged: selectedState == null
                ? null
                : (value) {
                    setState(() {
                      selectedLga = value;
                      _businessInfo.lga = value?.name ?? '';
                    });
                  },
            decoration: InputDecoration(
              hintText: selectedState == null ? 'Select state first' : 'Select business LGA',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: locals?.map((local) {
                  return DropdownMenuItem<Local>(
                    value: local,
                    child: Text(
                      local.name ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList() ??
                [],
          ),
          const SizedBox(height: 16),

          // Business Phone Field
          const Text(
            'Business Phone *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _businessInfo.phoneNumber = addLeadingZero(value);
              });
            },
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
             hintText: 'Enter your business phone number',
              // prefixIcon: Padding(
              //   padding: EdgeInsets.only(
              //     left: 20,
              //     right: 5,
              //   ),
              //   child: Column(
              //     mainAxisSize: MainAxisSize.min,
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         "+234",
              //         textAlign: TextAlign.center,
              //         style: TextStyle(
              //           color: Color(0xFF9CA3AF),
              //           fontSize: 14,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Business Email Field
          const Text(
            'Business Email *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _businessInfo.emailAddress = value;
              });
            },
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'business@company.com',
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Owner BVN Field
          const Text(
            'Owner BVN *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _businessInfo.ownerBvn = value;
              });
            },
            keyboardType: TextInputType.number,
            maxLength: 11,
            decoration: InputDecoration(
              hintText: 'Enter owner\'s BVN',
              prefixIcon: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_businessInfo.businessName.trim().isNotEmpty &&
                      _businessInfo.phoneNumber.trim().isNotEmpty &&
                      _businessInfo.emailAddress.trim().isNotEmpty &&
                      _businessInfo.ownerBvn.trim().isNotEmpty &&
                      _businessInfo.cacNumber.trim().isNotEmpty)
                  ? _handleBusinessInfoSubmit
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  Widget _buildCBNBranding() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Regulated by CBN • Insured by NDIC',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: double.infinity,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  context.pop();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF6B7280),
                    size: 16,
                  ),
                ),
              ),

              // RimaPay Logo placeholder

              Row(
                spacing: 10,
                children: [
                  Image.asset(
                    "assets/images/AppIcon.png",
                    height: 30,
                    width: 30,
                  ),
                  const Text(
                    'RimaPay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B252),
                    ),
                  ),
                ],
              ),

              Text(
                'Step ${_getStepNumber()} of ${_getTotalSteps()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4), // Rounded corners
              child: LinearProgressIndicator(
                value: _getStepNumber() / _getTotalSteps(),
                minHeight: 2,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00B252), // green progress
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case BusinessAccountStep.businessTypeSelection:
        return _buildBusinessTypeSelection();
      case BusinessAccountStep.bnInfo:
        return _buildBNInfoStep();
      case BusinessAccountStep.llcInfo:
        return _buildLLCInfoStep();
      case BusinessAccountStep.otpVerification:
        return _buildOtpVerificationStep();
      // case BusinessAccountStep.bnDocuments:
      //   return _buildBNDocumentsStep();
      // case BusinessAccountStep.llcDocuments:
      //   return _buildLLCDocumentsStep();
      case BusinessAccountStep.ownerVerification:
        return _buildOwnerVerificationStep();
      // case BusinessAccountStep.directorsInfo:
      //   return _buildDirectorsInfoStep();
      case BusinessAccountStep.llcOwnerVerification:
        return _buildLLCOwnerVerificationStep();
      // case BusinessAccountStep.verificationLoading:
      //   return _buildVerificationLoadingStep();
      case BusinessAccountStep.setPin:
        return _buildSetPinStep();
      default:
        return _buildBusinessTypeSelection();
    }
  }

// LLC Info Step - Similar to BN but with company-specific fields
  Widget _buildLLCInfoStep() {
    final locations = getCountryLocation();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Company Registration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your company information for LLC registration',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Company Name Field
          const Text(
            'Company Name *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) => setState(() => _businessInfo.businessName = value),
            decoration: const InputDecoration(
              hintText: 'Enter registered company name',
              prefixIcon: Icon(Icons.business_outlined, color: Color(0xFF9CA3AF), size: 16),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // CAC Registration Number Field
          const Text(
            'CAC Registration Number *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) => setState(() => _businessInfo.cacNumber = value),
            decoration: const InputDecoration(
              hintText: 'RC1234567',
              prefixIcon: Icon(Icons.credit_card_outlined, color: Color(0xFF9CA3AF), size: 16),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
            ),
            maxLength: 9,
          ),

          const SizedBox(height: 16),
          // Company Address with Google Places
          const Text(
            'Company Address *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          GooglePlacesAutoCompleteTextFormField(
            textEditingController: _addressController,
            googleAPIKey: GOOGLE_API_KEY,
            debounceTime: 600,
            onSuggestionClicked: (prediction) {
              _addressController.text = prediction.description ?? "";
            },
            countries: const ["ng"],
            decoration: InputDecoration(
              hintText: 'Enter full company address',
              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 16),
              suffixIcon: IconButton(
                onPressed: _onLocateMePressed,
                icon: const Icon(Icons.my_location, color: Color(0xFF00B252), size: 20),
              ),
              fillColor: Colors.white,
              filled: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Company Phone
          const Text(
            'Company Phone *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) => setState(() => _businessInfo.phoneNumber = value),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '+234 801 234 5678',
              prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF), size: 16),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Company Email
          const Text(
            'Company Email *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) => setState(() => _businessInfo.emailAddress = value),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'company@business.com',
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF9CA3AF), size: 16),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // TIN Number with checkbox
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TIN Number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _businessInfo.tinApplicable,
                    onChanged: (value) => setState(() {
                      _businessInfo.tinApplicable = value ?? false;
                      if (_businessInfo.tinApplicable) _businessInfo.tin = '';
                    }),
                    activeColor: const Color(0xFF00B252),
                  ),
                  const Text(
                    'Not applicable',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
          if (!_businessInfo.tinApplicable) ...[
            const SizedBox(height: 6),
            TextFormField(
              onChanged: (value) => setState(() => _businessInfo.tin = value),
              decoration: const InputDecoration(
                hintText: 'Enter company TIN',
                prefixIcon: Icon(Icons.description_outlined, color: Color(0xFF9CA3AF), size: 16),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinueLLC() ? _handleBusinessLCCInfoSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  bool _canContinueLLC() {
    return _businessInfo.businessName.trim().isNotEmpty &&
        _businessInfo.phoneNumber.trim().isNotEmpty &&
        _businessInfo.emailAddress.trim().isNotEmpty &&
        _businessInfo.cacNumber.trim().isNotEmpty &&
        (_businessInfo.tinApplicable || _businessInfo.tin.trim().isNotEmpty);
  }

  // OTP Verification Step
  Widget _buildOtpVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B252), Color(0xFF00A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verify Phone Number',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the 6-digit code sent to ${_businessInfo.phoneNumber}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // OTP Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40,
                height: 40,
                child: TextFormField(
                  onChanged: (value) {
                    setState(() => _otp[index] = value);
                    if (value.isNotEmpty && index < 5) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                  onTap: () => setState(() => _otp[index] = ''),
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF00B252), width: 2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Resend Code
          const Text(
            'Didn\'t receive the code?',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Resend OTP logic
            },
            child: const Text(
              'Resend Code',
              style: TextStyle(fontSize: 12, color: Color(0xFF00B252), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 32),

          // Verify Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || _otp.any((digit) => digit.isEmpty)) ? null : _handleOtpSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Verifying...'),
                      ],
                    )
                  : const Text('Verify & Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  // BN Documents Upload Step
  Widget _buildBNDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_file, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload Documents',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload required documents for BN verification',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Document upload items
          _buildDocumentItem(
            'CAC Certificate',
            'Certificate of Business Name Registration',
            Icons.description,
            _bnDocs.cacCertificate,
            () => setState(() => _bnDocs.cacCertificate = true),
            isRequired: true,
          ),
          _buildDocumentItem(
            'Owner ID',
            'Valid government-issued ID',
            Icons.credit_card,
            _bnDocs.ownerID,
            () => setState(() => _bnDocs.ownerID = true),
            isRequired: true,
          ),
          _buildDocumentItem(
            'Utility Bill',
            'Recent utility bill (max 3 months old)',
            Icons.description,
            _bnDocs.utilityBill,
            () => setState(() => _bnDocs.utilityBill = true),
            isRequired: true,
          ),
          _buildDocumentItem(
            'Passport Photo',
            'Clear passport photograph',
            Icons.camera_alt,
            _bnDocs.passportPhoto,
            () => setState(() => _bnDocs.passportPhoto = true),
            isRequired: true,
          ),
          _buildDocumentItem(
            'BN Form',
            'Business Name Registration Form',
            Icons.description,
            _bnDocs.bnForm,
            () => setState(() => _bnDocs.bnForm = true),
            isRequired: false,
          ),
          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinueBNDocs() ? _handleDocumentsSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue to Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  bool _canContinueBNDocs() {
    return _bnDocs.cacCertificate && _bnDocs.ownerID && _bnDocs.utilityBill && _bnDocs.passportPhoto;
  }

  // LLC Documents Upload Step
  Widget _buildLLCDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_file, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload Documents',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload required documents for LLC verification',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // LLC Document upload items
          _buildDocumentItem(
            'CAC Certificate',
            'Certificate of Incorporation',
            Icons.description,
            _llcDocs.cacIncorporation,
            () => setState(() => _llcDocs.cacIncorporation = true),
            isRequired: true,
          ),
          _buildDocumentItem(
            'Status Report',
            'Current CAC Status Report',
            Icons.description,
            _llcDocs.cacStatusReport,
            () => setState(() => _llcDocs.cacStatusReport = true),
            isRequired: true,
          ),
          _buildDocumentItem(
            'Memorandum & Articles',
            'Memorandum & Articles of Association',
            Icons.description,
            _llcDocs.memorandumArticles,
            () => setState(() => _llcDocs.memorandumArticles = true),
            isRequired: true,
          ),
          _buildDocumentItem(
            'Board Resolution',
            'Board resolution for account opening',
            Icons.description,
            _llcDocs.boardResolution,
            () => setState(() => _llcDocs.boardResolution = true),
            isRequired: true,
          ),
          _buildDocumentItem(
            'Utility Bill',
            'Recent utility bill (max 3 months old)',
            Icons.description,
            _llcDocs.utilityBill,
            () => setState(() => _llcDocs.utilityBill = true),
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinueLLCDocs() ? _handleDocumentsSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue to Directors Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  bool _canContinueLLCDocs() {
    return _llcDocs.cacIncorporation && _llcDocs.cacStatusReport && _llcDocs.memorandumArticles && _llcDocs.boardResolution && _llcDocs.utilityBill;
  }

  Widget _buildDocumentUploadItem(
    String docKey,
    String title,
    String description,
    IconData icon, {
    bool isRequired = false,
    bool allowCamera = false,
  }) {
    bool isUploaded = _uploadedDocuments.containsKey(docKey);
    String? fileName = isUploaded ? _getFileName(_uploadedDocuments[docKey]!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isUploaded ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(8),
        color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(' *', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
              ],
              const Spacer(),
              if (isUploaded) const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)) else const Icon(Icons.upload_file, size: 16, color: Color(0xFF6B7280)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          if (isUploaded && fileName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file, size: 12, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      fileName,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF059669)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _uploadDocument(docKey),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isUploaded ? const Color(0xFFD1FAE5) : Colors.white,
                    side: BorderSide(
                      color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF00B252),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    isUploaded ? 'Change File' : 'Choose File',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUploaded ? const Color(0xFF059669) : const Color(0xFF00B252),
                    ),
                  ),
                ),
              ),
              if (allowCamera && !isUploaded) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _captureDocs(docKey),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00B252)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 14, color: Color(0xFF00B252)),
                        SizedBox(width: 4),
                        Text(
                          'Take Photo',
                          style: TextStyle(fontSize: 12, color: Color(0xFF00B252)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (isUploaded) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeDocument(docKey),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  // Document Item Widget
  Widget _buildDocumentItem(String title, String description, IconData icon, bool isUploaded, VoidCallback onTap, {required bool isRequired}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6B7280), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    if (isRequired) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ),
              ),
              isUploaded
                  ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16)
                  : TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      child: const Text('Upload', style: TextStyle(fontSize: 12, color: Color(0xFF00B252))),
                    ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }

  void _removeDocument(String docKey) {
    setState(() {
      _uploadedDocuments.remove(docKey);
      // if (_businessType == 'BN') {
      //   _bnDocs[docKey] = false;
      // } else {
      //   _llcDocs[docKey] = false;
      // }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document removed')),
    );
  }

  Widget _buildDirectorsInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Directors Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add information for company directors (minimum 1, maximum 5)',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Directors List
          Column(
            children: _businessInfo.directors.asMap().entries.map((entry) {
              int index = entry.key;
              Director director = entry.value;
              return _buildDirectorCard(director, index);
            }).toList(),
          ),

          // Add Director Button
          if (_businessInfo.directors.length < 5)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                onPressed: _addDirector,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD1D5DB), style: BorderStyle.solid, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add, size: 16, color: Color(0xFF6B7280)),
                    SizedBox(width: 8),
                    Text(
                      'Add Director',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canContinueDirectors() ? _handleDirectorsInfoSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue to Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  void _handleDirectorsInfoSubmit() {
    setState(() {
      _currentStep = BusinessAccountStep.ownerVerification;
    });
  }

  Widget _buildDirectorCard(Director director, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Director ${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const Spacer(),
              if (_businessInfo.directors.length > 1)
                IconButton(
                  onPressed: () => _removeDirector(director.id),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Full Name
          const Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: director.name,
            onChanged: (value) => _updateDirector(director.id, 'name', value),
            decoration: const InputDecoration(
              hintText: 'Enter full name',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),

          // ID Type
          const Text('ID Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: director.idType.isEmpty ? 'NIN' : director.idType,
            onChanged: (value) => _updateDirector(director.id, 'idType', value ?? 'NIN'),
            decoration: const InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'NIN', child: Text('National ID (NIN)')),
              DropdownMenuItem(value: 'PASSPORT', child: Text('International Passport')),
              DropdownMenuItem(value: 'DRIVERS_LICENSE', child: Text('Driver\'s License')),
              DropdownMenuItem(value: 'VOTERS_CARD', child: Text('Voter\'s Card')),
            ],
          ),
          const SizedBox(height: 12),

          // BVN
          const Text('BVN *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: director.bvn,
            onChanged: (value) => _updateDirector(director.id, 'bvn', value),
            keyboardType: TextInputType.number,
            maxLength: 11,
            decoration: const InputDecoration(
              hintText: 'Enter BVN',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),

          // Upload buttons
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Photo Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await _uploadPhoto();
                          _updateDirector(director.id, 'photoUploaded', true);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: director.photoUploaded ? const Color(0xFFF0FDF4) : Colors.white,
                          side: BorderSide(color: director.photoUploaded ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          director.photoUploaded ? '✓ Uploaded' : 'Upload Photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: director.photoUploaded ? const Color(0xFF059669) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ID Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await _uploadDocument('directorID_${director.id}');
                          _updateDirector(director.id, 'idUploaded', true);
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: director.idUploaded ? const Color(0xFFF0FDF4) : Colors.white,
                          side: BorderSide(color: director.idUploaded ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          director.idUploaded ? '✓ Uploaded' : 'Upload ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: director.idUploaded ? const Color(0xFF059669) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateDirector(String id, String field, dynamic value) {
    setState(() {
      final index = _businessInfo.directors.indexWhere((director) => director.id == id);
      if (index != -1) {
        switch (field) {
          case 'name':
            _businessInfo.directors[index].name = value;
            break;
          case 'idType':
            _businessInfo.directors[index].idType = value;
            break;
          case 'bvn':
            _businessInfo.directors[index].bvn = value;
            break;
          case 'photoUploaded':
            _businessInfo.directors[index].photoUploaded = value;
            break;
          case 'idUploaded':
            _businessInfo.directors[index].idUploaded = value;
            break;
        }
      }
    });
  }

  bool _canContinueDirectors() {
    return _businessInfo.directors.isNotEmpty &&
        _businessInfo.directors.every((director) => director.name.trim().isNotEmpty && director.bvn.trim().isNotEmpty && director.photoUploaded && director.idUploaded);
  }

  void _addDirector() {
    if (_businessInfo.directors.length >= 5) return;
    setState(() {
      _businessInfo.directors.add(Director(id: DateTime.now().millisecondsSinceEpoch.toString()));
    });
  }

  void _removeDirector(String id) {
    setState(() {
      _businessInfo.directors.removeWhere((director) => director.id == id);
    });
  }

  // Owner Verification with Real Camera
  Widget _buildOwnerVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B252), Color(0xFF00A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Identity Verification',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Take a selfie to verify your identity',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Camera Interface
          if (!_cameraActive && _capturedImage == null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 40, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 12),
                  const Text(
                    'Ready to take your photo?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Make sure you\'re in good lighting and your face is clearly visible',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _startCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B252),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Start Camera'),
                  ),
                ],
              ),
            ),

          // Live Camera View
          (_cameraActive && _cameraController != null && _cameraController!.value.isInitialized)
              ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00B252), width: 4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CameraPreview(
                          _cameraController!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => _cameraActive = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: _capturePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B252),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ],
                )
              : const SizedBox.shrink(),

          // Captured Photo Preview
          if (_capturedImage != null)
            Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00B252), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(_capturedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  spacing: 10,
                  children: [
                    TextButton(
                      onPressed: _retakePhoto,
                      child: const Text('Retake', style: TextStyle(color: Color(0xFF6B7280))),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _handleVerificationComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B252),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ],
            ),

          // Camera Error Display
          if (_cameraError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                      SizedBox(width: 8),
                      Text('Camera Error', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF991B1B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_cameraError!, style: const TextStyle(fontSize: 14, color: Color(0xFFDC2626))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _uploadingPhoto ? null : _uploadPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFECACA),
                      foregroundColor: const Color(0xFF991B1B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_uploadingPhoto ? 'Uploading...' : 'Upload Photo Instead'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          TextButton(
            onPressed: _handleVerificationComplete,
            child: const Text(
              'Skip verification (not recommended)',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  // Password Requirements Helper
  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? const Color(0xFF059669) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // Set PIN Step - Complete implementation
  Widget _buildSetPinStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B252), Color(0xFF00A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create Password',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set up your account password for secure access',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Password Field
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Password *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) => setState(() => _password = value),
            obscureText: !_showPassword,
            decoration: InputDecoration(
              hintText: 'Enter password (min 8 characters)',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9CA3AF), size: 16),
              ),
              fillColor: Colors.white,
              filled: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Confirm Password *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) => setState(() => _confirmPassword = value),
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Confirm your password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9CA3AF), size: 16),
              ),
              fillColor: Colors.white,
              filled: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
              ),
            ),
          ),

          // Password Strength Indicators
          if (_password.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Password strength:',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                _buildPasswordRequirement('At least 8 characters', _password.length >= 8),
                _buildPasswordRequirement('One uppercase letter', _password.contains(RegExp(r'[A-Z]'))),
                _buildPasswordRequirement('One number', _password.contains(RegExp(r'[0-9]'))),
              ],
            ),
          ],
          const SizedBox(height: 32),

          // Create Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canCreateAccount() ? _handlePinSet : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Create Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  bool _canCreateAccount() {
    return _password.isNotEmpty && _confirmPassword.isNotEmpty && _password == _confirmPassword && _password.length >= 8;
  }

// LLC Owner Verification Step - Now with real camera functionality
  Widget _buildLLCOwnerVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B252), Color(0xFF00A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Owner Identity Verification',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Take a selfie to verify the primary owner\'s identity',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Camera Interface - Ready to take photo state
          if (!_cameraActive && _capturedImage == null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 40, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 12),
                  const Text(
                    'Ready to take your photo?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Make sure you\'re in good lighting and your face is clearly visible',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _startCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B252),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Start Camera'),
                  ),
                ],
              ),
            ),

          // Live Camera View
          (_cameraActive && _cameraController != null && _cameraController!.value.isInitialized)
              ? Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00B252), width: 4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CameraPreview(
                          _cameraController!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => _cameraActive = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: _capturePhoto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B252),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ],
                )
              : const SizedBox.shrink(),

          // Captured Photo Preview
          if (_capturedImage != null)
            Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00B252), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(_capturedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  spacing: 10,
                  children: [
                    TextButton(
                      onPressed: _retakePhoto,
                      child: const Text('Retake', style: TextStyle(color: Color(0xFF6B7280))),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _handleVerificationComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B252),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ],
            ),

          // Camera Error Display
          if (_cameraError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                      SizedBox(width: 8),
                      Text('Camera Error', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF991B1B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_cameraError!, style: const TextStyle(fontSize: 14, color: Color(0xFFDC2626))),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _uploadingPhoto ? null : _uploadPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFECACA),
                      foregroundColor: const Color(0xFF991B1B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_uploadingPhoto ? 'Uploading...' : 'Upload Photo Insteaad'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          TextButton(
            onPressed: _handleVerificationComplete,
            child: const Text(
              'Skip verification (not recommended)',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(height: 24),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  // Verification Loading Step
  Widget _buildVerificationLoadingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B252), Color(0xFF00A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          const Text(
            'Verifying Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we verify your business information and documents',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Progress Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: _verificationProgress / 100,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B252)),
                ),
              ),
              Text(
                '${_verificationProgress.round()}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Loading dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B252),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          _buildCBNBranding(),
        ],
      ),
    );
  }

  // // Set PIN Step
  // Widget _buildSetPinStep() {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.symmetric(horizontal: 24),
  //     child: Column(
  //       children: [
  //         const SizedBox(height: 40),
  //         Container(
  //           width: 40,
  //           height: 40,
  //           decoration: const BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [Color(0xFF00B252), Color(0xFF00A047)],
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //             ),
  //             shape: BoxShape.circle,
  //           ),
  //           child: const Icon(Icons.shield, color: Colors.white, size: 20),
  //         ),
  //         const SizedBox(height: 8),
  //         const Text(
  //           'Create Password',
  //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
  //         ),
  //         const SizedBox(height: 4),
  //         const Text(
  //           'Set up your account password for secure access',
  //           style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 32),

  //         // Password Field
  //         const Align(
  //           alignment: Alignment.centerLeft,
  //           child: Text(
  //             'Password *',
  //             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
  //           ),
  //         ),
  //         const SizedBox(height: 6),
  //         TextFormField(
  //           onChanged: (value) => setState(() => _password = value),
  //           obscureText: !_showPassword,
  //           decoration: InputDecoration(
  //             hintText: 'Enter password (min 8 characters)',
  //             suffixIcon: IconButton(
  //               onPressed: () => setState(() => _showPassword = !_showPassword),
  //               icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility,
  //                         color: const Color(0xFF9CA3AF), size: 16),
  //             ),
  //             fillColor: Colors.white,
  //             filled: true,
  //             border: const OutlineInputBorder(
  //               borderRadius: BorderRadius.all(Radius.circular(8)),
  //               borderSide: BorderSide(color: Color(0xFFE5E7EB)),
  //             ),
  //             focusedBorder: const OutlineInputBorder(
  //               borderRadius: BorderRadius.all(Radius.circular(8)),
  //               borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 16),

  //         // Confirm Password Field
  //         const Align(
  //           alignment: Alignment.centerLeft,
  //           child: Text(
  //             'Confirm Password *',
  //             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
  //           ),
  //         ),
  //         const SizedBox(height: 6),
  //         TextFormField(
  //           onChanged: (value) => setState(() => _confirmPassword = value),
  //           obscureText: !_showConfirmPassword,
  //           decoration: InputDecoration(
  //             hintText: 'Confirm your password',
  //             suffixIcon: IconButton(
  //               onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
  //               icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility,
  //                         color: const Color(0xFF9CA3AF), size: 16),
  //             ),
  //             fillColor: Colors.white,
  //             filled: true,
  //             border: const OutlineInputBorder(
  //               borderRadius: BorderRadius.all(Radius.circular(8)),
  //               borderSide: BorderSide(color: Color(0xFFE5E7EB)),
  //             ),
  //             focusedBorder: const OutlineInputBorder(
  //               borderRadius: BorderRadius.all(Radius.circular(8)),
  //               borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
  //             ),
  //           ),
  //         ),

  //         // Password Strength Indicators
  //         if (_password.isNotEmpty) ...[
  //           const SizedBox(height: 16),
  //           const Align(
  //             alignment: Alignment.centerLeft,
  //             child: Text(
  //               'Password strength:',
  //               style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Column(
  //             children: [
  //               _buildPasswordRequirement('At least 8 characters', _password.length >= 8),
  //               _buildPasswordRequirement('One uppercase letter', _password.contains(RegExp(r'[A-Z]'))),
  //               _buildPasswordRequirement('One number', _password.contains(RegExp(r'[0-9]'))),
  //             ],
  //           ),
  //         ],
  //         const SizedBox(height: 32),

  //         // Create Account Button
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             onPressed: _canCreateAccount() ? _handlePinSet : null,
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: const Color(0xFF00B252),
  //               foregroundColor: Colors.white,
  //               padding: const EdgeInsets.symmetric(vertical: 12),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //             ),
  //             child: const Text('Create Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
  //           ),
  //         ),
  //         const SizedBox(height: 24),
  //         _buildCBNBranding(),
  //       ],
  //     ),
  //   );
  // }

  // // Add placeholder methods for other steps
  // Widget _buildLLCInfoStep() {
  //   // Similar to BN info but with LLC-specific fields
  //   return const Center(child: Text('LLC Info Step - To be implemented'));
  // }

  // Widget _buildOtpVerificationStep() {
  //   return const Center(child: Text('OTP Verification Step - To be implemented'));
  // }

  // Widget _buildBNDocumentsStep() {
  //   return const Center(child: Text('BN Documents Step - To be implemented'));
  // }

  // Widget _buildLLCDocumentsStep() {
  //   return const Center(child: Text('LLC Documents Step - To be implemented'));
  // }

  // Widget _buildOwnerVerificationStep() {
  //   return const Center(child: Text('Owner Verification Step - To be implemented'));
  // }

  // Widget _buildDirectorsInfoStep() {
  //   return const Center(child: Text('Directors Info Step - To be implemented'));
  // }

  // Widget _buildLLCOwnerVerificationStep() {
  //   return const Center(child: Text('LLC Owner Verification Step - To be implemented'));
  // }

  // Widget _buildVerificationLoadingStep() {
  //   return const Center(child: Text('Verification Loading Step - To be implemented'));
  // }
}
