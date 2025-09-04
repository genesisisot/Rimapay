import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../features/splash/presentation/screens/splash_screen.dart';
import '../../../features/welcome/presentation/screens/welcome_screen.dart';
import '../../../features/auth/presentation/screens/auth_screen.dart';
import '../../../features/home/presentation/screens/home_screen.dart';
import '../../../features/bills/presentation/screens/bill_payments_screen.dart';
import '../../../features/transactions/presentation/screens/transaction_history_screen.dart';
import '../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../features/airtime/presentation/screens/airtime_purchase_screen.dart';
import '../../../features/data/presentation/screens/data_purchase_screen.dart';
import '../../../features/cable/presentation/screens/cable_purchase_screen.dart';
import '../../../features/electricity/presentation/screens/electricity_purchase_screen.dart';
import '../../../features/transfer/presentation/screens/transfer_screen.dart';
import '../../../features/pin_verification/presentation/screens/pin_verification_screen.dart';
import '../../../features/success/presentation/screens/success_screen.dart';
import '../../../features/receipt/presentation/screens/receipt_screen.dart';
import '../../../shared/widgets/modern_navigation.dart';

// class MainAppScreen extends StatelessWidget {
//   const MainAppScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<AppStateProvider, AuthProvider>(
//       builder: (context, appState, authProvider, child) {
//         return Scaffold(
//           body: AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             transitionBuilder: (Widget child, Animation<double> animation) {
//               return SlideTransition(
//                 position: Tween<Offset>(
//                   begin: const Offset(1.0, 0.0),
//                   end: Offset.zero,
//                 ).animate(animation),
//                 child: child,
//               );
//             },
//             child: _buildScreen(appState.currentScreen, appState, authProvider),
//           ),
//           bottomNavigationBar: appState.showBottomNav
//               ? ModernNavigation(
//                   activeTab: appState.activeTab,
//                   onTabChange: appState.setActiveTab,
//                 )
//               : null,
//         );
//       },
//     );
//   }

//   Widget _buildScreen(
//     AppScreen screen,
//     AppStateProvider appState,
//     AuthProvider authProvider,
//   ) {
//     switch (screen) {
//       case AppScreen.splash:
//         return const SplashScreen(key: ValueKey('splash'));

//       case AppScreen.welcome:
//         return const WelcomeScreen(key: ValueKey('welcome'));

//       case AppScreen.register:
//         return const AuthScreen(
//           key: ValueKey('register'),
//           mode: AuthMode.register,
//         );

//       case AppScreen.login:
//         return const AuthScreen(
//           key: ValueKey('login'),
//           mode: AuthMode.login,
//         );

//       case AppScreen.home:
//         return const HomeScreen(key: ValueKey('home'));

//       case AppScreen.transactions:
//         return const TransactionHistoryScreen(key: ValueKey('transactions'));

//       case AppScreen.cards:
//         return const CardManagementScreen(key: ValueKey('cards'));

//       case AppScreen.profile:
//         return const ProfileScreen(key: ValueKey('profile'));

//       case AppScreen.settings:
//         return const SettingsScreen(key: ValueKey('settings'));

//       case AppScreen.bills:
//         return const BillPaymentsScreen(key: ValueKey('bills'));

//       case AppScreen.airtime:
//         return const AirtimePurchaseScreen(key: ValueKey('airtime'));

//       case AppScreen.data:
//         return const DataPurchaseScreen(key: ValueKey('data'));

//       case AppScreen.cable:
//         return const CablePurchaseScreen(key: ValueKey('cable'));

//       case AppScreen.buyElectricity:
//         return const ElectricityPurchaseScreen(key: ValueKey('electricity'));

//       case AppScreen.transfer:
//       case AppScreen.send:
//         return const TransferScreen(key: ValueKey('transfer'));

//       case AppScreen.pinVerification:
//         return PinVerificationScreen(
//           key: const ValueKey('pin'),
//           transactionDetails: appState.pendingTransactionDetails!,
//         );

//       case AppScreen.success:
//         return SuccessScreen(
//           key: const ValueKey('success'),
//           transactionDetails: appState.transactionDetails!,
//         );

//       case AppScreen.receipt:
//         return ReceiptScreen(
//           key: const ValueKey('receipt'),
//           receiptData: appState.receiptData!,
//         );

//       default:
//         return const HomeScreen(k
//ey: ValueKey('default'));
//     }
//   }
// }

// Placeholder screens for missing features
class CardManagementScreen extends StatelessWidget {
  const CardManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.navigateToHome();
            // appState.setActiveTab('home');
          },
        ),
      ),
      body: const Center(
        child: Text('Card Management Screen'),
      ),
    );
  }
}
