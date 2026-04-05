import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';

class ToDoItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String status;
  final String priority;
  final String category;
  final VoidCallback action;

  ToDoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.priority,
    required this.category,
    required this.action,
  });
}

class Transaction {
  final String id;
  final String type;
  final String name;
  final String description;
  final String amount;
  final String time;
  final String category;

  Transaction({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.amount,
    required this.time,
    required this.category,
  });
}

class QuickAction {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback action;

  QuickAction({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.action,
  });
}

class BusinessService {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isNew;
  final VoidCallback action;

  BusinessService({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isNew = false,
    required this.action,
  });
}

class BusinessHome extends StatefulWidget {
  const BusinessHome({
    super.key,
  });

  @override
  State<BusinessHome> createState() => _BusinessHomeState();
}

class _BusinessHomeState extends State<BusinessHome> with TickerProviderStateMixin {
  bool _hideBalance = false;
  bool _notificationOpen = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;

  // Mock data - replace with actual data sources
  String get businessName => 'Business Account';
  String get businessBalance => '245,780.50';
  String get accountNumber => '4001234567';
  String get accountStatus => 'under_review';
  List<String> completedDocuments = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<ToDoItem> get allTodoItems => [
        ToDoItem(
          id: 'cac-certificate',
          title: 'Upload CAC Certificate',
          description: 'Upload your Certificate of Incorporation',
          icon: Icons.description,
          status: 'pending',
          priority: 'high',
          category: 'document',
          action: () {},
        ),
        ToDoItem(
          id: 'business-photo',
          title: 'Business Premises Photo',
          description: 'Take a photo of your business location',
          icon: Icons.camera_alt,
          status: 'pending',
          priority: 'high',
          category: 'verification',
          action: () {},
        ),
        ToDoItem(
          id: 'utility-bill',
          title: 'Utility Bill',
          description: 'Upload recent utility bill for address verification',
          icon: Icons.receipt_long,
          status: 'pending',
          priority: 'medium',
          category: 'document',
          action: () {},
        ),
        ToDoItem(
          id: 'director-id',
          title: 'Directors ID Cards',
          description: 'Upload valid ID cards for all directors',
          icon: Icons.upload_file,
          status: 'pending',
          priority: 'high',
          category: 'document',
          action: () {},
        ),
      ];

  List<ToDoItem> get todoItems => allTodoItems.where((item) => !completedDocuments.contains(item.id)).toList();

  List<Transaction> get recentTransactions => [
        Transaction(
          id: '1',
          type: 'received',
          name: 'Customer Payment',
          description: 'Invoice #INV-2024-001',
          amount: '45,000.00',
          time: '2 hours ago',
          category: 'income',
        ),
        Transaction(
          id: '2',
          type: 'sent',
          name: 'Office Supplies',
          description: 'Stationery purchase',
          amount: '12,500.00',
          time: 'Yesterday',
          category: 'bill',
        ),
        Transaction(
          id: '3',
          type: 'sent',
          name: 'Internet Bill',
          description: 'Monthly subscription',
          amount: '8,900.00',
          time: '2 days ago',
          category: 'subscription',
        ),
      ];

