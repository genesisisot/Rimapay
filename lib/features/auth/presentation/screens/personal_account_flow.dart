import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:developer';

import 'package:rimapay/core/Models/CountryStateLgaModel.dart';
import 'package:rimapay/core/Utils/En.dart';
import 'package:rimapay/core/services/GetPlaceDetailsService.dart';

enum AccountStep {
  personalInfo,
  otpVerification,
  bvnVerification,
  livenessCheck,
  setPin,
  success,
}

class PersonalInfo {
  String fullName = '';
  String dateOfBirth = '';
  String gender = '';
  String phoneNumber = '';
  String emailAddress = '';
  String residentialAddress = '';
  String state = '';
  String lga = '';
  String bvn = '';
  String nin = '';
  double? currentLat;
  double? currentLng;
}

class Prediction {
  final String? placeId;
  final String? description;
  final String? lat;
  final String? lng;

  Prediction({
    this.placeId,
    this.description,
    this.lat,
    this.lng,
  });
}

class PersonalAccountFlow extends ConsumerStatefulWidget {
  const PersonalAccountFlow({
    super.key,
  });

  @override
  ConsumerState<PersonalAccountFlow> createState() => _PersonalAccountFlowState();
}

class _PersonalAccountFlowState extends ConsumerState<PersonalAccountFlow> with TickerProviderStateMixin {
  AccountStep _currentStep = AccountStep.personalInfo;
  final PersonalInfo _personalInfo = PersonalInfo();
  final List<String> _otp = List.filled(6, '');
  final List<String> _pin = List.filled(4, '');
  String _password = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  bool _showUnderbanking = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _completedLiveness = false;
  bool _cameraActive = false;
  String? _capturedImage;
  String? _cameraError;
  bool _permissionDenied = false;
  bool _isGettingLocation = false;

  // Address and location related fields
  final _addressController = TextEditingController();
  CountryStateLgaModel? selectedState;
  Local? selectedLga;
  @override
  List<Local>? locals;
  Prediction? selectedCoordinate;

