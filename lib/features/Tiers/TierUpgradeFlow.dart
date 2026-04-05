// // screens/tier_upgrade_flow_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';

// import 'package:rimapay/features/Tiers/AccountTierScreen.dart';

// enum UpgradeStep { info, form, verification, success }

// class FormData {
//   String bvn;
//   String nin;
//   String otp;
//   String documentType;
//   String address;
//   String city;
//   String state;
//   String lga;
//   File? governmentDocument;
//   File? addressDocument;

//   FormData({
//     this.bvn = '',
//     this.nin = '',
//     this.otp = '',
//     this.documentType = '',
//     this.address = '',
//     this.city = '',
//     this.state = '',
//     this.lga = '',
//     this.governmentDocument,
//     this.addressDocument,
//   });

//   FormData copyWith({
//     String? bvn,
//     String? nin,
//     String? otp,
//     String? documentType,
//     String? address,
//     String? city,
//     String? state,
//     String? lga,
//     File? governmentDocument,
//     File? addressDocument,
//   }) {
//     return FormData(
//       bvn: bvn ?? this.bvn,
//       nin: nin ?? this.nin,
//       otp: otp ?? this.otp,
//       documentType: documentType ?? this.documentType,
//       address: address ?? this.address,
//       city: city ?? this.city,
//       state: state ?? this.state,
//       lga: lga ?? this.lga,
//       governmentDocument: governmentDocument ?? this.governmentDocument,
//       addressDocument: addressDocument ?? this.addressDocument,
//     );
//   }
// }
// class TierState {
//   final TierInfo currentTier;

//   const TierState(this.currentTier);
// }

// /// Notifier
// class TierNotifier extends StateNotifier<TierState> {
//   TierNotifier()
//       : super(TierState(_tier1)); // Default to tier1 at start

//   // Predefined TierInfo objects (you can expand/modify as needed)
//   static final TierInfo _tier1 = TierInfo(
//     name: "Basic Tier",
//     balanceLimit: "₦50,000",
//     transactionLimit: "₦10,000/day",
//     requirements: ["BVN not required", "Basic details only"],
//     benefits: ["Send & Receive Money", "Basic Wallet Access"],
//     level: TierLevel.tier1,
//   );

//   static final TierInfo _tier2 = TierInfo(
//     name: "Premium Tier",
//     balanceLimit: "₦500,000",
//     transactionLimit: "₦100,000/day",
//     requirements: ["BVN required", "Valid ID"],
//     benefits: ["Higher limits", "Access to loans"],
//     level: TierLevel.tier2,
//   );

//   static final TierInfo _tier3 = TierInfo(
//     name: "Elite Tier",
//     balanceLimit: "Unlimited",
//     transactionLimit: "₦1,000,000/day",
//     requirements: ["Full KYC", "Proof of Address"],
//     benefits: ["Unlimited transactions", "Full banking access"],
//     level: TierLevel.tier3,
//   );

//   void upgradeToTier(TierLevel newTier) {
//     switch (newTier) {
//       case TierLevel.tier1:
//         state = TierState(_tier1);
//         break;
//       case TierLevel.tier2:
//         state = TierState(_tier2);
//         break;
//       case TierLevel.tier3:
//         state = TierState(_tier3);
//         break;
//     }
//   }
// }

// /// Provider
// final userProvider = StateNotifierProvider<TierNotifier, TierState>((ref) {
//   return TierNotifier();
// });
// // Simple Nigerian States data structure
// class State {
//   final String id;
//   final String name;
//   final List<LGA> lgas;

//   const State({required this.id, required this.name, required this.lgas});
// }

// class LGA {
//   final String id;
//   final String name;

//   const LGA({required this.id, required this.name});
// }