  List<QuickAction> get quickActions => [
        QuickAction(
          id: 'send-money',
          title: 'Send Money',
          description: 'Transfer to banks & wallets',
          icon: Icons.send,
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFF0E5C37)],
          ),
          action: () {},
        ),
        QuickAction(
          id: 'add-money',
          title: 'Add Money',
          description: 'Fund your account',
          icon: Icons.add,
          gradient: const LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
          ),
          action: () {},
        ),
        QuickAction(
          id: 'pay-bills',
          title: 'Pay Bills',
          description: 'Utilities & services',
          icon: Icons.lightbulb,
          gradient: const LinearGradient(
            colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
          ),
          action: () {},
        ),
        QuickAction(
          id: 'request-money',
          title: 'Request Payment',
          description: 'Generate payment links',
          icon: Icons.add_circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
          ),
          action: () {},
        ),
      ];

  List<BusinessService> get businessServices => [
        BusinessService(
          id: 'payroll',
          title: 'Payroll',
          description: 'Staff salary payments',
          icon: Icons.credit_card,
          color: Colors.blue,
          isNew: true,
          action: () {},
        ),
        BusinessService(
          id: 'bulk-transfer',
          title: 'Bulk Transfer',
          description: 'Multiple transfers at once',
          icon: Icons.send,
          color: Colors.green,
          action: () {},
        ),
        BusinessService(
          id: 'invoice',
          title: 'Create Invoice',
          description: 'Generate professional invoices',
          icon: Icons.description,
          color: Colors.purple,
          isNew: true,
          action: () {},
        ),
        BusinessService(
          id: 'analytics',
          title: 'Business Analytics',
          description: 'View business insights',
          icon: Icons.trending_up,
          color: Colors.orange,
          action: () {},
        ),
      ];

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade50;
      case 'medium':
        return Colors.amber.shade50;
      case 'low':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color getPriorityBorderColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade200;
      case 'medium':
        return Colors.amber.shade200;
      case 'low':
        return Colors.blue.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color getIconColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.amber.shade600;
      case 'low':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              if (accountStatus == 'under_review') _buildAccountReviewBanner(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodoSection(),
                    const SizedBox(height: 20),
                    _buildBusinessWalletCard(),
                    const SizedBox(height: 20),
                    _buildQuickActionsSection(),
                    const SizedBox(height: 20),
                    _buildBusinessServicesSection(),
                    const SizedBox(height: 20),
                    _buildRecentActivitySection(),
                    const SizedBox(height: 80), // Bottom padding for navigation
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.business, color: Color(0xFF166C46)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  businessName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2939),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildHeaderButton(Icons.language, () {}),
          const SizedBox(width: 8),
          _buildNotificationButton(),
          const SizedBox(width: 8),
          _buildHeaderButton(Icons.settings, () {}),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: Colors.grey.shade600, size: 16),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () => setState(() => _notificationOpen = true),
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(Icons.notifications, color: Colors.grey.shade600, size: 16),
          ),
          if (todoItems.isNotEmpty)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${todoItems.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountReviewBanner() {
    final progress = completedDocuments.length / allTodoItems.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.amber.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Under Review',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Text(
                  'Complete required documents to activate your account',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.orange.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${completedDocuments.length}/${allTodoItems.length}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My To-dos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Hide',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166C46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: todoItems.isEmpty
              ? _buildCompletedTodoCard()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: todoItems.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _buildTodoCard(todoItems[index], index),
                ),
        ),
      ],
    );
  }

  Widget _buildTodoCard(ToDoItem item, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
          ),
        );

        return Transform.translate(
          offset: Offset(20 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: GestureDetector(
              onTap: item.action,
              child: Container(
                width: 192,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: getPriorityColor(item.priority),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: getPriorityBorderColor(item.priority)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: item.priority == 'high'
                                ? Colors.red.shade100
                                : item.priority == 'medium'
                                    ? Colors.amber.shade100
                                    : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, color: getIconColor(item.priority), size: 12),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D2939),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.priority == 'high'
                            ? Colors.red.shade100
                            : item.priority == 'medium'
                                ? Colors.amber.shade100
                                : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.priority[0].toUpperCase()}${item.priority.substring(1)}',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: item.priority == 'high'
                              ? Colors.red.shade700
                              : item.priority == 'medium'
                                  ? Colors.amber.shade700
                                  : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTodoCard() {
    return Container(
      width: 192,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          SizedBox(height: 8),
          Text(
            'All Done!',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          Text(
            'All requirements completed',
            style: TextStyle(
              fontSize: 9,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessWalletCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseAnimation = Tween<double>(begin: 0.15, end: 0.25).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B4F2F),
                Color(0xFF073D25),
                Color(0xFF09422A),
                Color(0xFF073D25),
                Color(0xFF0B4F2F),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Background effects
              Positioned(
                top: 8,
                right: 16,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(pulseAnimation.value),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Business Account',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (accountStatus == 'under_review') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Under Review',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Business Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _hideBalance = !_hideBalance),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _hideBalance ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _hideBalance ? '••••••••' : '₦$businessBalance',
                      key: ValueKey(_hideBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    'Account: $accountNumber',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildWalletActionButton('Send Money', Icons.send, () {})),
                        const SizedBox(width: 8),
                        Expanded(child: _buildWalletActionButton('Add Money', Icons.add, () {})),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF166C46).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF166C46).withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title == 'Send Money' ? 'Transfer funds' : 'Fund account',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final itemWidth = (MediaQuery.of(context).size.width - (4 * 12)) / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              quickActions.length,
              (index) => SizedBox(
                width: itemWidth,
                height: itemWidth / 2, // Example aspect ratio, adjust as needed
                child: _buildQuickActionCard(quickActions[index], index),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.3 + (index * 0.05), 1.0, curve: Curves.easeOut),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: GestureDetector(
              onTap: action.action,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: action.gradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(action.icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              action.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              action.description,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Business Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166C46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: businessServices.length,
          itemBuilder: (context, index) => _buildBusinessServiceCard(businessServices[index], index),
        ),
      ],
    );
  }

  Widget _buildBusinessServiceCard(BusinessService service, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.4 + (index * 0.05), 1.0, curve: Curves.easeOut),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: GestureDetector(
              onTap: service.action,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: service.color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(service.icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  service.title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D2939),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  service.description,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (service.isNew)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166C46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTransactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildTransactionCard(recentTransactions[index], index),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index) {
    final isReceived = transaction.type == 'received';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.5 + (index * 0.05), 1.0, curve: Curves.easeOut),
          ),
        );

        return Transform.translate(
          offset: Offset(-20 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isReceived ? Colors.green.shade100 : Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isReceived ? Colors.green.shade600 : Colors.red.shade600,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D2939),
                            ),
                          ),
                          Text(
                            transaction.description,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isReceived ? '+' : '-'}₦${transaction.amount}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isReceived ? Colors.green.shade600 : Colors.red.shade600,
                          ),
                        ),
                        Text(
                          transaction.time,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
