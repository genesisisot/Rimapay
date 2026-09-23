import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../success/presentation/screens/success_screen.dart';
import '../../../bills/data/bills_dtos.dart';
import '../../../bills/presentation/providers/bills_providers.dart';
import '../../../bills/presentation/widgets/bill_purchase_flow.dart';

import '../../../../core/localization/l10n.dart';
class InternetServicesScreen extends ConsumerStatefulWidget {
  const InternetServicesScreen({super.key});

  @override
  ConsumerState<InternetServicesScreen> createState() => _InternetServicesScreenState();
}

class _InternetServicesScreenState extends ConsumerState<InternetServicesScreen> {
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  BillerDto? _provider;
  BillerItemDto? _plan;

  static const _ispColors = [
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _accountController.addListener(_refresh);
    _amountController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  double get _payAmount => _plan == null
      ? 0
      : (_plan!.isAmountFixed && _plan!.amount > 0)
          ? _plan!.amount
          : double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

  bool get _canProceed =>
      _provider != null &&
      _plan != null &&
      _accountController.text.isNotEmpty &&
      _payAmount > 0;

  void _pay() {
    final provider = _provider;
    final plan = _plan;
    if (!_canProceed || provider == null || plan == null) return;
    final account = _accountController.text;
    final amount = _payAmount;
    final amountText = formatBillAmount(amount);
    runBillPurchase(
      context: context,
      summary: [
        {'label': 'Service', 'value': 'Internet'},
        {'label': 'Provider', 'value': provider.displayName},
        {'label': 'Plan', 'value': plan.name ?? 'Plan'},
        {'label': 'Account / Device ID', 'value': account},
        {'label': 'Amount', 'value': '₦$amountText'},
      ],
      submit: (pin, sourceAccount) =>
          ref.read(billsApiServiceProvider).payBill(BillPaymentRequest(
                sourceAccount: sourceAccount,
                billerId: provider.billerId,
                billerItemId: plan.billerItemId,
                customerId: account,
                amount: amount,
                transactionPin: pin,
              )),
      successProps: (result) => SuccessScreenProps(
        transactionType: 'Internet',
        amount: amountText,
        recipient: '${provider.displayName} – $account',
        transactionId: result.transactionReference,
      ),
    );
  }

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billersAsync = ref.watch(billersByKindProvider(BillCategoryKind.internet));
    final billers = billersAsync.valueOrNull?.billers ?? const <BillerDto>[];
    final itemsAsync =
        _provider == null ? null : ref.watch(billerItemsProvider(_provider!.billerId));
    final plans = itemsAsync?.valueOrNull ?? const <BillerItemDto>[];

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
                  _sectionLabel('Select Provider'),
                  const SizedBox(height: 10),
                  if (billersAsync.isLoading && !billersAsync.hasValue)
                    _statusText(context.l10n.loadingProviders)
                  else if (billers.isEmpty)
                    GestureDetector(
                      onTap: () => refreshBillers(ref, BillCategoryKind.internet),
                      child: _statusText(context.l10n.noProvidersAvailable),
                    )
                  else
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: billers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final p = billers[i];
                          final color = _ispColors[i % _ispColors.length];
                          final active = _provider?.billerId == p.billerId;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _provider = p;
                              _plan = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 110,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: active ? color.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active ? color : Theme.of(context).dividerColor,
                                  width: active ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('📡', style: TextStyle(fontSize: 24)),
                                  const SizedBox(height: 6),
                                  Text(p.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: active ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                      )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),
                  _sectionLabel('Account / Device ID'),
                  const SizedBox(height: 8),
                  _buildInput(
                    controller: _accountController,
                    hint: 'Enter account or device ID',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('Select Plan'),
                  const SizedBox(height: 10),
                  if (_provider == null)
                    _statusText(context.l10n.selectProviderFirst)
                  else if (itemsAsync != null && itemsAsync.isLoading && !itemsAsync.hasValue)
                    _statusText(context.l10n.loadingPlans)
                  else if (plans.isEmpty)
                    GestureDetector(
                      onTap: () => ref.invalidate(billerItemsProvider(_provider!.billerId)),
                      child: _statusText(context.l10n.noPlansAvailableRetry),
                    )
                  else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: plans.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                    ),
                    itemBuilder: (_, i) {
                      final plan = plans[i];
                      final active = _plan?.billerItemId == plan.billerItemId;
                      return GestureDetector(
                        onTap: () => setState(() => _plan = plan),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: active ? Theme.of(context).colorScheme.surface.withOpacity(0.5) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? Color(0xFF1A6B35) : Theme.of(context).dividerColor,
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(plan.name ?? 'Plan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF1A6B35),
                                  )),
                              Text(plan.isAmountFixed && plan.amount > 0
                                      ? '₦${formatBillAmount(plan.amount)}'
                                      : 'Any amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  )),
                              if (plan.itemFee > 0)
                                Text(context.l10n.itemfeeFee(formatBillAmount(plan.itemFee)),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  if (_plan != null && !(_plan!.isAmountFixed && _plan!.amount > 0)) ...[
                    const SizedBox(height: 20),
                    _sectionLabel('Amount'),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _amountController,
                      hint: 'Enter amount',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canProceed ? _pay : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6B35),
                        disabledBackgroundColor: Theme.of(context).dividerColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(context.l10n.proceed,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
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
          colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/bills'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.internetServices,
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              Text(context.l10n.spectranetSmileMore,
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)));
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A6B35), width: 2),
        ),
      ),
    );
  }
}