// // Sample Nigerian States and LGAs
// final List<State> NIGERIAN_STATES = [
//   State(
//     id: 'lagos',
//     name: 'Lagos',
//     lgas: [
//       LGA(id: 'ikeja', name: 'Ikeja'),
//       LGA(id: 'surulere', name: 'Surulere'),
//       LGA(id: 'yaba', name: 'Yaba'),
//     ],
//   ),
//   State(
//     id: 'abuja',
//     name: 'Federal Capital Territory',
//     lgas: [
//       LGA(id: 'gwagwalada', name: 'Gwagwalada'),
//       LGA(id: 'kubwa', name: 'Kubwa'),
//       LGA(id: 'wuse', name: 'Wuse'),
//     ],
//   ),
//   State(
//     id: 'kano',
//     name: 'Kano',
//     lgas: [
//       LGA(id: 'fagge', name: 'Fagge'),
//       LGA(id: 'dala', name: 'Dala'),
//       LGA(id: 'gwale', name: 'Gwale'),
//     ],
//   ),
// ];

// State? getStateById(String id) {
//   try {
//     return NIGERIAN_STATES.firstWhere((state) => state.id == id);
//   } catch (e) {
//     return null;
//   }
// }

// List<LGA> getLgasForState(String stateId) {
//   final state = getStateById(stateId);
//   return state?.lgas ?? [];
// }

// class TierUpgradeFlowScreen extends ConsumerStatefulWidget {
//   final TierInfo targetTier;

//   const TierUpgradeFlowScreen({
//     super.key,
//     required this.targetTier,
//   });

//   @override
//   ConsumerState<TierUpgradeFlowScreen> createState() => _TierUpgradeFlowScreenState();
// }

// class _TierUpgradeFlowScreenState extends ConsumerState<TierUpgradeFlowScreen> {
//   UpgradeStep currentStep = UpgradeStep.info;
//   FormData formData = FormData();
//   bool isLoading = false;
//   final ImagePicker _imagePicker = ImagePicker();

//   TierInfo get tierInfo => widget.targetTier;

//   String get stepTitle {
//     switch (currentStep) {
//       case UpgradeStep.info:
//         return 'Upgrade to ${tierInfo.name}';
//       case UpgradeStep.form:
//         return 'Verification Details';
//       case UpgradeStep.verification:
//         return 'Complete Verification';
//       case UpgradeStep.success:
//         return 'Upgrade Successful!';
//     }
//   }

//   void handleNext() {
//     if (currentStep == UpgradeStep.info) {
//       setState(() {
//         currentStep = UpgradeStep.form;
//       });
//     } else if (currentStep == UpgradeStep.form) {
//       setState(() {
//         currentStep = UpgradeStep.verification;
//       });
//     } else if (currentStep == UpgradeStep.verification) {
//       handleUpgrade();
//     }
//   }

//   void handleUpgrade() async {
//     setState(() {
//       isLoading = true;
//     });

//     // Simulate upgrade process
//     await Future.delayed(const Duration(seconds: 2));

//     ref.read(userProvider.notifier).upgradeToTier(widget.targetTier.level);
//     setState(() {
//       currentStep = UpgradeStep.success;
//       isLoading = false;
//     });

//     // Auto-navigate back after success
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         Navigator.pop(context);
//       }
//     });
//   }

//   Future<void> _pickImage({required bool isGovernmentDoc}) async {
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.camera,
//         preferredCameraDevice: CameraDevice.rear,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         setState(() {
//           if (isGovernmentDoc) {
//             formData = formData.copyWith(governmentDocument: File(image.path));
//           } else {
//             formData = formData.copyWith(addressDocument: File(image.path));
//           }
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error picking image: $e')),
//       );
//     }
//   }

//   Future<void> _pickFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
//       );

