import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/erp_input_field.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/services/employee_service.dart';

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
      payableSalary: json['total_salary']?.toString() ?? '0',
      avatarBgColor: const Color(0xFFFCD34D),
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
    setState(() => _isLoading = true);
    final res = await EmployeeService.getEmployees();
    setState(() => _isLoading = false);

    if (res['success']) {
      final List<dynamic> data = res['data'];
      setState(() {
        _employees = data.map((e) => EmployeeModel.fromJson(e)).toList();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch employees: ${res['error']}')),
        );
      }
    }
  }

  bool get hasSubScreen => _currentSubIndex > 0;

  void popSubScreen() {
    if (_currentSubIndex > 0) {
      setState(() {
        _currentSubIndex = 0;
      });
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

  Widget _buildEmployeeListScreen() {
    final filteredList = _employees.where((emp) {
      if (_selectedFilter == 'Available') return emp.isIn;
      if (_selectedFilter == 'Unavailable') return !emp.isIn;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Added padding to avoid overlapping with menubar
        child: FloatingActionButton(
          onPressed: goToAddNewEmployee,
          backgroundColor: const Color(0xFF5B3DF5),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              const ErpHeaderBar(title: 'Employee'),

              const SizedBox(height: 8),

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

              const SizedBox(height: 16),

              if (filteredList.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40.0),
                  child: Center(child: Text("No employees found.")),
                )
              else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  useGradientBorder: true,
                  borderRadius: 26,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    children: [
                      ...filteredList.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final emp = entry.value;
                        final isLast = idx == filteredList.length - 1;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () => _onSelectEmployee(emp),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: emp.avatarBgColor,
                                        shape: BoxShape.circle,
                                        image: emp.profilePicUrl != null && emp.profilePicUrl!.isNotEmpty
                                          ? DecorationImage(
                                              image: MemoryImage(base64Decode(emp.profilePicUrl!)),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      ),
                                      child: emp.profilePicUrl == null || emp.profilePicUrl!.isEmpty
                                      ? const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ) : null,
                                    ),
                                    const SizedBox(width: 14),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            emp.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            emp.phone,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // In / Out Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: emp.isIn ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        emp.isIn ? 'In' : 'Out',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: emp.isIn ? const Color(0xFF137333) : const Color(0xFFC5221F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast) const Divider(color: Color(0xFFF1F5F9), height: 1),
                          ],
                        );
                      }),
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B3DF5) : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5B3DF5).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewEmployeeScreen() {
    final nameCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final workCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSaving = false;

    Future<void> pickImage(ImageSource source) async {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }

    void showImageSourceSelector() {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 85.0),
              child: Column(
                children: [
                  ErpHeaderBar(
                    title: 'Add Employee',
                    onBackTap: _onBackToList,
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GlassContainer(
                      useGradientBorder: true,
                      borderRadius: 26,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: showImageSourceSelector,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                                image: _selectedImage != null
                                    ? DecorationImage(
                                        image: FileImage(_selectedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _selectedImage == null
                                  ? const Icon(
                                      Icons.camera_alt,
                                      color: Color(0xFF64748B),
                                      size: 32,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text("Tap to upload photo", style: TextStyle(fontSize: 12, color: Colors.grey)),

                          const SizedBox(height: 20),

                          ErpInputField(
                            label: 'Employee Name',
                            hintText: 'Enter Name of Employee',
                            controller: nameCtrl,
                          ),
                          const SizedBox(height: 14),
                          ErpInputField(
                            label: 'Employee Salary (Hourly)',
                            hintText: 'Enter hourly salary',
                            controller: salaryCtrl,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          ErpInputField(
                            label: 'Employee Mo. Number',
                            hintText: 'Enter Mobile Number',
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          ErpInputField(
                            label: 'Employee Role / Work',
                            hintText: 'Employee work in factory',
                            controller: workCtrl,
                          ),
                          const SizedBox(height: 14),
                          ErpInputField(
                            label: 'Employee Address',
                            hintText: 'Enter full address of Employee',
                            controller: addressCtrl,
                          ),
                          const SizedBox(height: 24),

                          isSaving ? const CircularProgressIndicator() : CustomButton(
                            text: 'Add New Employee',
                            onPressed: () async {
                              if (nameCtrl.text.isEmpty || salaryCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Name and Salary are required')),
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
                                'name': nameCtrl.text,
                                'hourly_salary': double.tryParse(salaryCtrl.text) ?? 0,
                                'phone': phoneCtrl.text,
                                'role': workCtrl.text,
                                'address': addressCtrl.text,
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
      }
    );
  }

  Widget _buildEmployeeDetailsScreen() {
    if (_selectedEmployee == null) return Container();
    final emp = _selectedEmployee!;
    bool isProcessing = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 85.0),
              child: Column(
                children: [
                  ErpHeaderBar(
                    title: 'Employee Details',
                    onBackTap: _onBackToList,
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GlassContainer(
                      useGradientBorder: true,
                      borderRadius: 26,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCD34D),
                              shape: BoxShape.circle,
                              image: emp.profilePicUrl != null && emp.profilePicUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: MemoryImage(base64Decode(emp.profilePicUrl!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: emp.profilePicUrl == null || emp.profilePicUrl!.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF1E3A8A),
                                    size: 48,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            emp.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emp.role,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Present/Out Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: emp.isIn ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              emp.isIn ? 'Present' : 'Absent',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: emp.isIn ? const Color(0xFF137333) : const Color(0xFFC5221F),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Details Key-Value Table
                          _buildDetailRow('Employee Mo. Number', emp.phone),
                          const SizedBox(height: 14),
                          _buildDetailRow('Join Date', emp.joinDate),
                          const SizedBox(height: 14),
                          _buildDetailRow('Salary Hourly', '${emp.hourlySalary}/h INR'),
                          const SizedBox(height: 14),
                          _buildDetailRow('Work', emp.work),
                          const SizedBox(height: 14),
                          _buildDetailRow('Address', emp.address),
                          const SizedBox(height: 14),
                          _buildDetailRow('Attendance (Hours)', emp.attendanceHours),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            'Payable Salary',
                            '${emp.payableSalary} INR',
                            valueColor: const Color(0xFF00B039),
                            isBoldValue: true,
                            fontSize: 15,
                          ),

                          const SizedBox(height: 28),

                          if (isProcessing)
                            const CircularProgressIndicator()
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: emp.isIn ? null : () async {
                                      setLocalState(() => isProcessing = true);
                                      final res = await EmployeeService.clockIn(emp.id);
                                      setLocalState(() => isProcessing = false);
                                      if (res['success']) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked in successfully')));
                                        _fetchEmployees();
                                        _onBackToList();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'])));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                    ),
                                    child: const Text('Clock In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: !emp.isIn ? null : () async {
                                      setLocalState(() => isProcessing = true);
                                      final res = await EmployeeService.clockOut(emp.id);
                                      setLocalState(() => isProcessing = false);
                                      if (res['success']) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clocked out successfully')));
                                        _fetchEmployees();
                                        _onBackToList();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'])));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                    ),
                                    child: const Text('Clock Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildDetailRow(
    String key,
    String value, {
    Color valueColor = const Color(0xFF0F172A),
    bool isBoldValue = false,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditEmployeeScreen() {
    return Scaffold(
      body: Center(child: Text("Edit feature coming soon")),
    );
  }
}
