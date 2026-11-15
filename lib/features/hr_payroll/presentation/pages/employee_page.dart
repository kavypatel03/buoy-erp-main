import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/erp_input_field.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/employee_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String phone;
  final bool isIn;
  final String role;
  final String joinDate;
  final String hourlySalary;
  final String work;
  final String address;
  final String attendanceHours;
  final String payableSalary;
  final String upiId;
  final List<dynamic> salaryPayments;
  final Color avatarBgColor;
  final String? profilePicUrl;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.isIn,
    required this.role,
    required this.joinDate,
    required this.hourlySalary,
    required this.work,
    required this.address,
    required this.attendanceHours,
    required this.payableSalary,
    required this.upiId,
    required this.salaryPayments,
    required this.avatarBgColor,
    this.profilePicUrl,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      isIn: json['is_clocked_in'] ?? false,
      role: json['role'] ?? 'Worker',
      joinDate: json['created_at'] != null 
          ? json['created_at'].toString().split('T')[0] 
          : 'Unknown',
      hourlySalary: json['hourly_salary']?.toString() ?? '0',
      work: json['role'] ?? 'Worker',
      address: json['address'] ?? '',
      attendanceHours: json['total_hours']?.toString() ?? '0',
      payableSalary: json['payable_salary']?.toString() ?? '0',
      upiId: json['upi_id'] ?? '',
      salaryPayments: json['salary_payments'] ?? [],
      avatarBgColor: const Color(0xFF6366F1),
      profilePicUrl: json['profile_pic_url'],
    );
  }
}

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => EmployeePageState();
}

class EmployeePageState extends State<EmployeePage> {
  int _currentSubIndex = 0; // 0: List, 1: Add New, 2: Details, 3: Edit
  String _selectedFilter = 'All Employee';
  EmployeeModel? _selectedEmployee;

  bool _isLoading = false;
  List<EmployeeModel> _employees = [];

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    final isFirstLoad = _employees.isEmpty;
    if (isFirstLoad && mounted) setState(() => _isLoading = true);
    final res = await EmployeeService.getEmployees();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      final List<dynamic> data = res['data'];
      setState(() {
        _employees = data.map((e) => EmployeeModel.fromJson(e)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch employees: ${res['error']}')),
      );
    }
  }

  bool get hasSubScreen => _currentSubIndex > 0;

  void popSubScreen() {
    if (_currentSubIndex > 0) {
      setState(() {
        _currentSubIndex = 0;
        _selectedEmployee = null;
      });
      _fetchEmployees();
    }
  }

  void goToAddNewEmployee() {
    setState(() {
      _currentSubIndex = 1;
      _selectedImage = null;
    });
  }

  void _onSelectEmployee(EmployeeModel employee) {
    setState(() {
      _selectedEmployee = employee;
      _currentSubIndex = 2;
    });
  }