//       if (result != null && result.files.single.path != null) {
//         setState(() {
//           formData = formData.copyWith(addressDocument: File(result.files.single.path!));
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error picking file: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFFFFFFFF),
//               Color(0xFFF0FDF4),
//               Color(0xFFF2F7F3),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Header
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     if (currentStep != UpgradeStep.success)
//                       Container(
//                         width: 36,
//                         height: 36,
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.8),
//                           borderRadius: BorderRadius.circular(18),
//                           border: Border.all(color: Colors.white.withOpacity(0.2)),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 4,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: IconButton(
//                           onPressed: () {
//                             if (currentStep == UpgradeStep.info) {
//                               Navigator.pop(context);
//                             } else {
//                               setState(() {
//                                 currentStep = UpgradeStep.info;
//                               });
//                             }
//                           },
//                           icon: const Icon(Icons.arrow_back, size: 16),
//                           color: const Color(0xFF6B7280),
//                         ),
//                       ),
//                     if (currentStep != UpgradeStep.success) const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             stepTitle,
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF111827),
//                             ),
//                           ),
//                           if (currentStep != UpgradeStep.success)
//                             Text(
//                               'Step ${currentStep.index + 1} of 3',
//                               style: const TextStyle(
//                                 fontSize: 12,
//                                 color: Color(0xFF6B7280),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Content
//               Expanded(
//                 child: _buildStepContent(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStepContent() {
//     switch (currentStep) {
//       case UpgradeStep.info:
//         return _buildInfoStep();
//       case UpgradeStep.form:
//         return _buildFormStep();
//       case UpgradeStep.verification:
//         return _buildVerificationStep();
//       case UpgradeStep.success:
//         return _buildSuccessStep();
//     }
//   }

//   Widget _buildInfoStep() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Benefits Overview
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Color(0x1A166C46),
//                   Color(0x1A0E5C37),
//                 ],
//               ),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0x33166C46)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Unlock ${tierInfo.name} Benefits',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF111827),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 _buildBenefitItem(
//                   'Higher Limits',
//                   'Up to ${tierInfo.balanceLimit} balance, ${tierInfo.transactionLimit} per transaction',
//                 ),
//                 ...tierInfo.benefits.take(2).map((benefit) => 
//                   _buildBenefitItem('', benefit),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Requirements
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFFE5E7EB)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'What You\'ll Need',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF111827),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 ...tierInfo.requirements.take(3).map((req) => Padding(
//                   padding: const EdgeInsets.only(bottom: 8),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.description,
//                         color: Color(0xFF166C46),
//                         size: 16,
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           req,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Color(0xFF374151),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )),
//                 if (widget.targetTier == TierLevel.tier2)
//                   Container(
//                     margin: const EdgeInsets.only(top: 12),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFEFF6FF),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFBFDBFE)),
//                     ),
//                     child: const Text(
//                       'Note: Additional verification required since you\'ve completed liveness verification during onboarding.',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Color(0xFF1D4ED8),
//                       ),
//                     ),
//                   ),
//                 if (widget.targetTier == TierLevel.tier3)
//                   Container(
//                     margin: const EdgeInsets.only(top: 12),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFAF5FF),
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: const Color(0xFFE9D5FF)),
//                     ),
//                     child: const Text(
//                       'Note: Document verification may take 1-2 days.',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Color(0xFF7C3AED),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 24),

//           ElevatedButton(
//             onPressed: handleNext,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF166C46),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 2,
//             ),
//             child: const Text(
//               'Start Upgrade Process',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),

//           const SizedBox(height: 24),
//         ],
//       ),
//     ).animate().fadeIn().slideY(begin: 0.2);
//   }

//   Widget _buildBenefitItem(String title, String description) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 24,
//             height: 24,
//             decoration: const BoxDecoration(
//               color: Color(0xFF166C46),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.check,
//               color: Colors.white,
//               size: 12,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (title.isNotEmpty)
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: Color(0xFF111827),
//                     ),
//                   ),
//                 Text(
//                   description,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: title.isNotEmpty ? const Color(0xFF6B7280) : const Color(0xFF374151),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFormStep() {
//     final user = ref.watch(userProvider);
    
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Requirements Info
//           if (widget.targetTier == TierLevel.tier1)
//             _buildInfoCard(
//               color: Colors.blue,
//               title: 'Tier 1 Requirements',
//               description: '• Provide either BVN OR NIN (only one required)\n• Complete OTP verification',
//             ),

//           if (widget.targetTier == TierLevel.tier2)
//             _buildInfoCard(
//               color: Colors.orange,
//               title: 'Tier 2 Requirements',
//               description: '• Provide the alternative verification method (${!user.bvnVerified ? 'BVN' : 'NIN'}) since you already provided ${user.bvnVerified ? 'BVN' : 'NIN'} for Tier 1\n• Complete additional OTP verification',
//             ),

//           const SizedBox(height: 16),

