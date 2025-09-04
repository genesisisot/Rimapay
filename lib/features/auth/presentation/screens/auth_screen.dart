import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/biometric_service.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  final AuthMode mode;
  
  const AuthScreen({
    super.key,
    required this.mode,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricAvailability();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    
    setState(() {
      _biometricAvailable = available && enabled && widget.mode == AuthMode.login;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;

    try {
      if (widget.mode == AuthMode.login) {
        success = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await authProvider.register(
          _emailController.text.trim(),
          _passwordController.text,
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          _phoneController.text.trim(),
        );
      }

      if (success && mounted) {
        // Haptic feedback
        HapticFeedback.lightImpact();
        context.go('/home');
      } else if (mounted) {
        _showErrorMessage(authProvider.error ?? 'Authentication failed');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await BiometricService.authenticateForLogin();
      
      if (result == AuthResult.success) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // Mock successful biometric login - you might want to implement proper biometric token storage
        final success = await authProvider.login('biometric@rimapay.com', 'biometric_auth');
        
        if (success && mounted) {
          HapticFeedback.lightImpact();
          context.go('/home');
        } else if (mounted) {
          _showErrorMessage('Biometric login failed. Please try again.');
        }
      } else if (mounted && result != AuthResult.cancelled) {
        _showErrorMessage(BiometricService.getAuthResultMessage(result));
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Biometric authentication error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?[0-9]{10,14}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isLogin = widget.mode == AuthMode.login;

    return Scaffold(
      backgroundColor: AppColors.neutral0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back_ios),
          color: AppColors.neutral600,
        ),
        actions: [
          TextButton(
            onPressed: () {
              
              final newMode = isLogin ? AuthMode.register : AuthMode.login;
              context.go(newMode == AuthMode.login ? '/auth?mode=login' : '/auth?mode=register');
            },
            child: Text(
              isLogin ? languageProvider.t('signUp') : languageProvider.t('login'),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.responsivePadding(context),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Title and subtitle
                    _buildHeader(languageProvider, isLogin),
                    
                    const SizedBox(height: AppSpacing.xxxl),
                    
                    // Form fields
                    _buildFormFields(languageProvider, isLogin),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Submit button
                    _buildSubmitButton(languageProvider, isLogin),
                    
                    if (isLogin) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildForgotPassword(languageProvider),
                    ],
                    
                    if (_biometricAvailable && isLogin) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildBiometricOption(),
                    ],
                    
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageProvider languageProvider, bool isLogin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isLogin ? 'Welcome Back' : 'Create Account',
          style: AppTextStyles.responsiveHeading1(context).copyWith(
            color: AppColors.neutral900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isLogin 
            ? 'Sign in to access your RimaPay account'
            : 'Join thousands of users managing their finances with RimaPay',
          style: AppTextStyles.responsiveBodyMedium(context).copyWith(
            color: AppColors.neutral600,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(LanguageProvider languageProvider, bool isLogin) {
    return Column(
      children: [
        if (!isLogin) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  validator: (value) => _validateRequired(value, 'First name'),
                  decoration: InputDecoration(
                    labelText: languageProvider.t('firstName'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  validator: (value) => _validateRequired(value, 'Last name'),
                  decoration: InputDecoration(
                    labelText: languageProvider.t('lastName'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          TextFormField(
            controller: _phoneController,
            validator: _validatePhone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: languageProvider.t('phoneNumber'),
              prefixIcon: const Icon(Icons.phone_outlined),
              hintText: '+234 800 000 0000',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        
        TextFormField(
          controller: _emailController,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: languageProvider.t('email'),
            prefixIcon: const Icon(Icons.email_outlined),
            hintText: 'your.email@example.com',
          ),
          textInputAction: TextInputAction.next,
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        TextFormField(
          controller: _passwordController,
          validator: _validatePassword,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            labelText: languageProvider.t('password'),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleSubmit(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(LanguageProvider languageProvider, bool isLogin) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary500.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        ),
        child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              isLogin ? languageProvider.t('login') : languageProvider.t('signUp'),
              style: AppTextStyles.responsiveButtonMedium(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }

  Widget _buildForgotPassword(LanguageProvider languageProvider) {
    return Center(
      child: TextButton(
        onPressed: () {
          // TODO: Navigate to forgot password
        },
        child: Text(
          languageProvider.t('forgotPassword'),
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary500,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricOption() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.neutral200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'or',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.neutral200)),
          ],
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        GestureDetector(
          onTap: _isLoading ? null : _handleBiometricLogin,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _isLoading ? AppColors.primary100.withOpacity(0.5) : AppColors.primary100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: _isLoading ? AppColors.primary200.withOpacity(0.5) : AppColors.primary200,
                width: 2,
              ),
            ),
            child: _isLoading 
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
                  ),
                )
              : Icon(
                  Icons.fingerprint,
                  size: 36,
                  color: AppColors.primary500,
                ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Use biometric to sign in',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }
}