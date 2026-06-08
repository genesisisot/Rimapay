import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/features/BusinessScreens/BusinessHome.dart';
import 'package:rimapay/features/internet/presentation/screens/internet_services_screen.dart';
import 'package:rimapay/features/fixed_deposit/presentation/screens/fixed_deposit_screen.dart';
import 'package:rimapay/features/cards/presentation/screens/cards_screen.dart';
import 'package:rimapay/features/grants/presentation/screens/grants_screen.dart';
import 'package:rimapay/features/zakat/presentation/screens/zakat_screen.dart';
import 'package:rimapay/features/remita/presentation/screens/remita_screen.dart';
import 'package:rimapay/features/account_limits/presentation/screens/account_limits_screen.dart';
import 'package:rimapay/features/NotificationScreen.dart';
import 'package:rimapay/features/Tiers/AccountTierScreen.dart';
import 'package:rimapay/features/add_money/presentation/screens/add_money_screen.dart';
import 'package:rimapay/features/airtime/presentation/screens/airtime_purchase_screen.dart';
import 'package:rimapay/features/airtime_cash/presentation/screens/airtime_cash_screen.dart';
import 'package:rimapay/features/auth/presentation/screens/business_account_flow.dart';
import 'package:rimapay/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:rimapay/features/auth/presentation/screens/personal_account_flow.dart';
import 'package:rimapay/features/bills/presentation/screens/bill_payments_screen.dart';
import 'package:rimapay/features/cable/presentation/screens/cable_purchase_screen.dart';
import 'package:rimapay/features/data/presentation/screens/data_purchase_screen.dart';
import 'package:rimapay/features/education/presentation/screens/education_bills_screen.dart';
import 'package:rimapay/features/electricity/presentation/screens/electricity_purchase_screen.dart';
import 'package:rimapay/features/events/presentation/screens/events_screen.dart';
import 'package:rimapay/features/flights/presentation/screens/flights_screen.dart';
import 'package:rimapay/features/government/presentation/screens/government_screen.dart';
import 'package:rimapay/features/pension/presentation/screens/pension_screen.dart';
import 'package:rimapay/features/pin_verification/presentation/screens/pin_verification_screen.dart';
import 'package:rimapay/features/profile/presentation/screens/residential_address_screen.dart';
import 'package:rimapay/features/profile/presentation/screens/pep_declaration_screen.dart';
import 'package:rimapay/features/profile/presentation/screens/source_of_income_screen.dart';
import 'package:rimapay/features/transport/presentation/screens/transport_screen.dart';
import 'package:rimapay/features/profile/presentation/screens/profile_screen.dart';
import 'package:rimapay/features/receipt/presentation/screens/receipt_screen.dart'
    show ReceiptScreen, ReceiptData;
import 'package:rimapay/features/success/presentation/screens/success_screen.dart';
import 'package:rimapay/features/transactions/presentation/screens/transaction_history_screen.dart';
import 'package:rimapay/features/transfer/presentation/screens/transfer_screen.dart';
import 'package:rimapay/shared/presentation/screens/main_app_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/presentation/screens/main_navigation_screen.dart';