//           // BVN Input
//           if (_shouldShowBvnInput())
//             _buildTextInput(
//               label: 'BVN ${_getBvnLabel()}',
//               value: formData.bvn,
//               onChanged: (value) => setState(() {
//                 formData = formData.copyWith(bvn: value);
//               }),
//               placeholder: 'Enter your 11-digit BVN',
//               maxLength: 11,
//               icon: Icons.person,
//             ),

//           // NIN Input
//           if (_shouldShowNinInput())
//             _buildTextInput(
//               label: 'NIN ${_getNinLabel()}',
//               value: formData.nin,
//               onChanged: (value) => setState(() {
//                 formData = formData.copyWith(nin: value);
//               }),
//               placeholder: 'Enter your 11-digit NIN',
//               maxLength: 11,
//               icon: Icons.person,
//             ),

//           // Document Upload for Tier 3
//           if (widget.targetTier == TierLevel.tier3) ...[
//             _buildInfoCard(
//               color: Colors.purple,
//               title: 'Tier 3 Requirements',
//               description: '• Upload a clear photo of your government-issued ID\n• Provide address verification document',
//             ),

//             const SizedBox(height: 16),

//             // Government ID
//             _buildDropdown(
//               label: 'Government ID Document',
//               value: formData.documentType,
//               onChanged: (value) => setState(() {
//                 formData = formData.copyWith(documentType: value ?? '');
//               }),
//               items: const [
//                 DropdownMenuItem(value: '', child: Text('Select ID type')),
//                 DropdownMenuItem(value: 'drivers-license', child: Text('Driver\'s License')),
//                 DropdownMenuItem(value: 'passport', child: Text('International Passport')),
//                 DropdownMenuItem(value: 'nin-slip', child: Text('NIN Slip')),
//                 DropdownMenuItem(value: 'voters-card', child: Text('Voter\'s Card')),
//               ],
//             ),

//             const SizedBox(height: 8),

//             _buildFileUpload(
//               label: 'Upload government ID photo',
//               file: formData.governmentDocument,
//               onTap: () => _pickImage(isGovernmentDoc: true),
//             ),

//             const SizedBox(height: 16),

//             // Address Document
//             Text(
//               'Address Verification Document',
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: Color(0xFF374151),
//               ),
//             ),
//             const SizedBox(height: 8),

//             _buildFileUpload(
//               label: 'Upload address proof',
//               description: 'Utility bill, bank statement, etc.',
//               file: formData.addressDocument,
//               onTap: _pickFile,
//             ),

//             const SizedBox(height: 16),

//             _buildTextInput(
//               label: 'Full Address',
//               value: formData.address,
//               onChanged: (value) => setState(() {
//                 formData = formData.copyWith(address: value);
//               }),
//               placeholder: 'Enter your full address',
//               maxLines: 2,
//               icon: Icons.location_on,
//             ),

//             const SizedBox(height: 8),

