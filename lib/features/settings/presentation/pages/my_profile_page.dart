import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/erp_input_field.dart';
import '../../../../core/widgets/erp_input_field.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/profile_service.dart';

class MyProfilePage extends StatefulWidget {
  final VoidCallback? onBack;

  const MyProfilePage({
    super.key,
    this.onBack,
  });

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _occupationController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ProfileService.getProfile();
    if (result['success'] && mounted) {
      final data = result['data'];
      setState(() {
        _firstNameController.text = data['first_name'] ?? '';
        _middleNameController.text = data['middle_name'] ?? '';
        _surnameController.text = data['surname'] ?? '';
        _mobileController.text = data['mobile'] ?? '';
        _emailController.text = data['email'] ?? '';
        _occupationController.text = data['occupation'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    final result = await ProfileService.updateProfile({
      'first_name': _firstNameController.text,
      'middle_name': _middleNameController.text,
      'surname': _surnameController.text,
      'mobile': _mobileController.text,
      'occupation': _occupationController.text,
    });
    
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated Successfully!')),
      );
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'].toString())),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _surnameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              // Header with Back arrow support
              ErpHeaderBar(
                title: 'My Profile',
                onBackTap: widget.onBack ?? () => Navigator.pop(context),
              ),

              const SizedBox(height: 16),

              // Edit Profile Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  useGradientBorder: true,
                  borderRadius: 26,
                  padding: const EdgeInsets.all(22),
                  child: _isLoading 
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      const Text(
                        'Edit Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Avatar Illustration & Upload Image Link
                      Column(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD600),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFCD34D),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Icon(
                                  Icons.account_circle_rounded,
                                  size: 74,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'Upload Image',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5B3DF5),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Full Name Section (No Truncation Fix)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildNoTruncateField(_firstNameController, 'First Name'),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildNoTruncateField(_middleNameController, 'Middle Name'),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildNoTruncateField(_surnameController, 'Surname'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Mobile No.
                      ErpInputField(
                        label: 'Mobile No.',
                        hintText: '+91-00500-00000',
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      // Email
                      ErpInputField(
                        label: 'Email',
                        hintText: 'admin@factory.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      // Occupation
                      ErpInputField(
                        label: 'Occupation',
                        hintText: 'Enter Your Position in Company',
                        controller: _occupationController,
                      ),

                      const SizedBox(height: 24),

                      // Update Profile Button
                      CustomButton(
                        text: _isSaving ? 'Updating...' : 'Update Profile',
                        onPressed: _isSaving ? () {} : _updateProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoTruncateField(TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}
