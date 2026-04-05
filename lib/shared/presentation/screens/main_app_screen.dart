import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/auth_provider.dart';

// class CardManagementScreen extends StatefulWidget {
//   const CardManagementScreen({super.key});

//   @override
//   State<CardManagementScreen> createState() => _CardManagementScreenState();
// }

// class _CardManagementScreenState extends State<CardManagementScreen> with TickerProviderStateMixin {
//   bool _showDetails = false;
//   bool _cardFrozen = false;
//   bool _showBiometricModal = false;
//   late AnimationController _cardAnimationController;
//   late AnimationController _pulseController;
//   late Animation<double> _cardRotation;
//   late Animation<double> _pulseAnimation;

//   final CardData _cardData = CardData(
//     cardNumber: '5399 **** **** 1234',
//     fullNumber: '5399 4567 8901 1234',
//     holderName: 'ADEBAYO JOHNSON',
//     expiryDate: '12/28',
//     cvv: '123',
//     cardType: 'Mastercard',
//     balance: '₦125,430.50',
//   );

//   final List<TransactionData> _recentTransactions = [
//     TransactionData(
//       id: '1',
//       merchant: 'Shoprite',
//       amount: '₦12,450',
//       date: 'Today',
//       type: TransactionType.pos,
//       icon: '🛒',
//       suspicious: false,
//     ),
//     TransactionData(
//       id: '2',
//       merchant: 'Netflix',
//       amount: '₦5,500',
//       date: 'Yesterday',
//       type: TransactionType.online,
//       icon: '🎬',
//       suspicious: false,
//     ),
//     TransactionData(
//       id: '3',
//       merchant: 'ATM Withdrawal',
//       amount: '₦20,000',
//       date: '2 days ago',
//       type: TransactionType.atm,
//       icon: '🏧',
//       suspicious: false,
//     ),
//     TransactionData(
//       id: '4',
//       merchant: 'Unknown Merchant',
//       amount: '₦35,000',
//       date: '3 days ago',
//       type: TransactionType.online,
//       icon: '⚠️',
//       suspicious: true,
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _cardAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat();

//     _cardRotation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _cardAnimationController,
//       curve: Curves.easeInOut,
//     ));

//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.1,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _cardAnimationController.dispose();
//     _pulseController.dispose();
//     super.dispose();
//   }

