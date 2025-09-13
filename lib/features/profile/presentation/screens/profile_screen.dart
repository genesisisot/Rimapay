import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rimapay/core/router/app_router.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _editAnimationController;
  late AnimationController _profileImageController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isEditing = false;
  bool _showImageOptions = false;
  String? _profileImage;

  final _imagePicker = ImagePicker();

  // Edit form data
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Original user data (mock data - replace with actual user data)
  final Map<String, String> _originalData = {
    'fullName': 'Adebayo Johnson',
    'phone': '08137954069',
    'email': 'adebayo.johnson@mail.com',
    'gender': 'Male',
    'dateOfBirth': '15th Feb, 1995',
  };

  @override
  void initState() {
    super.initState();

    // Initialize controllers with original data
    _nameController.text = _originalData['fullName'] ?? '';
    _emailController.text = _originalData['email'] ?? '';

    // Main animation controller
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Edit mode animation controller
    _editAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Profile image animation controller
    _profileImageController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _editAnimationController,
      curve: Curves.elasticOut,
    ));

    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _editAnimationController.dispose();
    _profileImageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  List<ProfileSection> get _profileSections => [
        ProfileSection(
          icon: Icons.phone,
          iconColor: Colors.green[600]!,
          bgColor: Colors.green[50]!,
          title: 'PHONE NUMBER',
          value: _originalData['phone']!,
          subtitle: "This is your registered number can't be changed. Others find you by this number.",
          editable: false,
        ),
        ProfileSection(
          icon: Icons.email,
          iconColor: Colors.purple[600]!,
          bgColor: Colors.purple[50]!,
          title: 'EMAIL ADDRESS',
          value: _isEditing ? _emailController.text : _originalData['email']!,
          editable: true,
          field: 'email',
        ),
        ProfileSection(
          icon: Icons.person,
          iconColor: Colors.blue[600]!,
          bgColor: Colors.blue[50]!,
          title: 'GENDER',
          value: _originalData['gender']!,
          editable: false,
        ),
        ProfileSection(
          icon: Icons.calendar_today,
          iconColor: Colors.pink[600]!,
          bgColor: Colors.pink[50]!,
          title: 'DATE OF BIRTH',
          value: _originalData['dateOfBirth']!,
          editable: false,
        ),
      ];

  TierInfo get _currentTier => TierInfo(
        level: 'tier1',
        name: 'Gold Tier',
        balanceLimit: '₦500,000',
        transactionLimit: '₦100,000',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Custom App Bar
              _buildSliverAppBar(),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Profile Header
                          _buildProfileHeader(),
                          const SizedBox(height: 16),

                          // Account Tier Card
                          _buildAccountTierCard(),
                          const SizedBox(height: 16),

                          // Profile Information Sections
                          _buildProfileSections(),
                          const SizedBox(height: 24),

                          // Edit Profile Button
                          _buildEditProfileButton(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Image Options Modal
          if (_showImageOptions) _buildImageOptionsModal(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () {}),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            "assets/images/AppIcon.png",
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      actions: const [
        SizedBox(width: 56), // Spacer for center alignment
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Image with Edit Option
        GestureDetector(
          onTap: _isEditing ? _handleImageChange : null,
          child: Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B252), Color(0xFF00A047)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B252).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: _profileImage != null
                        ? Image.file(
                            File(_profileImage!),
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00B252), Color(0xFF00A047)],
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: AnimatedScale(
                    scale: _isEditing ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B252),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Name Field (Editable)
        if (_isEditing)
          SizedBox(
            width: 200,
            child: TextFormField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00B252), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          )
        else
          Text(
            _nameController.text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

        const SizedBox(height: 8),

        // Phone Number (Read-only)
        Text(
          _originalData['phone']!,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTierCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.pushNamed("tiers");
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTierColor().withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTierIcon(),
                    color: _getTierColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT TIER',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentTier.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_currentTier.balanceLimit} balance • ${_currentTier.transactionLimit} per txn',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSections() {
    return Column(
      children: _profileSections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: section.bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    section.icon,
                    color: section.iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Editable Email Field
                      if (_isEditing && section.editable && section.field == 'email')
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00B252)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00B252)),
                            ),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        )
                      else
                        Text(
                          section.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                      if (section.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          section.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditProfileButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: !_isEditing
          ? SizedBox(
              key: const ValueKey('edit'),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _startEditing,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Row(
              key: const ValueKey('save-cancel'),
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B252),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

  Widget _buildImageOptionsModal() {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: () => setState(() => _showImageOptions = false),
        child: Container(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Take Photo
                _buildImageOption(
                  icon: Icons.camera_alt,
                  title: 'Take Photo',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 12),

                // Choose from Gallery
                _buildImageOption(
                  icon: Icons.photo_library,
                  title: 'Choose from Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),

                // Remove Photo (only if there's a custom image)
                if (_profileImage != null) ...[
                  const SizedBox(height: 12),
                  _buildImageOption(
                    icon: Icons.delete,
                    title: 'Remove Photo',
                    onTap: _removeImage,
                    isDestructive: true,
                  ),
                ],

                const SizedBox(height: 12),

                // Cancel
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => setState(() => _showImageOptions = false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isDestructive ? Colors.red[50] : Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.black87,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  IconData _getTierIcon() {
    switch (_currentTier.level) {
      case 'tier0':
        return Icons.person;
      case 'tier1':
        return Icons.star;
      case 'tier2':
        return Icons.shield;
      case 'tier3':
        return Icons.shield;
      default:
        return Icons.star;
    }
  }

  Color _getTierColor() {
    switch (_currentTier.level) {
      case 'tier0':
        return Colors.amber;
      case 'tier1':
        return const Color(0xFF00B252);
      case 'tier2':
        return Colors.blue;
      case 'tier3':
        return Colors.purple;
      default:
        return const Color(0xFF00B252);
    }
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _editAnimationController.forward();
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _showImageOptions = false;
      _nameController.text = _originalData['fullName']!;
      _emailController.text = _originalData['email']!;
      _profileImage = null;
    });
    _editAnimationController.reverse();
  }

  void _saveChanges() {
    // Here you would typically save to your backend/storage
    print('Saving changes:');
    print('Name: ${_nameController.text}');
    print('Email: ${_emailController.text}');
    print('Profile Image: $_profileImage');

    setState(() => _isEditing = false);
    _editAnimationController.reverse();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  void _handleImageChange() {
    setState(() => _showImageOptions = true);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _profileImage = image.path;
          _showImageOptions = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
      _showImageOptions = false;
    });
  }
}

// Data Models
class ProfileSection {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String value;
  final String? subtitle;
  final bool editable;
  final String? field;

  ProfileSection({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.value,
    this.subtitle,
    this.editable = false,
    this.field,
  });
}

class TierInfo {
  final String level;
  final String name;
  final String balanceLimit;
  final String transactionLimit;

  TierInfo({
    required this.level,
    required this.name,
    required this.balanceLimit,
    required this.transactionLimit,
  });
}

// Crown Icon Widget (since it's not in default Material Icons)
class CrownIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CrownIcon({super.key, this.size = 24, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.emoji_events, // Using trophy as crown alternative
      size: size,
      color: color,
    );
  }
}