// Shared fade page builder
Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

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
        pageBuilder: (context, state) {
          final accountType = state.extra as String? ?? 'personal';
          return _fadePage(state, PersonalAccountFlow(accountType: accountType));
        },
      ),
      GoRoute(
        path: '/business-account',
        name: 'business-account',
        pageBuilder: (context, state) =>
            _fadePage(state, BusinessAccountFlow()),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) =>
            _fadePage(state, const ForgotPasswordScreen()),
      ),
      // Profile completion routes
      GoRoute(
        path: '/residential-address',
        name: 'residential-address',
        pageBuilder: (context, state) =>
            _fadePage(state, const ResidentialAddressScreen()),
      ),
      GoRoute(
        path: '/pep-declaration',
        name: 'pep-declaration',
        pageBuilder: (context, state) =>
            _fadePage(state, const PepDeclarationScreen()),
      ),
      GoRoute(
        path: '/source-of-income',
        name: 'source-of-income',
        pageBuilder: (context, state) =>
            _fadePage(state, const SourceOfIncomeScreen()),
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
            builder: (context, state) => const DashboardScreen(),
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
        pageBuilder: (context, state) {
          final initialTab = state.extra as int? ?? 0;
          return _fadePage(
              state, AirtimePurchaseScreen(initialTab: initialTab));
        },
      ),
      GoRoute(
        path: '/bills/data',
        name: 'data',
        redirect: (context, state) => '/bills/airtime',
      ),
      GoRoute(
        path: '/bills/cable',
        name: 'cable',
        pageBuilder: (context, state) =>
            _fadePage(state, const CablePurchaseScreen()),
      ),
      GoRoute(
        path: '/bills/electricity',
        name: 'electricity',
        pageBuilder: (context, state) =>
            _fadePage(state, const ElectricityPurchaseScreen()),
      ),

      // Settings (outside main navigation)
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            _fadePage(state, const SettingsScreen()),
      ),

      // Account Tiers (NEW ROUTE)
      GoRoute(
        path: '/tiers',
        name: 'tiers',
        pageBuilder: (context, state) =>
            _fadePage(state, const AccountTiersScreen()),
      ),

      GoRoute(
        path: '/business',
        name: 'business',
        pageBuilder: (context, state) => _fadePage(state, BusinessHome()),
      ),

      // Add Money
      GoRoute(
        path: '/add-money',
        name: 'add-money',
        pageBuilder: (context, state) =>
            _fadePage(state, const AddMoneyScreen()),
      ),

      // Bill service screens
      GoRoute(
        path: '/education-bills',
        pageBuilder: (context, state) =>
            _fadePage(state, const EducationBillsScreen()),
      ),
      GoRoute(
        path: '/airtime-to-cash',
        pageBuilder: (context, state) =>
            _fadePage(state, const AirtimeCashScreen()),
      ),
      GoRoute(
        path: '/event-tickets',
        pageBuilder: (context, state) => _fadePage(state, const EventsScreen()),
      ),
      GoRoute(
        path: '/voluntary-pension',
        pageBuilder: (context, state) =>
            _fadePage(state, const PensionScreen()),
      ),
      GoRoute(
        path: '/road-transport',
        pageBuilder: (context, state) =>
            _fadePage(state, const TransportScreen()),
      ),
      GoRoute(
        path: '/air-transport',
        pageBuilder: (context, state) =>
            _fadePage(state, const FlightsScreen()),
      ),
      GoRoute(
        path: '/state-government',
        pageBuilder: (context, state) =>
            _fadePage(state, const GovernmentScreen()),
      ),

      // New feature screens
      GoRoute(
        path: '/bills/internet',
        pageBuilder: (context, state) =>
            _fadePage(state, const InternetServicesScreen()),
      ),
      GoRoute(
        path: '/fixed-deposit',
        pageBuilder: (context, state) =>
            _fadePage(state, const FixedDepositScreen()),
      ),
      GoRoute(
        path: '/cards',
        pageBuilder: (context, state) =>
            _fadePage(state, const CardsScreen()),
      ),
      GoRoute(
        path: '/grants-donation',
        pageBuilder: (context, state) =>
            _fadePage(state, const GrantsScreen()),
      ),
      GoRoute(
        path: '/zakat',
        pageBuilder: (context, state) =>
            _fadePage(state, const ZakatScreen()),
      ),
      GoRoute(
        path: '/remita',
        pageBuilder: (context, state) =>
            _fadePage(state, const RemitaScreen()),
      ),
      GoRoute(
        path: '/account-limits',
        pageBuilder: (context, state) =>
            _fadePage(state, const AccountLimitsScreen()),
      ),

      // PIN Verification
      GoRoute(
        path: '/pin-verification',
        name: 'pin-verification',
        pageBuilder: (context, state) {
          final transactionData = state.extra as Map<String, dynamic>?;
          return _fadePage(
              state,
              PinVerificationScreen(
                transactionData: transactionData ?? {},
              ));
        },
      ),

      // Success Screen
      GoRoute(
        path: '/success',
        name: 'success',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is SuccessScreenProps) {
            return _fadePage(state, SuccessScreen(props: extra));
          }
          if (extra is Map<String, dynamic>) {
            return _fadePage(
                state,
                SuccessScreen(
                  props: SuccessScreenProps(
                    transactionType: extra['type']?.toString() ?? 'Payment',
                    amount: extra['amount']?.toString() ?? '0',
                    recipient: extra['recipient']?.toString() ?? '',
                  ),
                ));
          }
          return _fadePage(state, SuccessScreen(props: SuccessScreenProps()));
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => _fadePage(state, NotificationScreen()),
      ),
      // Receipt Screen
      GoRoute(
        path: '/receipt',
        name: 'receipt',
        pageBuilder: (context, state) {
          final receiptData = state.extra as ReceiptData;
          return _fadePage(state, ReceiptScreen(receiptData: receiptData));
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF073D25),
                  Color(0xFF0B4F2F),
                  Color(0xFF073D25),
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