//   List<QuickAction> get _quickActions => [
//         QuickAction(
//           id: 'freeze',
//           title: _cardFrozen ? 'Unfreeze Card' : 'Freeze Card',
//           subtitle: _cardFrozen ? 'Reactivate now' : 'Disable temporarily',
//           icon: Icons.ac_unit,
//           color: _cardFrozen ? Colors.green : Colors.red,
//           action: () => setState(() => _cardFrozen = !_cardFrozen),
//         ),
//         QuickAction(
//           id: 'change-pin',
//           title: 'Change PIN',
//           subtitle: 'Update PIN',
//           icon: Icons.key,
//           color: Colors.blue,
//           action: () => _showSnackBar('Change PIN feature coming soon'),
//         ),
//         QuickAction(
//           id: 'block-card',
//           title: 'Block & Request New',
//           subtitle: 'Replace card',
//           icon: Icons.shield,
//           color: Colors.orange,
//           action: () => _showSnackBar('Block card feature coming soon'),
//         ),
//       ];

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   void _handleShowDetails() {
//     setState(() => _showBiometricModal = true);
//   }

//   void _handleBiometricSuccess() {
//     setState(() {
//       _showBiometricModal = false;
//       _showDetails = true;
//     });
//     _cardAnimationController.forward();

//     // Auto hide after 10 seconds
//     Future.delayed(const Duration(seconds: 10), () {
//       if (mounted && _showDetails) {
//         setState(() => _showDetails = false);
//         _cardAnimationController.reverse();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final isSmallScreen = size.width < 360;

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: Stack(
//         children: [
//           CustomScrollView(
//             slivers: [
//               // Custom App Bar
//               SliverAppBar(
//                 backgroundColor: Colors.white,
//                 elevation: 0,
//                 pinned: true,
//                 leading: Container(
//                   margin: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.black87),
//                     onPressed: () {},
//                   ),
//                 ),
//                 title: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Image.asset(
//                       "assets/images/AppIcon.png",
//                       height: 24,
//                       width: 24,
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'Cards',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//                 actions: [
//                   Container(
//                     margin: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: IconButton(
//                       icon: const Icon(Icons.more_vert, color: Colors.black87),
//                       onPressed: () {},
//                     ),
//                   ),
//                 ],
//               ),

//               // Content
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // 3D Card Preview
//                       _buildCardPreview(isSmallScreen),
//                       const SizedBox(height: 8),

//                       // Show Details Button
//                       _buildShowDetailsButton(),
//                       const SizedBox(height: 16),

//                       // Quick Actions
//                       _buildQuickActions(),
//                       const SizedBox(height: 16),

//                       // Recent Transactions
//                       _buildRecentTransactions(),
//                       const SizedBox(height: 16),

//                       // Call-to-Action Buttons
//                       _buildCallToActionButtons(),
//                       const SizedBox(height: 100), // Bottom padding
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // Biometric Modal
//           if (_showBiometricModal) _buildBiometricModal(),
//         ],
//       ),
//     );
//   }

//   Widget _buildCardPreview(bool isSmallScreen) {
//     final cardWidth = isSmallScreen ? 240.0 : 280.0;
//     final cardHeight = isSmallScreen ? 140.0 : 160.0;

//     return Center(
//       child: AnimatedBuilder(
//         animation: _cardRotation,
//         builder: (context, child) {
//           return Transform(
//             alignment: Alignment.center,
//             transform: Matrix4.identity()
//               ..setEntry(3, 2, 0.001)
//               ..rotateY(_cardRotation.value * 3.14159),
//             child: Container(
//               width: cardWidth,
//               height: cardHeight,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 gradient: const LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Color(0xFF1E293B),
//                     Color(0xFF0F172A),
//                   ],
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.3),
//                     blurRadius: 24,
//                     offset: const Offset(0, 12),
//                   ),
//                 ],
//               ),
//               child: _cardRotation.value < 0.5
//                   ? _buildCardFront(isSmallScreen)
//                   : Transform(
//                       alignment: Alignment.center,
//                       transform: Matrix4.identity()..rotateY(3.14159),
//                       child: _buildCardBack(isSmallScreen),
//                     ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCardFront(bool isSmallScreen) {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Container(
//                 width: 32,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Colors.amber, Colors.yellow],
//                   ),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//               Text(
//                 'RimaPay',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: isSmallScreen ? 12 : 14,
//                 ),
//               ),
//             ],
//           ),
//           const Spacer(),
//           Text(
//             _cardData.cardNumber,
//             style: TextStyle(
//               color: Colors.white,
//               fontFamily: 'monospace',
//               fontSize: isSmallScreen ? 16 : 18,
//               letterSpacing: 2,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'CARD HOLDER',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: isSmallScreen ? 8 : 10,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     _cardData.holderName,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                       fontSize: isSmallScreen ? 10 : 12,
//                     ),
//                   ),
//                 ],
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'EXPIRES',
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: isSmallScreen ? 8 : 10,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     _cardData.expiryDate,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                       fontSize: isSmallScreen ? 10 : 12,
//                     ),
//                   ),
//                 ],
//               ),
//               Text(
//                 _cardData.cardType,
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: isSmallScreen ? 10 : 12,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCardBack(bool isSmallScreen) {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             height: 40,
//             color: Colors.black54,
//             margin: const EdgeInsets.symmetric(horizontal: -20),
//           ),
//           const Spacer(),
//           Column(
//             children: [
//               Row(
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'FULL NUMBER',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: isSmallScreen ? 8 : 10,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         _cardData.fullNumber,
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontFamily: 'monospace',
//                           fontSize: isSmallScreen ? 10 : 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'CVV',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: isSmallScreen ? 8 : 10,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         _cardData.cvv,
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontFamily: 'monospace',
//                           fontSize: isSmallScreen ? 10 : 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         'BALANCE',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: isSmallScreen ? 8 : 10,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         _cardData.balance,
//                         style: TextStyle(
//                           color: Colors.green[400],
//                           fontWeight: FontWeight.bold,
//                           fontSize: isSmallScreen ? 10 : 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildShowDetailsButton() {
//     return Center(
//       child: TextButton.icon(
//         onPressed: _handleShowDetails,
//         icon: Icon(
//           _showDetails ? Icons.visibility_off : Icons.visibility,
//           size: 16,
//         ),
//         label: Text(
//           _showDetails ? 'Hide Details' : 'Show Details',
//           style: const TextStyle(fontSize: 12),
//         ),
//         style: TextButton.styleFrom(
//           foregroundColor: Colors.grey[700],
//           backgroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//             side: BorderSide(color: Colors.grey[300]!),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildQuickActions() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Quick Actions',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 12),
//         ..._quickActions.map((action) => _buildQuickActionTile(action)),
//       ],
//     );
//   }

//   Widget _buildQuickActionTile(QuickAction action) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: action.action,
//           borderRadius: BorderRadius.circular(12),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: action.color,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Icon(
//                     action.icon,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         action.title,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         action.subtitle,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentTransactions() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Recent Transactions',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//             TextButton(
//               onPressed: () {},
//               child: const Text(
//                 'View All',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Color(0xFF166C46),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[200]!),
//           ),
//           child: Column(
//             children: _recentTransactions.take(2).map((transaction) => _buildTransactionTile(transaction)).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTransactionTile(TransactionData transaction) {
//     return Container(
//       decoration: BoxDecoration(
//         color: transaction.suspicious ? Colors.red[50] : Colors.white,
//         borderRadius: const BorderRadius.all(Radius.circular(12)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Center(
//                 child: Text(
//                   transaction.icon,
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           transaction.merchant,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       Text(
//                         transaction.amount,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: transaction.suspicious ? Colors.red : Colors.black87,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         transaction.date,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           Text(
//                             _getTransactionTypeLabel(transaction.type),
//                             style: TextStyle(
//                               fontSize: 10,
//                               color: _getTransactionTypeColor(transaction.type),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           if (transaction.suspicious) ...[
//                             const SizedBox(width: 4),
//                             const Text(
//                               '⚠️',
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getTransactionTypeLabel(TransactionType type) {
//     switch (type) {
//       case TransactionType.pos:
//         return 'POS';
//       case TransactionType.online:
//         return 'Online';
//       case TransactionType.atm:
//         return 'ATM';
//     }
//   }

//   Color _getTransactionTypeColor(TransactionType type) {
//     switch (type) {
//       case TransactionType.pos:
//         return Colors.blue;
//       case TransactionType.online:
//         return Colors.green;
//       case TransactionType.atm:
//         return Colors.green;
//     }
//   }

//   Widget _buildCallToActionButtons() {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton(
//             onPressed: () => _showSnackBar('Physical card request coming soon'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF166C46),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               elevation: 0,
//             ),
//             child: const Text(
//               'Request Physical Card',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           width: double.infinity,
//           child: OutlinedButton(
//             onPressed: () => _showSnackBar('Card activation coming soon'),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: const Color(0xFF166C46),
//               side: const BorderSide(color: Color(0xFF166C46), width: 2),
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text(
//               'Activate Card',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildBiometricModal() {
//     return Material(
//       color: Colors.black54,
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(32),
//           padding: const EdgeInsets.all(32),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AnimatedBuilder(
//                 animation: _pulseAnimation,
//                 builder: (context, child) {
//                   return Transform.scale(
//                     scale: _pulseAnimation.value,
//                     child: Container(
//                       width: 64,
//                       height: 64,
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Color(0xFF166C46), Color(0xFF0E5C37)],
//                         ),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.fingerprint,
//                         color: Colors.white,
//                         size: 32,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Verify Identity',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Use your fingerprint or Face ID to view card details',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => setState(() => _showBiometricModal = false),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Text('Cancel'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         HapticFeedback.lightImpact();
//                         _handleBiometricSuccess();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF166C46),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: const Text('Verify'),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Data Models
// class CardData {
//   final String cardNumber;
//   final String fullNumber;
//   final String holderName;
//   final String expiryDate;
//   final String cvv;
//   final String cardType;
//   final String balance;

//   CardData({
//     required this.cardNumber,
//     required this.fullNumber,
//     required this.holderName,
//     required this.expiryDate,
//     required this.cvv,
//     required this.cardType,
//     required this.balance,
//   });
// }

// class TransactionData {
//   final String id;
//   final String merchant;
//   final String amount;
//   final String date;
//   final TransactionType type;
//   final String icon;
//   final bool suspicious;

//   TransactionData({
//     required this.id,
//     required this.merchant,
//     required this.amount,
//     required this.date,
//     required this.type,
//     required this.icon,
//     required this.suspicious,
//   });
// }

// enum TransactionType { pos, online, atm }

// class QuickAction {
//   final String id;
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final Color color;
//   final VoidCallback action;

//   QuickAction({
//     required this.id,
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     required this.color,
//     required this.action,
//   });
// }
class CardManagementScreen extends StatelessWidget {
  const CardManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
  

    return Scaffold(
  backgroundColor: Colors.white,
      body: const Center(
        child: Text('Coming soon'),
      ),
    );
  }
}
