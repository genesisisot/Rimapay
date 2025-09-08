import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/features/airtime/presentation/screens/airtime_purchase_screen.dart';
import 'package:rimapay/features/bills/presentation/screens/bill_payments_screen.dart';
import 'package:rimapay/features/cable/presentation/screens/cable_purchase_screen.dart';
import 'package:rimapay/features/data/presentation/screens/data_purchase_screen.dart';
import 'package:rimapay/features/electricity/presentation/screens/electricity_purchase_screen.dart';
import 'package:rimapay/features/pin_verification/presentation/screens/pin_verification_screen.dart';
import 'package:rimapay/features/profile/presentation/screens/profile_screen.dart';
import 'package:rimapay/features/receipt/presentation/screens/receipt_screen.dart' show ReceiptScreen, ReceiptData;
import 'package:rimapay/features/success/presentation/screens/success_screen.dart';
import 'package:rimapay/features/transactions/presentation/screens/transaction_history_screen.dart';
import 'package:rimapay/features/transfer/presentation/screens/transfer_screen.dart';
import 'package:rimapay/shared/presentation/screens/main_app_screen.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

import '../../features/settings/presentation/screens/settings_screen.dart';

import '../../shared/presentation/screens/main_navigation_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash & Welcome Flow
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) =>  WelcomeScreen() ,
      ),

      // Authentication Flow
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'login';
          return AuthScreen(
            mode: mode == 'login' ? AuthMode.login : AuthMode.register,
          );
        },
      ),

      // Main Navigation Shell
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          // Home Tab
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Transactions Tab
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionHistoryScreen(),
          ),

          // Cards Tab
          GoRoute(
            path: '/cards',
            name: 'cards',
            builder: (context, state) => const CardManagementScreen(),
          ),

          // Profile Tab
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Settings (outside main navigation)
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Bill Payments Flow
      GoRoute(
        path: '/bills',
        name: 'bills',
        builder: (context, state) => const BillPaymentsScreen(),
        routes: [
          GoRoute(
            path: '/airtime',
            name: 'airtime',
            builder: (context, state) => const AirtimePurchaseScreen(),
          ),
          GoRoute(
            path: '/data',
            name: 'data',
            builder: (context, state) => const DataPurchaseScreen(),
          ),
          GoRoute(
            path: '/cable',
            name: 'cable',
            builder: (context, state) => const CablePurchaseScreen(),
          ),
          GoRoute(
            path: '/electricity',
            name: 'electricity',
            builder: (context, state) => const ElectricityPurchaseScreen(),
          ),
        ],
      ),

      // Transfer Flow
      GoRoute(
        path: '/transfer',
        name: 'transfer',
        builder: (context, state) => const TransferScreen(),
      ),

      // Add Money Flow
      // GoRoute(
      //   path: '/add-money',
      //   name: 'add-money',
      //   builder: (context, state) => const AddMoneyScreen(),
      // ),

      // PIN Verification
      GoRoute(
        path: '/pin-verification',
        name: 'pin-verification',
        builder: (context, state) {
          final transactionData = state.extra as Map<String, dynamic>?;
          return PinVerificationScreen(
            transactionData: transactionData ?? {},
          );
        },
      ),

      // Success Screen
      GoRoute(
        path: '/success',
        name: 'success',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return SuccessScreen(
            transactionData: data ?? {},
          );
        },
      ),

      // Receipt Screen
      GoRoute(
        path: '/receipt',
        name: 'receipt',
        builder: (context, state) {
          final receiptData = state.extra as Map<String, dynamic>?;
          return ReceiptScreen(
            receiptData: ReceiptData(
              amount: "",
              date: "",
              recipient: "",
              reference: "",
              status: "",
              time: "",
              type: "",
            ),
          );
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),

    // Redirect logic
    redirect: (context, state) {
      // Add authentication logic here
      // For now, allow all navigation
      return null;
    },
  );
}

// Navigation helper methods
class AppNavigation {
  static void goToHome(BuildContext context) {
    context.go('/home');
  }

  static void goToAuth(BuildContext context, {String mode = 'login'}) {
    context.go('/auth?mode=$mode');
  }

  static void goToBills(BuildContext context) {
    context.go('/bills');
  }

  static void goToTransfer(BuildContext context) {
    context.go('/transfer');
  }

  static void goToAddMoney(BuildContext context) {
    context.go('/add-money');
  }

  static void goToPinVerification(
    BuildContext context,
    Map<String, dynamic> transactionDetails,
  ) {
    context.go('/pin-verification', extra: transactionDetails);
  }

  static void goToSuccess(
    BuildContext context,
    Map<String, dynamic> transactionData,
  ) {
    context.go('/success', extra: transactionData);
  }

  static void goToReceipt(
    BuildContext context,
    Map<String, dynamic> receiptData,
  ) {
    context.go('/receipt', extra: receiptData);
  }

  static void goToSettings(BuildContext context) {
    context.go('/settings');
  }

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}