  CameraController? _cameraController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(_scaleController);

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _cameraController?.dispose();
    _addressController.dispose();
    super.dispose();
  }

  int _getStepNumber(AccountStep step) {
    return AccountStep.values.indexOf(step) + 1;
  }

  String? _validatePasswords() {
    if (_password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (_password != _confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _handlePersonalInfoSubmit() {
    if (_personalInfo.bvn.trim().isEmpty && _personalInfo.nin.trim().isEmpty) {
      setState(() {
        _showUnderbanking = true;
      });
      return;
    }
    setState(() {
      _currentStep = AccountStep.otpVerification;
    });
  }

  void _handleUnderbanking() {
    setState(() {
      _showUnderbanking = false;
      _currentStep = AccountStep.otpVerification;
    });
  }

  void _handleOtpSubmit() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
        if (_personalInfo.bvn.trim().isNotEmpty || _personalInfo.nin.trim().isNotEmpty) {
          _currentStep = AccountStep.bvnVerification;
        } else {
          _currentStep = AccountStep.setPin;
        }
      });
    });
  }

  void _handleBvnVerification() {
    setState(() {
      _currentStep = AccountStep.livenessCheck;
    });
  }

  void _handleLivenessCheck() {
    if (_capturedImage != null) {
      setState(() {
        _completedLiveness = true;
        _currentStep = AccountStep.setPin;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture your photo first')),
      );
    }
  }

  void _handlePinSet() {
    final passwordError = _validatePasswords();
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    setState(() {
      _currentStep = AccountStep.success;
    });
  }

  // Location related methods
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
              _personalInfo.residentialAddress = address;

              selectedCoordinate = Prediction(
                placeId: null,
                description: address,
                lat: position.latitude.toString(),
                lng: position.longitude.toString(),
              );

              _personalInfo.currentLat = position.latitude;
              _personalInfo.currentLng = position.longitude;
            });

            final locations = getCountryLocation();
            if (placemark.administrativeArea != null) {
              final service = ref.read(locationDetailsServiceProvider);
              final matchingState = service.findMatchingState(placemark.administrativeArea!, locations);
              if (matchingState != null) {
                setState(() {
                  selectedState = matchingState;
                  _personalInfo.state = matchingState.state?.name ?? '';
                  locals = matchingState.state?.locals;

                  if (placemark.subAdministrativeArea != null && locals != null) {
                    selectedLga = service.findMatchingLGA(placemark.subAdministrativeArea!, locals!);
                    if (selectedLga != null) {
                      _personalInfo.lga = selectedLga!.name ?? '';
                    }
                  } else {
                    selectedLga = null;
                    _personalInfo.lga = '';
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
            _personalInfo.residentialAddress = _addressController.text;
            selectedCoordinate = Prediction(
              placeId: null,
              description: "Current Location",
              lat: position.latitude.toString(),
              lng: position.longitude.toString(),
            );
            _personalInfo.currentLat = position.latitude;
            _personalInfo.currentLng = position.longitude;
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

  // Camera methods (keeping existing implementation)
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera found on this device';
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

      if (mounted) {
        setState(() {
          _cameraActive = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to initialize camera: ${e.toString()}';
        _cameraActive = false;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _initializeCamera();
    } else {
      setState(() {
        _permissionDenied = true;
        _cameraError = 'Camera permission denied. Please allow camera access and try again.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image.path;
        _cameraActive = false;
      });
      _cameraController?.dispose();
      _cameraController = null;
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to capture photo: ${e.toString()}';
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _cameraError = null;
      _permissionDenied = false;
    });
    _requestCameraPermission();
  }

  Widget _buildPersonalInfoStep() {
    final locations = getCountryLocation();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Full Name Field
          const Text(
            'Full Name *',
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
                _personalInfo.fullName = value;
              });
            },
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.person_outline,
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

          // Date of Birth and Gender Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date of Birth *',
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
                          _personalInfo.dateOfBirth = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'YYYY-MM-DD',
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
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _personalInfo.dateOfBirth = date.toString().split(' ')[0];
                          });
                        }
                      },
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gender *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _personalInfo.gender.isEmpty ? null : _personalInfo.gender,
                      onChanged: (value) {
                        setState(() {
                          _personalInfo.gender = value ?? '';
                        });
                      },
                      decoration: InputDecoration(
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
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Phone Number Field
          const Text(
            'Phone Number *',
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
                _personalInfo.phoneNumber = value;
              });
            },
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+234 801 234 5678',
              prefixIcon: const Icon(
                Icons.phone_outlined,
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

          // Email Field
          const Text(
            'Email Address (Optional)',
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
                _personalInfo.emailAddress = value;
              });
            },
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'you@example.com (optional)',
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

          // Address Field with Google Places Autocomplete
          const Text(
            'Residential Address *',
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
            countries: const ["ng"], // Nigeria only

            onPlaceDetailsWithCoordinatesReceived: (prediction) {
              setState(() {
                _personalInfo.residentialAddress = prediction.description ?? '';
                selectedCoordinate = Prediction(
                  description: prediction.description,
                  lat: prediction.lat,
                  lng: prediction.lng,
                  placeId: prediction.placeId,
                );
                _personalInfo.currentLat = double.tryParse(prediction.lat ?? "0");
                _personalInfo.currentLng = double.tryParse(prediction.lng ?? "0");
              });

              // You can add logic here to automatically set state and LGA based on the address
            },
            decoration: InputDecoration(
              hintText: 'Enter your full address',
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
                _personalInfo.state = value?.state?.name ?? '';
                locals = value?.state?.locals;
                selectedLga = null;
                _personalInfo.lga = '';
                // Clear address and coordinates when state changes manually
                selectedCoordinate = null;
                _addressController.clear();
                _personalInfo.residentialAddress = '';
              });
            },
            decoration: InputDecoration(
              hintText: 'Select your state',
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
                      _personalInfo.lga = value?.name ?? '';
                    });
                  },
            decoration: InputDecoration(
              hintText: selectedState == null ? 'Select state first' : 'Select your LGA',
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

          // Tier 1 Requirements Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2563EB),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tier 1 Account Requirements',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Provide either BVN OR NIN (only one required)\n• Complete mandatory liveness check with image capture\n• Skip both for Underbanking Profile (₦50,000 daily limit)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BVN Field
          const Text(
            'BVN (Choose BVN or NIN below)',
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
                _personalInfo.bvn = value;
              });
            },
            keyboardType: TextInputType.number,
            maxLength: 11,
            decoration: InputDecoration(
              hintText: 'Enter 11-digit BVN',
              prefixIcon: const Icon(
                Icons.credit_card,
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
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),

          const Center(
            child: Text(
              'OR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // NIN Field
          const Text(
            'NIN (Choose BVN or NIN above)',
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
                _personalInfo.nin = value;
              });
            },
            keyboardType: TextInputType.number,
            maxLength: 11,
            decoration: InputDecoration(
              hintText: 'Enter 11-digit NIN',
              prefixIcon: const Icon(
                Icons.person_outline,
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
              counterText: '',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '💡 Providing BVN or NIN enables Tier 1 with higher limits + mandatory liveness check',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_personalInfo.fullName.isNotEmpty &&
                      _personalInfo.phoneNumber.isNotEmpty &&
                      _personalInfo.state.isNotEmpty &&
                      _personalInfo.lga.isNotEmpty &&
                      _personalInfo.residentialAddress.isNotEmpty)
                  ? _handlePersonalInfoSubmit
                  : null,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    final hasBvn = _personalInfo.bvn.trim().isNotEmpty;
    final hasEmail = _personalInfo.emailAddress.trim().isNotEmpty;

    String verificationMessage;
    if (hasBvn) {
      verificationMessage = "We've sent verification codes to your BVN-registered phone number and email address";
    } else if (hasEmail) {
      verificationMessage = "We've sent verification codes to ${_personalInfo.phoneNumber} and ${_personalInfo.emailAddress}";
    } else {
      verificationMessage = "We've sent a verification code to ${_personalInfo.phoneNumber}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B252), Color(0xFF00A047)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasBvn
                ? 'Verify BVN Contacts'
                : hasEmail
                    ? 'Verify Your Phone & Email'
                    : 'Verify Your Phone Number',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            verificationMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (hasBvn) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📱 BVN Verification: We\'re using your BVN-registered contacts for enhanced security',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'Enter 6-digit code from SMS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _otp[index] = value;
                    });
                    if (value.isNotEmpty && index < 5) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
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
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || _otp.any((digit) => digit.isEmpty)) ? null : _handleOtpSubmit,
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
                      'Verify',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivenessStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00B252), Color(0xFF00A047)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mandatory Liveness Verification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete liveness check to verify your identity - this step is required for Tier 1',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Required for Tier 1 Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFDC2626),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Required for Tier 1',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• This step cannot be skipped for Tier 1 accounts\n• Your photo will be securely stored for identity verification',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Camera Guidelines
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildGuidelineItem('Look directly at the camera'),
                _buildGuidelineItem('Ensure good lighting'),
                _buildGuidelineItem('Remove glasses if possible'),
                _buildGuidelineItem('Hold device steady'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Camera Interface
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                if (_cameraError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFECACA)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFDC2626),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Camera Access Issue',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _cameraError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!_cameraActive && _capturedImage == null) ...[
                  Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _requestCameraPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B252),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_cameraError != null ? 'Try Again' : 'Start Camera'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📱 Make sure to allow camera access when prompted',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_cameraActive && _capturedImage == null) ...[
                  Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00B252), width: 2),
                    ),
                    child: _cameraController != null && _cameraController!.value.isInitialized
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CameraPreview(_cameraController!),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00B252),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _cameraController?.dispose();
                          _cameraController = null;
                          setState(() {
                            _cameraActive = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7280),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _capturePhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B252),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('📸 Capture'),
                      ),
                    ],
                  ),
                ],
                if (_capturedImage != null) ...[
                  Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00B252), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _capturedImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Color(0xFFDC2626),
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _retakePhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B7280),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retake'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _handleLivenessCheck,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B252),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('✓ Confirm & Continue'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '🔒 Your image is encrypted and securely stored for identity verification purposes only',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(
            Icons.check,
            color: Color(0xFF00B252),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Create Password & Transaction PIN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your account security credentials',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Password Fields
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Account Password *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _password = value;
              });
            },
            obscureText: !_showPassword,
            decoration: InputDecoration(
              hintText: 'Create a strong password',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF9CA3AF),
                  size: 16,
                ),
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
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Must be at least 8 characters long',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Confirm Password *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _confirmPassword = value;
              });
            },
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              hintText: 'Confirm your password',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF9CA3AF),
                size: 16,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
                icon: Icon(
                  _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF9CA3AF),
                  size: 16,
                ),
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
          if (_password.isNotEmpty && _confirmPassword.isNotEmpty && _password != _confirmPassword) ...[
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Passwords do not match',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Transaction PIN
          const Text(
            'Transaction PIN *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a 4-digit PIN to secure your transactions',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      _pin[index] = value;
                    });
                    if (value.isNotEmpty && index < 3) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
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
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_pin.any((digit) => digit.isEmpty) || _password.isEmpty || _confirmPassword.isEmpty) ? null : _handlePinSet,
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
                'Complete Setup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your RimaPay Account is Ready! 🎉',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Welcome to the future of digital banking',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00B252).withOpacity(0.1),
                  const Color(0xFF00A047).withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF00B252).withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildAccountDetailRow('Account Number:', '2001234567', isHighlight: true),
                const SizedBox(height: 12),
                _buildAccountDetailRow(
                    'Account Tier:',
                    _personalInfo.bvn.isNotEmpty && _completedLiveness
                        ? 'Tier 2'
                        : _personalInfo.bvn.isNotEmpty
                            ? 'Tier 1 (BVN)'
                            : 'Tier 1'),
                const SizedBox(height: 12),
                _buildAccountDetailRow(
                    'Daily Limit:',
                    _personalInfo.bvn.isNotEmpty && _completedLiveness
                        ? '₦500,000'
                        : _personalInfo.bvn.isNotEmpty
                            ? '₦200,000'
                            : '₦50,000'),
                if (_personalInfo.bvn.isNotEmpty && !_completedLiveness) ...[
                  const SizedBox(height: 12),
                  _buildAccountDetailRow('Next Upgrade:', 'Complete Liveness → Tier 2', isUpgrade: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAccountDetailRow(String label, String value, {bool isHighlight = false, bool isUpgrade = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight
                ? const Color(0xFF00B252)
                : isUpgrade
                    ? const Color(0xFF00B252)
                    : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        setState(() => _currentStep = AccountStep.personalInfo);
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFF0FDF4),
                Color(0xFFDCFCE7),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _currentStep == AccountStep.personalInfo
                              ? () {
                                  context.pop();
                                }
                              : () => setState(() => _currentStep = AccountStep.personalInfo),
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
                          'Step ${_getStepNumber(_currentStep)} of 6',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress Bar
                  // Progress Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4), // Rounded corners
                      child: LinearProgressIndicator(
                        value: _getStepNumber(_currentStep) / 6, // progress (0.0 - 1.0)
                        minHeight: 2,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00B252), // green progress
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildCurrentStep(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Underbanking Modal
        bottomSheet: _showUnderbanking ? _buildUnderbankingModal() : null,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case AccountStep.personalInfo:
        return _buildPersonalInfoStep();
      case AccountStep.otpVerification:
        return _buildOtpStep();
      case AccountStep.bvnVerification:
        return _buildBvnVerificationStep();
      case AccountStep.livenessCheck:
        return _buildLivenessStep();
      case AccountStep.setPin:
        return _buildPinStep();
      case AccountStep.success:
        return _buildSuccessStep();
    }
  }

  Widget _buildBvnVerificationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'BVN Verification',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please confirm your details retrieved from BVN',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildBvnDetailRow('Name:', _personalInfo.fullName),
                const SizedBox(height: 8),
                _buildBvnDetailRow('Date of Birth:', _personalInfo.dateOfBirth),
                const SizedBox(height: 8),
                _buildBvnDetailRow('Phone:', _personalInfo.phoneNumber),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleBvnVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B252),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBvnDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildUnderbankingModal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF059669),
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Underbanking Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'You are opening an Underbanking Profile linked to a Cooperative Pool with daily limits of ₦50,000 until you upgrade with BVN/NIN + mandatory liveness verification.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showUnderbanking = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF374151),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleUnderbanking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B252),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
}
