import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountLimitsScreen extends StatelessWidget {
  const AccountLimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current tier badge
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A6B35), Color(0xFF0B4F2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('⭐', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Current Tier: Basic',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 2),
                              Text('Upgrade to unlock higher limits',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/tiers'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Upgrade',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Transaction Limits',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828))),
                  const SizedBox(height: 12),

                  _buildLimitsTable(context, 'Transfers', [
                    _LimitRow('Single Transfer', '₦50,000', '₦200,000', '₦500,000'),
                    _LimitRow('Daily Transfer', '₦200,000', '₦1,000,000', '₦5,000,000'),
                  ]),

                  const SizedBox(height: 16),
                  _buildLimitsTable(context, 'Bills & Payments', [
                    _LimitRow('Single Payment', '₦50,000', '₦200,000', '₦500,000'),
                    _LimitRow('Daily Bills', '₦100,000', '₦500,000', '₦2,000,000'),
                  ]),

                  const SizedBox(height: 16),
                  _buildLimitsTable(context, 'Account Balance', [
                    _LimitRow('Maximum Balance', '₦300,000', '₦1,000,000', 'Unlimited'),
                    _LimitRow('Fixed Deposit', 'Not available', '₦5,000,000', 'Unlimited'),
                  ]),

                  const SizedBox(height: 16),
                  _buildLimitsTable(context, 'POS / ATM', [
                    _LimitRow('ATM Daily', '₦20,000', '₦100,000', '₦300,000'),
                    _LimitRow('POS Daily', '₦50,000', '₦200,000', '₦1,000,000'),
                  ]),

                  const SizedBox(height: 24),
                  // CBN regulatory note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF1A6B35).withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF1A6B35), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Limits are set in accordance with CBN regulations for microfinance banks. Upgrade your account tier to increase your limits.',
                            style: TextStyle(
                              color: const Color(0xFF1A6B35).withOpacity(0.85),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsTable(
      BuildContext context, String title, List<_LimitRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF101828))),
                ),
                ...[
                  ('T1', '⭐'),
                  ('T2', '🥈'),
                  ('T3', '🥇'),
                ].map((t) => Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text(t.$2, style: const TextStyle(fontSize: 12)),
                          Text(t.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  color: Color(0xFF667085))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            final row = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFF5F5F5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(row.label,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF667085))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(row.tier1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF101828))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(row.tier2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF101828))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(row.tier3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A6B35))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/settings'),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Limits',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              Text('CBN-regulated transaction limits',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LimitRow {
  final String label;
  final String tier1;
  final String tier2;
  final String tier3;
  const _LimitRow(this.label, this.tier1, this.tier2, this.tier3);
}
