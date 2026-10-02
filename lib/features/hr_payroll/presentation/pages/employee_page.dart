import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/erp_input_field.dart';
import '../../../../core/widgets/glass_container.dart';

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
  });
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
    });
  }

  final List<EmployeeModel> _employees = [
    EmployeeModel(
      id: '1',
      name: 'Mahesh Gupta',
      phone: '+91-11111-11111',
      isIn: true,
      role: 'Worker',
      joinDate: '21 June 2025',
      hourlySalary: '800',
      work: 'Paper rolling',
      address: 'Ahmedabad',
      attendanceHours: '100 Hours',
      payableSalary: '8000/- INR',
      avatarBgColor: const Color(0xFFFCD34D),
    ),
    EmployeeModel(
      id: '2',
      name: 'Rajesh Jain',
      phone: '+91-22222-22222',
      isIn: false,
      role: 'Machine Operator',
      joinDate: '15 Jan 2024',
      hourlySalary: '950',
      work: 'Lead cutting',
      address: 'Surat',
      attendanceHours: '90 Hours',
      payableSalary: '8550/- INR',
      avatarBgColor: const Color(0xFFF87171),
    ),
    EmployeeModel(
      id: '3',
      name: 'Minal Makwana',
      phone: '+91-33333-33333',
      isIn: true,
      role: 'Quality Supervisor',
      joinDate: '10 Aug 2023',
      hourlySalary: '1100',
      work: 'Quality Audit',
      address: 'Vadodara',
      attendanceHours: '120 Hours',
      payableSalary: '13200/- INR',
      avatarBgColor: const Color(0xFF60A5FA),
    ),
    EmployeeModel(
      id: '4',
      name: 'Ketan Raina',
      phone: '+91-44444-44444',
      isIn: true,
      role: 'Packaging Lead',
      joinDate: '05 Mar 2025',
      hourlySalary: '750',
      work: 'Box Packing',
      address: 'Rajkot',
      attendanceHours: '110 Hours',
      payableSalary: '8250/- INR',
      avatarBgColor: const Color(0xFFFBBF24),
    ),
    EmployeeModel(
      id: '5',
      name: 'Riddhi Chauhan',
      phone: '+91-55555-55555',
      isIn: false,
      role: 'Inventory Helper',
      joinDate: '12 Nov 2024',
      hourlySalary: '700',
      work: 'Stock Sorting',
      address: 'Ahmedabad',
      attendanceHours: '80 Hours',
      payableSalary: '5600/- INR',
      avatarBgColor: const Color(0xFFF472B6),
    ),
  ];

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

  // ---------------------------------------------------------------------------
  // SCREEN 1.1: EMPLOYEE LIST
  // ---------------------------------------------------------------------------
  Widget _buildEmployeeListScreen() {
    final filteredList = _employees.where((emp) {
      if (_selectedFilter == 'Available') return emp.isIn;
      if (_selectedFilter == 'Unavailable') return !emp.isIn;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              const ErpHeaderBar(title: 'Employee'),

              const SizedBox(height: 8),

              // Filter Chips Row
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

              // Main Employee List Container Card with + button inside at bottom-right
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
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
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

  // ---------------------------------------------------------------------------
  // SCREEN 1.2: ADD NEW EMPLOYEE
  // ---------------------------------------------------------------------------
  Widget _buildAddNewEmployeeScreen() {
    final nameCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final workCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              ErpHeaderBar(
                title: 'Employee',
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
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCD34D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF1E3A8A),
                          size: 48,
                        ),
                      ),

                      const SizedBox(height: 20),

                      ErpInputField(
                        label: 'Employee Name',
                        hintText: 'Enter Name of Employee',
                        controller: nameCtrl,
                      ),
                      const SizedBox(height: 14),
                      ErpInputField(
                        label: 'Employee Salary (Hourly)',
                        hintText: 'Enter salary on based of One Hour',
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
                        label: 'Employee Work',
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

                      CustomButton(
                        text: 'Add New Employee',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New Employee Added Successfully!')),
                          );
                          _onBackToList();
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

  // ---------------------------------------------------------------------------
  // SCREEN 1.3: EMPLOYEE DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildEmployeeDetailsScreen() {
    final emp = _selectedEmployee ?? _employees.first;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              ErpHeaderBar(
                title: 'Employee',
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
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCD34D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF1E3A8A),
                          size: 48,
                        ),
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

                      // Present Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Present',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF137333),
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
                      _buildDetailRow('Attendance (Hours)\n(This Month Only)', emp.attendanceHours),
                      const SizedBox(height: 14),
                      _buildDetailRow(
                        'Payable Salary',
                        emp.payableSalary,
                        valueColor: const Color(0xFF00B039),
                        isBoldValue: true,
                        fontSize: 15,
                      ),

                      const SizedBox(height: 28),

                      // Action Buttons (Edit Employee & Pay Salary)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _currentSubIndex = 3;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Edit Employee',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Salary paid for ${emp.name}!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5B3DF5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Pay Salary',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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

  // ---------------------------------------------------------------------------
  // SCREEN 1.4: EDIT EMPLOYEE
  // ---------------------------------------------------------------------------
  Widget _buildEditEmployeeScreen() {
    final emp = _selectedEmployee ?? _employees.first;
    final nameCtrl = TextEditingController(text: emp.name);
    final salaryCtrl = TextEditingController(text: emp.hourlySalary);
    final phoneCtrl = TextEditingController(text: emp.phone);
    final workCtrl = TextEditingController(text: emp.work);
    final addressCtrl = TextEditingController(text: emp.address);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              ErpHeaderBar(
                title: 'Employee',
                onBackTap: () {
                  setState(() {
                    _currentSubIndex = 2;
                  });
                },
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
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFCD34D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF1E3A8A),
                          size: 48,
                        ),
                      ),

                      const SizedBox(height: 20),

                      ErpInputField(
                        label: 'Employee Name',
                        hintText: 'Mahesh Gupta',
                        controller: nameCtrl,
                      ),
                      const SizedBox(height: 14),
                      ErpInputField(
                        label: 'Employee Salary (Hourly)',
                        hintText: '800',
                        controller: salaryCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      ErpInputField(
                        label: 'Employee Mo. Number',
                        hintText: '+91-11111-11111',
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      ErpInputField(
                        label: 'Employee Work',
                        hintText: 'Paper rolling',
                        controller: workCtrl,
                      ),
                      const SizedBox(height: 14),
                      ErpInputField(
                        label: 'Employee Address',
                        hintText: 'Ahmedabad',
                        controller: addressCtrl,
                      ),
                      const SizedBox(height: 24),

                      CustomButton(
                        text: 'Update Employee',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Employee Updated Successfully!')),
                          );
                          setState(() {
                            _currentSubIndex = 2;
                          });
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
}