//             Row(
//               children: [
//                 Expanded(
//                   child: _buildTextInput(
//                     label: 'City',
//                     value: formData.city,
//                     onChanged: (value) => setState(() {
//                       formData = formData.copyWith(city: value);
//                     }),
//                     placeholder: 'City',
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildDropdown(
//                     label: 'State',
//                     value: formData.state,
//                     onChanged: (value) => setState(() {
//                       formData = formData.copyWith(state: value ?? '', lga: '');
//                     }),
//                     items: [
//                       const DropdownMenuItem(value: '', child: Text('Select State')),
//                       ...NIGERIAN_STATES.map((state) => 
//                         DropdownMenuItem(value: state.id, child: Text(state.name)),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 8),

//             Row(
//               children: [
//                 Expanded(
//                   child: _buildDropdown(
//                     label: 'LGA',
//                     value: formData.lga,
//                     onChanged: (value) => setState(() {
//                       formData = formData.copyWith(lga: value ?? '');
//                     }),
//                     items: [
//                       DropdownMenuItem(
//                         value: '',
//                         child: Text(formData.state.isEmpty ? 'Select State First' : 'Select LGA'),
//                       ),
//                       if (formData.state.isNotEmpty)
//                         ...getLgasForState(formData.state).map((lga) => 
//                           DropdownMenuItem(value: lga.id, child: Text(lga.name)),
//                         ),
//                     ],
//                   ),
//                 ),
//                 const Expanded(child: SizedBox()), // Empty space to match the grid
//               ],
//             ),
//           ],

//           const SizedBox(height: 24),

//           ElevatedButton(
//             onPressed: _canContinue() ? handleNext : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF166C46),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 2,
//             ),
//             child: const Text(
//               'Continue to Verification',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),

//           const SizedBox(height: 24),
//         ],
//       ),
//     ).animate().fadeIn().slideY(begin: 0.2);
//   }

//   Widget _buildVerificationStep() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: const BoxDecoration(
//               color: Color(0xFF166C46),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.shield,
//               color: Colors.white,
//               size: 32,
//             ),
//           ),

//           const SizedBox(height: 24),

//           Text(
//             widget.targetTier.level == TierLevel.tier1 ? 'BVN/NIN Verification' : 'Additional Verification',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF111827),
//             ),
//           ),

//           const SizedBox(height: 8),

//           Text(
//             widget.targetTier.level == TierLevel.tier1 
//                 ? 'We\'ll verify your BVN or NIN details'
//                 : 'Complete your account verification process',
//             style: const TextStyle(
//               fontSize: 14,
//               color: Color(0xFF6B7280),
//             ),
//             textAlign: TextAlign.center,
//           ),

//           const SizedBox(height: 24),

//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFFE5E7EB)),
//             ),
//             child: Column(
//               children: [
//                 _buildVerificationItem('${widget.targetTier.level == TierLevel.tier1 
//                     ? (formData.bvn.isNotEmpty ? 'BVN verification' : 'NIN verification')
//                     : (formData.bvn.isNotEmpty ? 'BVN verification' : 'NIN verification')
//                   } in progress'),
//                 _buildVerificationItem('OTP sent to registered phone'),
//                 _buildVerificationItem('Secure verification process'),
//               ],
//             ),
//           ),

//           const SizedBox(height: 24),

//           SizedBox(
//             width: 200,
//             child: _buildTextInput(
//               label: 'Enter OTP sent to your phone',
//               value: formData.otp,
//               onChanged: (value) => setState(() {
//                 formData = formData.copyWith(otp: value);
//               }),
//               placeholder: '000000',
//               maxLength: 6,
//               textAlign: TextAlign.center,
//               icon: Icons.phone,
//             ),
//           ),

//           const SizedBox(height: 24),

//           SizedBox(
//             width: 200,
//             child: ElevatedButton(
//               onPressed: (isLoading || formData.otp.length != 6) ? null : handleNext,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF166C46),
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 2,
//               ),
//               child: isLoading
//                   ? const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 16,
//                           height: 16,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         ),
//                         SizedBox(width: 8),
//                         Text('Verifying...'),
//                       ],
//                     )
//                   : const Text(
//                       'Complete Verification',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     ).animate().fadeIn().slideY(begin: 0.2);
//   }

//   Widget _buildSuccessStep() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Color(0xFF166C46),
//                   Color(0xFF0E5C37),
//                 ],
//               ),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.check,
//               color: Colors.white,
//               size: 40,
//             ),
//           ).animate().scale(delay: 200.ms),

//           const SizedBox(height: 24),

//           const Text(
//             'Congratulations! 🎉',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF111827),
//             ),
//           ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

//           const SizedBox(height: 12),

//           Text(
//             'You are now ${tierInfo.name}',
//             style: const TextStyle(
//               fontSize: 14,
//               color: Color(0xFF6B7280),
//             ),
//           ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),

//           const SizedBox(height: 24),

//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFFE5E7EB)),
//             ),
//             child: Column(
//               children: [
//                 _buildSuccessItem('New Balance Limit:', tierInfo.balanceLimit),
//                 _buildSuccessItem('Transaction Limit:', tierInfo.transactionLimit),
//                 _buildSuccessItem('Account Number:', '2138547690'),
//               ],
//             ),
//           ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoCard({
//     required Color color,
//     required String title,
//     required String description,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             Icons.info_outline,
//             color: color,
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: color,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: color.withOpacity(0.8),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextInput({
//     required String label,
//     required String value,
//     required ValueChanged<String> onChanged,
//     required String placeholder,
//     int maxLength = 100,
//     int maxLines = 1,
//     IconData? icon,
//     TextAlign textAlign = TextAlign.start,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF374151),
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           initialValue: value,
//           onChanged: onChanged,
//           maxLength: maxLength,
//           maxLines: maxLines,
//           textAlign: textAlign,
//           decoration: InputDecoration(
//             hintText: placeholder,
//             prefixIcon: icon != null ? Icon(icon, size: 16, color: const Color(0xFF9CA3AF)) : null,
//             counterText: '',
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Color(0xFF166C46), width: 2),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//           ),
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   Widget _buildDropdown({
//     required String label,
//     required String value,
//     required ValueChanged<String?> onChanged,
//     required List<DropdownMenuItem<String>> items,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: Color(0xFF374151),
//           ),
//         ),
//         const SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           value: value.isEmpty ? null : value,
//           onChanged: onChanged,
//           items: items,
//           decoration: InputDecoration(
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Color(0xFF166C46), width: 2),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//           ),
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   Widget _buildFileUpload({
//     required String label,
//     String? description,
//     File? file,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: const Color(0xFFD1D5DB),
//             style: BorderStyle.solid,
//             width: 2,
//           ),
//           borderRadius: BorderRadius.circular(8),
//           color: Colors.white,
//         ),
//         child: Column(
//           children: [
//             const Icon(
//               Icons.upload_file,
//               color: Color(0xFF9CA3AF),
//               size: 24,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               file?.path.split('/').last ?? label,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Color(0xFF6B7280),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             if (description != null && file == null)
//               Text(
//                 description,
//                 style: const TextStyle(
//                   fontSize: 10,
//                   color: Color(0xFF9CA3AF),
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVerificationItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.check,
//             color: Color(0xFF166C46),
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Color(0xFF374151),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSuccessItem(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 12,
//               color: Color(0xFF6B7280),
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: label == 'Account Number:' ? const Color(0xFF111827) : const Color(0xFF166C46),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   bool _shouldShowBvnInput() {
//     final user = ref.watch(userProvider);
//     if (widget.targetTier == TierLevel.tier1) {
//       return !user.bvnVerified && !user.ninVerified;
//     } else if (widget.targetTier == TierLevel.tier2) {
//       return !user.bvnVerified;
//     }
//     return false;
//   }

//   bool _shouldShowNinInput() {
//     final user = ref.watch(userProvider);
//     if (widget.targetTier == TierLevel.tier1) {
//       return !user.bvnVerified && !user.ninVerified;
//     } else if (widget.targetTier == TierLevel.tier2) {
//       return !user.ninVerified;
//     }
//     return false;
//   }

//   String _getBvnLabel() {
//     final user = ref.watch(userProvider);
//     if (widget.targetTier == TierLevel.tier1) {
//       return '(Choose BVN or NIN below)';
//     } else if (widget.targetTier == TierLevel.tier2) {
//       return '(Required - Alternative verification)';
//     }
//     return '(Required)';
//   }

//   String _getNinLabel() {
//     final user = ref.watch(userProvider);
//     if (widget.targetTier == TierLevel.tier1) {
//       return '(Choose BVN or NIN above)';
//     } else if (widget.targetTier == TierLevel.tier2) {
//       return '(Required - Alternative verification)';
//     }
//     return '(Required)';
//   }

//   bool _canContinue() {
//     final user = ref.watch(userProvider);
    
//     if (widget.targetTier == TierLevel.tier1) {
//       return formData.bvn.isNotEmpty || formData.nin.isNotEmpty;
//     } else if (widget.targetTier == TierLevel.tier2) {
//       return (!user.bvnVerified && formData.bvn.isNotEmpty) || 
//              (!user.ninVerified && formData.nin.isNotEmpty);
//     } else if (widget.targetTier == TierLevel.tier3) {
//       return formData.documentType.isNotEmpty &&
//              formData.governmentDocument != null &&
//              formData.addressDocument != null &&
//              formData.address.isNotEmpty;
//     }
//     return false;
//   }
// }