  void _onBackToList() {
    setState(() {
      _currentSubIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentSubIndex) {
      case 1:
        return _buildAddNewEmployeeScreen();
      case 2:
        return _buildEmployeeDetailsScreen();
      case 3:
        return _buildEditEmployeeScreen();
      default:
        return _buildEmployeeListScreen();
    }
  }

  // ─── Screen: Employees List ────────────────────────────────────────────────
  Widget _buildEmployeeListScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredList = _employees.where((emp) {
      if (_selectedFilter == 'Available') return emp.isIn;
      if (_selectedFilter == 'Unavailable') return !emp.isIn;
      return true;
    }).toList();

    final clockedInCount = _employees.where((e) => e.isIn).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ErpHeaderBar(
              title: 'Employees',
              trailing: Row(
                children: [
                  GestureDetector(
                    onTap: goToAddNewEmployee,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // Summary stats strip
            if (!_isLoading && _employees.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    _buildStatPill('$clockedInCount On Duty', AppColors.success, isDark),
                    const SizedBox(width: 8),
                    _buildStatPill('${_employees.length - clockedInCount} Off Duty', AppColors.textSecondary, isDark),
                    const SizedBox(width: 8),
                    _buildStatPill('${_employees.length} Total', AppColors.primary, isDark),
                  ],
                ),
              ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildFilterChip('All Employee'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Available'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unavailable'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filteredList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(Icons.people_outline_rounded, color: AppColors.primary, size: 36),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No employees found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add your staff to track attendance and payroll.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _fetchEmployees,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final emp = filteredList[index];
                              return RepaintBoundary(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: GlassContainer(
                                    borderRadius: 20,
                                    onTap: () => _onSelectEmployee(emp),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          _buildAvatar(emp, 48),
                                          const SizedBox(width: 14),
                                          // Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  emp.name,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Text(
                                                      emp.role,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textSecondary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (emp.phone.isNotEmpty) ...[
                                                      const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                                                      Text(
                                                        emp.phone,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Status Badge (In / Out)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: emp.isIn
                                                  ? (isDark ? AppColors.darkSuccessBg : AppColors.successBg)
                                                  : (isDark ? AppColors.darkErrorBg : AppColors.errorBg),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: emp.isIn ? AppColors.success : AppColors.error,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  emp.isIn ? 'Clocked In' : 'Clocked Out',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: emp.isIn ? AppColors.success : AppColors.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkCardBorder : AppColors.border),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // ─── Screen: Add New Employee ──────────────────────────────────────────────
  Widget _buildAddNewEmployeeScreen() {
    final nameCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final workCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final upiCtrl = TextEditingController();
    bool isSaving = false;

    Future<void> pickImage(ImageSource source) async {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    }

    void showImageSourceSelector() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 85.0),
              child: Column(
                children: [
                  ErpHeaderBar(
                    title: 'New Employee',
                    onBackTap: _onBackToList,
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GlassContainer(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          // Photo upload circular button
                          GestureDetector(
                            onTap: showImageSourceSelector,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkCardBorder : AppColors.border,
                                      width: 2,
                                    ),
                                    image: _selectedImage != null
                                        ? DecorationImage(
                                            image: FileImage(_selectedImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _selectedImage == null
                                      ? const Icon(
                                          Icons.person_add_rounded,
                                          color: AppColors.textMuted,
                                          size: 38,
                                        )
                                      : null,
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Tap to add photo",
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),

                          const SizedBox(height: 22),

                          ErpInputField(
                            label: 'Full Name *',
                            hintText: 'e.g. Ramesh Sharma',
                            controller: nameCtrl,
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'Hourly Salary (INR) *',
                            hintText: 'e.g. 120',
                            controller: salaryCtrl,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.currency_rupee_rounded,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'Mobile Number',
                            hintText: 'e.g. 9876543210',
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'Role / Designation',
                            hintText: 'e.g. Machine Operator, Assembly',
                            controller: workCtrl,
                            prefixIcon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'Residential Address',
                            hintText: 'e.g. Plot 42, GIDC Industrial Estate',
                            controller: addressCtrl,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'UPI ID for Salary Payments',
                            hintText: 'e.g. ramesh@okaxis',
                            controller: upiCtrl,
                            prefixIcon: Icons.payment_outlined,
                          ),
                          const SizedBox(height: 26),

                          isSaving
                              ? const CircularProgressIndicator(color: AppColors.primary)
                              : CustomButton(
                                  text: 'Create Employee Profile',
                                  onPressed: () async {
                                    if (nameCtrl.text.trim().isEmpty || salaryCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Name and Hourly Salary are required')),
                                      );
                                      return;
                                    }

                                    setLocalState(() => isSaving = true);
                                    String? base64Image;
                                    if (_selectedImage != null) {
                                      final bytes = await _selectedImage!.readAsBytes();
                                      base64Image = base64Encode(bytes);
                                    }

                                    final res = await EmployeeService.createEmployee({
                                      'name': nameCtrl.text.trim(),
                                      'hourly_salary': double.tryParse(salaryCtrl.text.trim()) ?? 0,
                                      'phone': phoneCtrl.text.trim(),
                                      'role': workCtrl.text.trim().isEmpty ? 'Worker' : workCtrl.text.trim(),
                                      'address': addressCtrl.text.trim(),
                                      'upi_id': upiCtrl.text.trim(),
                                      'profile_pic_url': base64Image ?? '',
                                    });

                                    setLocalState(() => isSaving = false);

                                    if (res['success']) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('New Employee Added Successfully!')),
                                      );
                                      _fetchEmployees();
                                      _onBackToList();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed: ${res['error']}')),
                                      );
                                    }
                                  },
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
      },
    );
  }

  // ─── Screen: Edit Employee ─────────────────────────────────────────────────
  Widget _buildEditEmployeeScreen() {
    if (_selectedEmployee == null) return const SizedBox();
    final emp = _selectedEmployee!;

    final nameCtrl = TextEditingController(text: emp.name);
    final salaryCtrl = TextEditingController(text: emp.hourlySalary);
    final phoneCtrl = TextEditingController(text: emp.phone);
    final workCtrl = TextEditingController(text: emp.role);
    final addressCtrl = TextEditingController(text: emp.address);
    final upiCtrl = TextEditingController(text: emp.upiId);
    bool isSaving = false;

    Future<void> pickImage(ImageSource source) async {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    }

    void showImageSourceSelector() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                  title: const Text('Photo Library'),
                  onTap: () {
                    Navigator.of(context).pop();
                    pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 85.0),
              child: Column(
                children: [
                  ErpHeaderBar(
                    title: 'Edit Employee',
                    onBackTap: () => setState(() => _currentSubIndex = 2),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GlassContainer(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: showImageSourceSelector,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkCardBorder : AppColors.border,
                                      width: 2,
                                    ),
                                    image: _selectedImage != null
                                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                        : (emp.profilePicUrl != null && emp.profilePicUrl!.isNotEmpty
                                            ? DecorationImage(
                                                image: MemoryImage(base64Decode(emp.profilePicUrl!)),
                                                fit: BoxFit.cover,
                                              )
                                            : null),
                                  ),
                                  child: (_selectedImage == null && (emp.profilePicUrl == null || emp.profilePicUrl!.isEmpty))
                                      ? const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 40)
                                      : null,
                                ),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text("Tap to change photo", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),

                          const SizedBox(height: 22),

                          ErpInputField(
                            label: 'Full Name *',
                            hintText: 'Enter Name',
                            controller: nameCtrl,
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'Hourly Salary (INR) *',
                            hintText: 'Hourly salary',
                            controller: salaryCtrl,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.currency_rupee_rounded,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'Mobile Number',
                            hintText: 'Mobile Number',
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'Role / Designation',
                            hintText: 'Employee role',
                            controller: workCtrl,
                            prefixIcon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'Address',
                            hintText: 'Full address',
                            controller: addressCtrl,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          ErpInputField(
                            label: 'UPI ID',
                            hintText: 'UPI ID (optional)',
                            controller: upiCtrl,
                            prefixIcon: Icons.payment_outlined,
                          ),
                          const SizedBox(height: 26),

                          isSaving
                              ? const CircularProgressIndicator(color: AppColors.primary)
                              : CustomButton(
                                  text: 'Save Changes',
                                  onPressed: () async {
                                    if (nameCtrl.text.trim().isEmpty || salaryCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Name and Salary are required')),
                                      );
                                      return;
                                    }

                                    setLocalState(() => isSaving = true);
                                    String? base64Image = emp.profilePicUrl;
                                    if (_selectedImage != null) {
                                      final bytes = await _selectedImage!.readAsBytes();
                                      base64Image = base64Encode(bytes);
                                    }

                                    final res = await EmployeeService.editEmployee(emp.id, {
                                      'name': nameCtrl.text.trim(),
                                      'hourly_salary': double.tryParse(salaryCtrl.text.trim()) ?? 0,
                                      'phone': phoneCtrl.text.trim(),
                                      'role': workCtrl.text.trim(),
                                      'address': addressCtrl.text.trim(),
                                      'upi_id': upiCtrl.text.trim(),
                                      'profile_pic_url': base64Image ?? '',
                                    });

                                    setLocalState(() => isSaving = false);

                                    if (res['success']) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Employee Updated Successfully!')),
                                      );
                                      await _fetchEmployees();
                                      final updated = _employees.firstWhere((e) => e.id == emp.id, orElse: () => emp);
                                      setState(() {
                                        _selectedEmployee = updated;
                                        _currentSubIndex = 2; // return to details
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed: ${res['error']}')),
                                      );
                                    }
                                  },
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
      },
    );
  }

  // ─── Screen: Employee Details ──────────────────────────────────────────────
  Widget _buildEmployeeDetailsScreen() {
    if (_selectedEmployee == null) return const SizedBox();
    final emp = _selectedEmployee!;
    bool isProcessing = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final payable = double.tryParse(emp.payableSalary) ?? 0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.only(bottom: 85.0),
              child: Column(
                children: [
                  ErpHeaderBar(
                    title: 'Employee Details',
                    onBackTap: _onBackToList,
                    trailing: GlassContainer(
                      width: 44,
                      height: 44,
                      isCircle: true,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isDark ? AppColors.darkCard : Colors.white,
                        onSelected: (value) async {
                          if (value == 'edit') {
                            setState(() => _currentSubIndex = 3);
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Employee?'),
                                content: Text('Permanently delete ${emp.name}? This action cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              setLocalState(() => isProcessing = true);
                              final res = await EmployeeService.deleteEmployee(emp.id);
                              setLocalState(() => isProcessing = false);
                              if (res['success']) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee deleted')));
                                await _fetchEmployees();
                                _onBackToList();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res['error']}')));
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Profile'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Hero Profile Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GlassContainer(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAvatar(emp, 76),
                          const SizedBox(height: 12),
                          Text(
                            emp.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            emp.role,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Present / Absent Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: emp.isIn
                                  ? (isDark ? AppColors.darkSuccessBg : AppColors.successBg)
                                  : (isDark ? AppColors.darkErrorBg : AppColors.errorBg),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: emp.isIn ? AppColors.success : AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  emp.isIn ? 'Present on Floor' : 'Clocked Out',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: emp.isIn ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),
                          Divider(color: isDark ? AppColors.darkDivider : AppColors.border, height: 1),
                          const SizedBox(height: 18),

                          // Details Key-Value Table
                          _buildDetailRow('Mobile Number', emp.phone.isNotEmpty ? emp.phone : 'Not provided'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Join Date', emp.joinDate),
                          const SizedBox(height: 12),
                          _buildDetailRow('Rate', '₹${emp.hourlySalary} / hour'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Work Role', emp.work),
                          const SizedBox(height: 12),
                          _buildDetailRow('Address', emp.address.isNotEmpty ? emp.address : '—'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Hours Logged', '${emp.attendanceHours} hrs'),
                          const SizedBox(height: 14),

                          // Payable Highlight Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF063320) : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF047857) : const Color(0xFFA7F3D0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Outstanding Salary', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    SizedBox(height: 2),
                                    Text('Ready for payout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                                  ],
                                ),
                                Text(
                                  '₹${emp.payableSalary}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Actions (Clock In / Clock Out)
                          if (isProcessing)
                            const CircularProgressIndicator(color: AppColors.primary)
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: emp.isIn ? null : () async {
                                          TimeOfDay? customTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                            helpText: 'Select Clock In Time (Cancel for Now)',
                                          );
                                          
                                          DateTime? finalTime;
                                          if (customTime != null) {
                                            final now = DateTime.now();
                                            finalTime = DateTime(now.year, now.month, now.day, customTime.hour, customTime.minute);
                                          }

                                          setLocalState(() => isProcessing = true);
                                          final res = await EmployeeService.clockIn(emp.id, time: finalTime);
                                          setLocalState(() => isProcessing = false);
                                          if (res['success']) {
                                            HapticFeedback.lightImpact();
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked in successfully')));
                                            await _fetchEmployees();
                                            _onBackToList();
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Error')));
                                          }
                                        },
                                        icon: const Icon(Icons.login_rounded, size: 18),
                                        label: const Text('Clock In'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: !emp.isIn ? null : () async {
                                          TimeOfDay? customTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                            helpText: 'Select Clock Out Time (Cancel for Now)',
                                          );
                                          
                                          DateTime? finalTime;
                                          if (customTime != null) {
                                            final now = DateTime.now();
                                            finalTime = DateTime(now.year, now.month, now.day, customTime.hour, customTime.minute);
                                          }

                                          setLocalState(() => isProcessing = true);
                                          final res = await EmployeeService.clockOut(emp.id, time: finalTime);
                                          setLocalState(() => isProcessing = false);
                                          if (res['success']) {
                                            HapticFeedback.lightImpact();
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked out successfully')));
                                            await _fetchEmployees();
                                            _onBackToList();
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Error')));
                                          }
                                        },
                                        icon: const Icon(Icons.logout_rounded, size: 18),
                                        label: const Text('Clock Out'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Payout buttons
                                if (payable > 0)
                                  Row(
                                    children: [
                                      if (emp.upiId.isNotEmpty)
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _handlePayment(
                                              emp,
                                              'UPI',
                                              setLocalState,
                                              (val) => setLocalState(() => isProcessing = val),
                                            ),
                                            icon: const Icon(Icons.qr_code_rounded, size: 18),
                                            label: const Text('Pay UPI'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                          ),
                                        ),
                                      if (emp.upiId.isNotEmpty) const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _handlePayment(
                                            emp,
                                            'Cash',
                                            setLocalState,
                                            (val) => setLocalState(() => isProcessing = val),
                                          ),
                                          icon: const Icon(Icons.payments_outlined, size: 18),
                                          label: const Text('Pay Cash'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF59E0B),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Payment History List
                  if (emp.salaryPayments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Payment History",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: emp.salaryPayments.length,
                      itemBuilder: (ctx, i) {
                        final payment = emp.salaryPayments[i];
                        final method = payment['payment_method']?.toString() ?? 'Cash';
                        final isUPI = method == 'UPI';

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkCardBorder : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isUPI
                                          ? AppColors.primary.withValues(alpha: 0.12)
                                          : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isUPI ? Icons.qr_code_rounded : Icons.payments_outlined,
                                      color: isUPI ? AppColors.primary : const Color(0xFFF59E0B),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹${payment['amount']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        payment['paid_at'] != null
                                            ? payment['paid_at'].toString().split('T')[0]
                                            : '',
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isUPI
                                      ? AppColors.primary.withValues(alpha: 0.1)
                                      : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  method,
                                  style: TextStyle(
                                    color: isUPI ? AppColors.primary : const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _buildAvatar(EmployeeModel emp, double size) {
    final hasImage = emp.profilePicUrl != null && emp.profilePicUrl!.isNotEmpty;
    final initials = emp.name.isNotEmpty
        ? emp.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'E';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: emp.avatarBgColor,
        shape: BoxShape.circle,
        image: hasImage
            ? DecorationImage(
                image: MemoryImage(base64Decode(emp.profilePicUrl!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.38,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayment(
    EmployeeModel emp,
    String method,
    StateSetter setLocalState,
    void Function(bool) setProcessing,
  ) async {
    double amount = double.tryParse(emp.payableSalary) ?? 0;

    if (method == 'UPI') {
      final url = 'upi://pay?pa=${emp.upiId}&pn=${Uri.encodeComponent(emp.name)}&am=$amount&cu=INR';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No UPI app found on this device.')),
          );
        }
      }
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm $method Payment'),
        content: Text('Confirm salary payout of ₹$amount to ${emp.name} via $method?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Yes, Paid', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setProcessing(true);
      final res = await EmployeeService.paySalary(emp.id, amount, method);
      setProcessing(false);

      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment logged successfully!')));
        await _fetchEmployees();
        final updated = _employees.firstWhere((e) => e.id == emp.id, orElse: () => emp);
        setState(() {
          _selectedEmployee = updated;
          _currentSubIndex = 2;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res['error']}')));
      }
    }
  }
}
