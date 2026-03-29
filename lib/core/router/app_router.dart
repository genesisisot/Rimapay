import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/features/BusinessScreens/BusinessHome.dart';
import 'package:rimapay/features/NotificationScreen.dart';
import 'package:rimapay/features/Tiers/AccountTierScreen.dart';
import 'package:rimapay/features/airtime/presentation/screens/airtime_purchase_screen.dart';
import 'package:rimapay/features/auth/presentation/screens/business_account_flow.dart';
import 'package:rimapay/features/auth/presentation/screens/personal_account_flow.dart';
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
        builder: (context, state) => WelcomeScreen(),
      ),

      // Authentication Flow
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'login';
          return AuthScreen(
            mode: mode == 'login' ? AuthMode.login : AuthMode.signup,
          );
        },
      ),
      GoRoute(
        path: '/personal-account',
        name: 'personal-account',
        builder: (context, state) => PersonalAccountFlow(),
      ),
      GoRoute(
        path: '/business-account',
        name: 'business-account',
        builder: (context, state) => BusinessAccountFlow(),
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

          // Transfer Tab
          GoRoute(
            path: '/transfer',
            name: 'transfer',
            builder: (context, state) => const TransferScreen(),
          ),

          // Transactions Tab
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionHistoryScreen(),
          ),

          // Bills / Services Tab
          GoRoute(
            path: '/bills',
            name: 'bills',
            builder: (context, state) => const BillPaymentsScreen(),
          ),

          // Profile Tab
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Bill sub-screens (outside shell — no bottom nav)
      GoRoute(
        path: '/bills/airtime',
        name: 'airtime',
        builder: (context, state) => const AirtimePurchaseScreen(),
      ),
      GoRoute(
        path: '/bills/data',
        name: 'data',
        builder: (context, state) => const DataPurchaseScreen(),
      ),
      GoRoute(
        path: '/bills/cable',
        name: 'cable',
        builder: (context, state) => const CablePurchaseScreen(),
      ),
      GoRoute(
        path: '/bills/electricity',
        name: 'electricity',
        builder: (context, state) => const ElectricityPurchaseScreen(),
      ),

      // Settings (outside main navigation)
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Account Tiers (NEW ROUTE)
      GoRoute(
        path: '/tiers',
        name: 'tiers',
        builder: (context, state) => const AccountTiersScreen(),
      ),

     GoRoute(
        path: '/business',
        name: 'business',
        builder: (context, state) => BusinessHome(),
      ),

      // Add Money
      GoRoute(
        path: '/add-money',
        name: 'add-money',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Add Money', subtitle: 'Fund your account'),
      ),

      // Coming-soon stubs for unlocked services
      GoRoute(
        path: '/education-bills',
        builder: (_, __) => const ComingSoonScreen(title: 'Education', subtitle: 'School fee payments'),
      ),
      GoRoute(
        path: '/airtime-to-cash',
        builder: (_, __) => const ComingSoonScreen(title: 'Airtime → Cash', subtitle: 'Convert airtime to cash'),
      ),
      GoRoute(
        path: '/event-tickets',
        builder: (_, __) => const ComingSoonScreen(title: 'Events', subtitle: 'Buy tickets & concert passes'),
      ),
      GoRoute(
        path: '/betting-lottery',
        builder: (_, __) => const ComingSoonScreen(title: 'Betting', subtitle: 'Betting & lottery top-up'),
      ),
      GoRoute(
        path: '/voluntary-pension',
        builder: (_, __) => const ComingSoonScreen(title: 'Pension', subtitle: 'Voluntary pension contributions'),
      ),
      GoRoute(
        path: '/road-transport',
        builder: (_, __) => const ComingSoonScreen(title: 'Transport', subtitle: 'Buy bus tickets'),
      ),
      GoRoute(
        path: '/air-transport',
        builder: (_, __) => const ComingSoonScreen(title: 'Flights', subtitle: 'Book flight tickets'),
      ),
      GoRoute(
        path: '/state-government',
        builder: (_, __) => const ComingSoonScreen(title: 'Gov. Payments', subtitle: 'Taxes & government fees'),
      ),

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
          final extra = state.extra;
          if (extra is SuccessScreenProps) {
            return SuccessScreen(props: extra);
          }
          if (extra is Map<String, dynamic>) {
            return SuccessScreen(
              props: SuccessScreenProps(
                transactionType: extra['type']?.toString() ?? 'Payment',
                amount: extra['amount']?.toString() ?? '0',
                recipient: extra['recipient']?.toString() ?? '',
              ),
            );
          }
          return SuccessScreen(props: SuccessScreenProps());
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) {
          return NotificationScreen();
        },
      ),
      // Receipt Screen
      GoRoute(
        path: '/receipt',
        name: 'receipt',
        builder: (context, state) {
          final receiptData = state.extra as ReceiptData;
          return ReceiptScreen(
            receiptData: receiptData,
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

// ── Coming Soon Screen ────────────────────────────────────────────────────────

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  const ComingSoonScreen(
      {super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF001a0c),
                  Color(0xFF003d1a),
                  Color(0xFF005e27),
                ],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        )),
                    Text(subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🚧', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 20),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This feature is under development.\nCheck back soon!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
