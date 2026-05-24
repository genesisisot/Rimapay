// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/providers/app_state_provider.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';
// import '../../core/localization/app_localizations.dart';

// class ModernNavigation extends StatefulWidget {
//   final String activeTab;
//   final Function(String) onTabChange;

//   const ModernNavigation({
//     super.key,
//     required this.activeTab,
//     required this.onTabChange,
//   });

//   @override
//   State<ModernNavigation> createState() => _ModernNavigationState();
// }

// class _ModernNavigationState extends State<ModernNavigation>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(
//       begin: 0.95,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOut,
//     ));

//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final localizations = AppLocalizations.of(context)!;
//     final appState = context.watch<AppStateProvider>();
    
//     final tabs = [
//       _NavigationTab(
//         id: 'home',
//         icon: Icons.home_filled,
//         activeIcon: Icons.home,
//         label: localizations.home,
//         screen: ,
//       ),
//       _NavigationTab(
//         id: 'transactions',
//         icon: Icons.receipt_long,
//         activeIcon: Icons.receipt_long_outlined,
//         label: localizations.transactions,
//         screen: AppScreen.transactions,
//       ),
//       _NavigationTab(
//         id: 'cards',
//         icon: Icons.credit_card,
//         activeIcon: Icons.credit_card_outlined,
//         label: localizations.cards,
//         screen: AppScreen.cards,
//       ),
//       _NavigationTab(
//         id: 'profile',
//         icon: Icons.person,
//         activeIcon: Icons.person_outline,
//         label: localizations.profile,
//         screen: AppScreen.profile,
//       ),
//     ];

//     return AnimatedBuilder(
//       animation: _scaleAnimation,
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _scaleAnimation.value,
//           child: Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context).cardColor,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 20,
//                   offset: const Offset(0, -5),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               top: false,
//               child: Container(
//                 height: 70,
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: tabs.map((tab) {
//                     final isActive = widget.activeTab == tab.id;
//                     return _buildNavigationItem(tab, isActive, appState);
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildNavigationItem(_NavigationTab tab, bool isActive, AppStateProvider appState) {
//     return Expanded(
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () {
//             widget.onTabChange(tab.id);
//             appState.navigateToScreen(tab.screen);
//             _animationController.reset();
//             _animationController.forward();
//           },
//           borderRadius: BorderRadius.circular(12),
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 8),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: isActive 
//                         ? AppColors.primary500.withOpacity(0.1)
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     isActive ? tab.activeIcon : tab.icon,
//                     color: isActive ? AppColors.primary500 : AppColors.neutral400,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 AnimatedDefaultTextStyle(
//                   duration: const Duration(milliseconds: 200),
//                   style: AppTextStyles.caption.copyWith(
//                     color: isActive ? AppColors.primary500 : AppColors.neutral400,
//                     fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
//                     fontSize: 11,
//                   ),
//                   child: Text(
//                     tab.label,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NavigationTab {
//   final String id;
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;
//   final AppScreen screen;

//   _NavigationTab({
//     required this.id,
//     required this.icon,
//     required this.activeIcon,
//     required this.label,
//     required this.screen,
//   });
// }