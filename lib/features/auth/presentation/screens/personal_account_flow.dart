import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rimapay/Constants/En.dart';
import 'package:rimapay/Services/PersonAuthServices/CreatePinService.dart';
import 'package:rimapay/Services/PersonAuthServices/OtpServices.dart';
import 'package:rimapay/Services/PersonAuthServices/PersonalSignUpService.dart';
import 'package:rimapay/Services/SessionServices/GetSessionId.dart';
import 'package:rimapay/Utils/Logics.dart';
import 'dart:developer';

import 'package:rimapay/core/Models/CountryStateLgaModel.dart';
import 'package:rimapay/core/Utils/En.dart';
import 'package:rimapay/core/services/GetPlaceDetailsService.dart';

enum AccountStep {
  personalInfo,
  otpVerification,
  setPin,
}

class PersonalInfo {
  String firstname = '';
  String lastname = '';
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
  final bool _completedLiveness = false;
  bool _cameraActive = false;
  String? _capturedImage;
  String? _cameraError;
  bool _permissionDenied = false;
  bool _isGettingLocation = false;

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _acceptTerms = false;

  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();

  // Address and location related fields
  final _addressController = TextEditingController();
  CountryStateLgaModel? selectedState;
  Local? selectedLga;
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
    _birthdayController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bvnController.dispose();
    _ninController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PersonalSignupResponse?>(signupResponseStateProvider, (previous, next) {
      if (next != null) {
        setState(() {
          _isLoading = false;
        });

        if (next.status == SUCCESS) {
          setState(() {
            _currentStep = AccountStep.otpVerification;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errmessage ?? 'Registration successful! Please verify your phone number.'),
              backgroundColor: const Color(0xFF00B252),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errmessage ?? 'Failed to create account. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    });
    ref.listen(verifyOtpResponseStateProvider, (prev, next) {
      setState(() {
        _isLoading = false;
      });
      if (next?.model != null) {
        setState(() {
          _currentStep = AccountStep.setPin;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next?.errmessage ?? 'Failed to create account. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
    ref.listen(resendOtpResponseStateProvider, (prev, next) {
      setState(() {
        _isResending = false;
      });
      if (next?.model != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Otp Resent Successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next?.errmessage ?? 'Failed to resend otp. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
    ref.listen(createPinResponseStateProvider, (prev, next) {
      setState(() {
        _creatingPin = false;
      });
      if (next?.model != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your Account has been created successfully and pin activated, please login with your credentials'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/auth?mode=login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next?.errmessage ?? ERROR_TEXT),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (_currentStep != AccountStep.personalInfo) {
          setState(() => _currentStep = AccountStep.personalInfo);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
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
                          'Step ${_getStepNumber(_currentStep)} of 3',
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
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _getStepNumber(_currentStep) / 6,
                        minHeight: 2,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00B252),
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

        // // Underbanking Modal
        // bottomSheet: _showUnderbanking ? _buildUnderbankingModal() : null,
      ),
    );
  }

  int _getStepNumber(AccountStep step) {
    return AccountStep.values.indexOf(step) + 1;
  }

  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Email is optional
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove any spaces or special characters
    String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it starts with 0 and has 11 digits
    if (cleanPhone.length == 11 && cleanPhone.startsWith('0')) {
      // Check if second digit is 7, 8, or 9 (valid Nigerian mobile prefixes)
      if (['7', '8', '9'].contains(cleanPhone[1])) {
        return null;
      }
    }
    // Check if it starts with 234 and has 13 digits total
    else if (cleanPhone.length == 13 && cleanPhone.startsWith('234')) {
      if (['7', '8', '9'].contains(cleanPhone[3])) {
        return null;
      }
    }

    return 'Please enter a valid Nigerian phone number (e.g., 08012345678)';
  }

  String? _validateBVN(String? value) {
    if (value == null || value.trim().isEmpty) return null; // BVN is optional
    String cleanBVN = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanBVN.length != 11) {
      return 'BVN must be exactly 11 digits';
    }
    return null;
  }

  String? _validateNIN(String? value) {
    if (value == null || value.trim().isEmpty) return null; // NIN is optional
    String cleanNIN = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNIN.length != 11) {
      return 'NIN must be exactly 11 digits';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    // Check for valid name characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _password) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date of birth is required';
    }

    try {
      // Parse the date in DD-MM-YYYY format
      List<String> parts = value.split('-');
      if (parts.length != 3) {
        return 'Please select a valid date';
      }

      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      DateTime birthDate = DateTime(year, month, day);
      DateTime now = DateTime.now();
      DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

      if (birthDate.isAfter(eighteenYearsAgo)) {
        return 'You must be at least 18 years old';
      }

      if (birthDate.isAfter(now)) {
        return 'Date of birth cannot be in the future';
      }

      return null;
    } catch (e) {
      return 'Please select a valid date';
    }
  }

  void _handleOtpSubmit() async {
    // Validate OTP
    if (_otp.any((digit) => digit.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final session = getSessionId();
    final otpParams = OtpParams(
      method: "validateOtp",
      otpCode: _otp.join(),
      requestType: REQUEST_TYPE,
      sessionId: session,
    );

    ref.read(verifyOtpProvider(otpParams));
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });
    final session = getSessionId();
    final otpParams = OtpParams(
      method: "resendOtp",
      requestType: REQUEST_TYPE,
      sessionId: session,
    );
    ref.read(resendOtpProvider(otpParams));
    _startResendCountdown();
  }

  // API Integration
  Future<void> _handlePersonalInfoSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      // Scroll to first error
      return;
    }

    // Check terms acceptance
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if neither BVN nor NIN is provided
    if (_personalInfo.bvn.trim().isEmpty && _personalInfo.nin.trim().isEmpty) {
      //    setState(() {
      //   _showUnderbanking = true;
      // });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A Bvn OR Nin is required for tier1'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that at least address or coordinates are available
    if (_personalInfo.residentialAddress.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your residential address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Start loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare API parameters
      final getSessionId = await ref.read(authenticateProvider.future);
      if (getSessionId == null) {
        setState(() {
          _isLoading = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AN_ERROR_OCCURED_WHILE_PROCESSING_YOUR_REQUEST_PLEASE_TRY_AGAIN),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      final params = PersonalSignupParams(
        sessionId: getSessionId?.model?.data?.sessionId,
        requestType: "testDeployment",
        method: "signupPersonal",
        acceptOurTerms: "1",
        // addressLine2: "Nil",
        // customerMiddleName: "Nil",
        customerTitle: _personalInfo.gender.toLowerCase() == 'female' ? "mrs" : "mr",
        customerFirstName: _personalInfo.firstname.trim(),
        customerSurnameName: _personalInfo.lastname.trim(),
        emailAddress: _personalInfo.emailAddress.trim().isEmpty ? "" : _personalInfo.emailAddress.trim(),
        dateOfBirth: _personalInfo.dateOfBirth,
        gender: _personalInfo.gender.toLowerCase(),
        mobilePhoneNo: _personalInfo.phoneNumber.trim(),
        password: _password,
        confirmPassword: _confirmPassword,
        nationality: "Nigerian",
        residentState: _personalInfo.state,
        residentCity: selectedLga?.name ?? _personalInfo.lga,
        residentLga: _personalInfo.lga,

        addressLine1: _personalInfo.residentialAddress.trim(),
        accountType: "current",
        customerBVN: _personalInfo.bvn.trim().isEmpty ? "" : _personalInfo.bvn.trim(),
        customerNIN: _personalInfo.nin.trim().isEmpty ? "" : _personalInfo.nin.trim(),
        latitude: selectedCoordinate?.lat ?? _personalInfo.currentLat?.toString(),
        longitude: selectedCoordinate?.lng ?? _personalInfo.currentLng?.toString(),
      );

      log('Submitting signup with params: ${params.toJson()}');

      // Make API call using the provider
      await ref.read(signupProvider(params).future);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      log('Signup error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleUnderbanking() {
    setState(() {
      _showUnderbanking = false;
      _currentStep = AccountStep.otpVerification;
    });
  }

  bool _creatingPin = false;
  void _handlePinSet() {
    // Validate PIN
    if (_pin.any((digit) => digit.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a complete 4-digit PIN')),
      );
      return;
    }
    if (mounted) {
      setState(() {
        _creatingPin = true;
      });
    }
    final session = getSessionId();
    final createPin = CreatePinParams(
      requestType: REQUEST_TYPE,
      method: "createSoftToken",
      sentConfirmPIN: _pin.join(),
      sentPIN: _pin.join(),
      sessionId: session,
    );
    ref.read(createPinProvider(createPin));
  }

  // Location related methods (keeping your existing implementation)
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
          }
        } catch (e) {
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
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get your location")),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Widget _buildPersonalInfoStep() {
    final locations = getCountryLocation();
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // First Name Field
            const Text(
              'First Name *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _firstNameController,
              validator: (value) => _validateName(value, 'First name'),
              onChanged: (value) {
                setState(() {
                  _personalInfo.firstname = value.trim();
                });
              },
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your first name',
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Last Name Field
            const Text(
              'Last Name *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _lastNameController,
              validator: (value) => _validateName(value, 'Last name'),
              onChanged: (value) {
                setState(() {
                  _personalInfo.lastname = value.trim();
                });
              },
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your last name',
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
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
                        controller: _birthdayController,
                        validator: _validateDateOfBirth,
                        decoration: InputDecoration(
                          hintText: 'DD-MM-YYYY',
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now().subtract(const Duration(days: 6570)), // Must be 18+
                          );
                          if (date != null) {
                            final dateString = date.toString().split(' ')[0];
                            final parts = dateString.split('-');
                            final formattedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
                            setState(() {
                              _personalInfo.dateOfBirth = formattedDate;
                              _birthdayController.text = formattedDate;
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
                        validator: (value) => value == null ? 'Please select your gender' : null,
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
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
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
              controller: _phoneController,
              validator: _validatePhone,
              onChanged: (value) {
                setState(() {
                  _personalInfo.phoneNumber = addLeadingZero(value);
                });
              },
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter your phone number (e.g., 08012345678)',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.6),
                  fontSize: 14,
                ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
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
              controller: _emailController,
              validator: _validateEmail,
              onChanged: (value) {
                setState(() {
                  _personalInfo.emailAddress = value.trim();
                });
              },
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'you@example.com (optional)',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.6),
                  fontSize: 14,
                ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Password Fields
            const Text(
              'Password *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              validator: _validatePassword,
              onChanged: (value) {
                setState(() {
                  _password = value;
                });
              },
              obscureText: !_showPassword,
              decoration: InputDecoration(
                hintText: 'Create a strong password',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.6),
                  fontSize: 14,
                ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Must contain uppercase, lowercase, number, and be 8+ characters',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Confirm Password *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              validator: _validateConfirmPassword,
              onChanged: (value) {
                setState(() {
                  _confirmPassword = value;
                });
              },
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                hintText: 'Confirm your password',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.6),
                  fontSize: 14,
                ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
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
              validator: (value) => _validateRequired(value, 'Residential address'),
              googleAPIKey: GOOGLE_API_KEY,
              debounceTime: 600,
              onSuggestionClicked: (prediction) {
                _addressController.text = prediction.description ?? "";
                _addressController.selection = TextSelection.fromPosition(
                  TextPosition(offset: prediction.description?.length ?? 0),
                );
                setState(() {
                  _personalInfo.residentialAddress = prediction.description ?? "";
                });
              },
              countries: const ["ng"],
              onChanged: (e) {
                setState(() {
                  _personalInfo.residentialAddress = e;
                });
                if (e.trim().isEmpty) {
                  setState(() {
                    selectedState = null;
                    selectedLga = null;
                  });
                }
              },
              onPlaceDetailsWithCoordinatesReceived: (prediction) async {
                setState(() {
                  selectedCoordinate = Prediction(
                    description: prediction.description,
                    lat: prediction.lat,
                    lng: prediction.lng,
                    placeId: prediction.placeId,
                  );
                });
                if (prediction.placeId != null) {
                  final locationDetails = await ref.read(locationDetailsProvider(prediction.placeId ?? "").future);
                  if (locationDetails != null) {
                    final locations = getCountryLocation();
                    final service = ref.read(locationDetailsServiceProvider);
                    final matchingState = service.findMatchingState(locationDetails.state, locations);

                    if (matchingState != null) {
                      setState(() {
                        selectedState = matchingState;
                        _personalInfo.state = matchingState.state?.name ?? '';
                        locals = matchingState.state?.locals;

                        if (locationDetails.localGovernment != null && locals != null) {
                          selectedLga = service.findMatchingLGA(locationDetails.localGovernment!, locals!);
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
                }
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
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
              validator: (value) => value == null ? 'Please select your state' : null,
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                  _personalInfo.state = value?.state?.name ?? '';
                  locals = value?.state?.locals;
                  selectedLga = null;
                  _personalInfo.lga = '';
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
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
              validator: (value) => value == null ? 'Please select your LGA' : null,
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
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
                          '• Provide either BVN OR NIN (only one required)\n• Skip both for Underbanking Profile (₦50,000 daily limit)',
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
              'BVN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bvnController,
              validator: _validateBVN,
              onChanged: (value) {
                setState(() {
                  _personalInfo.bvn = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (value.isNotEmpty) {
                    _ninController.clear();
                    _personalInfo.nin = '';
                  }
                });
              },
              keyboardType: TextInputType.number,
              maxLength: 11,
              decoration: InputDecoration(
                hintText: 'Enter 11-digit BVN',
                hintStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.6),
                  fontSize: 14,
                ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
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
              'NIN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ninController,
              validator: _validateNIN,
              onChanged: (value) {
                setState(() {
                  _personalInfo.nin = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (value.isNotEmpty) {
                    _bvnController.clear();
                    _personalInfo.bvn = '';
                  }
                });
              },
              keyboardType: TextInputType.number,
              maxLength: 11,
              decoration: InputDecoration(
                hintText: 'Enter 11-digit NIN',
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                counterText: '',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Providing BVN or NIN enables Tier 1 with higher limits + mandatory liveness check',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),

            // Terms and Conditions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF00B252),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _acceptTerms = !_acceptTerms;
                      });
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                        ),
                        children: [
                          TextSpan(text: 'I accept the '),
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              color: Color(0xFF00B252),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF00B252),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePersonalInfoSubmit,
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
      ),
    );
  }

// Add these variables to your state class
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

// Add this method to your state class
  void _startResendCountdown() {
    _resendCountdown = 60; // 60 seconds countdown
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

// Add this method to handle resend OTP

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
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
          const Text(
            'Verify Your Phone & Email',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'Enter 6-digit code from SMS/Email',
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
          const SizedBox(height: 24),

          // Resend OTP Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Didn't receive code? ",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              TextButton(
                onPressed: (_resendCountdown > 0 || _isResending) ? null : _handleResendOtp,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B252)),
                        ),
                      )
                    : Text(
                        _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Resend',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _resendCountdown > 0 ? const Color(0xFF6B7280) : const Color(0xFF00B252),
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 24),

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

          // Additional help text
          const SizedBox(height: 16),
          Text(
            'Check your SMS and email for the verification code',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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

  Widget _buildPinStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
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
            'Create Transaction PIN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your 4-digit PIN to secure your transactions',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

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
              onPressed: _pin.any((digit) => digit.isEmpty) ? null : _handlePinSet,
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
              child: _creatingPin
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
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

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case AccountStep.personalInfo:
        return _buildPersonalInfoStep();
      case AccountStep.otpVerification:
        return _buildOtpStep();

      case AccountStep.setPin:
        return _buildPinStep();
    }
  }

  // Widget _buildUnderbankingModal() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: const BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Container(
  //           width: 48,
  //           height: 48,
  //           decoration: const BoxDecoration(
  //             color: Color(0xFFDCFCE7),
  //             shape: BoxShape.circle,
  //           ),
  //           child: const Icon(
  //             Icons.shield_outlined,
  //             color: Color(0xFF059669),
  //             size: 24,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         const Text(
  //           'Underbanking Profile',
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w600,
  //             color: Color(0xFF111827),
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 8),
  //         const Text(
  //           'You are opening an Underbanking Profile linked to a Cooperative Pool with daily limits of ₦50,000 until you upgrade with BVN/NIN + mandatory liveness verification.',
  //           style: TextStyle(
  //             fontSize: 14,
  //             color: Color(0xFF6B7280),
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         const SizedBox(height: 20),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: ElevatedButton(
  //                 onPressed: () {
  //                   setState(() {
  //                     _showUnderbanking = false;
  //                   });
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: const Color(0xFFF3F4F6),
  //                   foregroundColor: const Color(0xFF374151),
  //                   elevation: 0,
  //                   padding: const EdgeInsets.symmetric(vertical: 12),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //                 child: const Text(
  //                   'Go Back',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             Expanded(
  //               child: ElevatedButton(
  //                 onPressed: _handleUnderbanking,
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: const Color(0xFF00B252),
  //                   foregroundColor: Colors.white,
  //                   elevation: 0,
  //                   padding: const EdgeInsets.symmetric(vertical: 12),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //                 child: const Text(
  //                   'Continue',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
