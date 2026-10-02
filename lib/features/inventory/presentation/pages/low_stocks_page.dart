import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/erp_input_field.dart';

class InventoryItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String metric;
  final String unit;
  final Color metricColor;
  final IconData icon;
  final Color iconBgColor;
  final String itemCode;
  final String type;
  final String category;
  final String stockQuantity;
  final String minQuantity;
  final String description;

  InventoryItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.unit,
    required this.metricColor,
    required this.icon,
    required this.iconBgColor,
    required this.itemCode,
    required this.type,
    required this.category,
    required this.stockQuantity,
    required this.minQuantity,
    required this.description,
  });
}

class LowStocksPage extends StatefulWidget {
  const LowStocksPage({super.key});

  @override
  State<LowStocksPage> createState() => LowStocksPageState();
}

class LowStocksPageState extends State<LowStocksPage> {
  int _currentSubIndex = 0; // 0: List, 1: Details, 2: Add New Item
  String _selectedCategory = 'All Items';
  InventoryItemModel? _selectedItem;

  bool get hasSubScreen => _currentSubIndex > 0;

  void popSubScreen() {
    if (_currentSubIndex > 0) {
      setState(() {
        _currentSubIndex = 0;
      });
    }
  }

  void goToAddNewItem() {
    setState(() {
      _currentSubIndex = 2;
    });
  }

  final List<InventoryItemModel> _inventoryItems = [
    InventoryItemModel(
      id: '1',
      title: 'Brown Paper roll',
      subtitle: '150 GSM',
      metric: '250',
      unit: 'Kg',
      metricColor: const Color(0xFF00B039),
      icon: Icons.description_rounded,
      iconBgColor: const Color(0xFFFEF3C7),
      itemCode: 'BP-0112',
      type: 'Raw Material',
      category: 'Papers',
      stockQuantity: '250',
      minQuantity: '100',
      description: 'Heavy duty brown craft paper rolls for packaging & box lining.',
    ),
    InventoryItemModel(
      id: '2',
      title: 'Black Graphite',
      subtitle: 'Synthetic',
      metric: '150',
      unit: 'Kg',
      metricColor: const Color(0xFFF59E0B),
      icon: Icons.grain_rounded,
      iconBgColor: const Color(0xFFE0E7FF),
      itemCode: 'BG-0623',
      type: 'Synthetic',
      category: 'Graphite Lead',
      stockQuantity: '175',
      minQuantity: '50',
      description: 'High Quality Synthetic Graphite used in manufacturing process of lead making',
    ),
    InventoryItemModel(
      id: '3',
      title: 'White Paper roll',
      subtitle: '150 GSM',
      metric: '25',
      unit: 'Kg',
      metricColor: const Color(0xFFFF334B),
      icon: Icons.receipt_long_rounded,
      iconBgColor: const Color(0xFFF1F5F9),
      itemCode: 'WP-0881',
      type: 'Raw Material',
      category: 'Papers',
      stockQuantity: '25',
      minQuantity: '100',
      description: 'Premium bleached white paper rolls for printing & label wrapping.',
    ),
    InventoryItemModel(
      id: '4',
      title: 'B-7000 Glue',
      subtitle: 'Grey',
      metric: '200',
      unit: 'Kg',
      metricColor: const Color(0xFF00B039),
      icon: Icons.science_rounded,
      iconBgColor: const Color(0xFFFEE2E2),
      itemCode: 'GL-9902',
      type: 'Adhesive',
      category: 'Chemicals',
      stockQuantity: '200',
      minQuantity: '50',
      description: 'Industrial multi-purpose epoxy adhesive liquid for high bonding.',
    ),
    InventoryItemModel(
      id: '5',
      title: 'Opus Color',
      subtitle: 'Dark-Brown',
      metric: '50',
      unit: 'Liter',
      metricColor: const Color(0xFFF59E0B),
      icon: Icons.color_lens_rounded,
      iconBgColor: const Color(0xFFE0F2FE),
      itemCode: 'OC-4410',
      type: 'Pigment Liquid',
      category: 'Colors',
      stockQuantity: '50',
      minQuantity: '30',
      description: 'Concentrated dark-brown pigment solution for paper dye processing.',
    ),
  ];

  void _onSelectItem(InventoryItemModel item) {
    setState(() {
      _selectedItem = item;
      _currentSubIndex = 1;
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
        return _buildItemDetailsScreen();
      case 2:
        return _buildAddNewItemScreen();
      default:
        return _buildInventoryListScreen();
    }
  }

  // ---------------------------------------------------------------------------
  // SCREEN 2.1: INVENTORY ITEMS LIST
  // ---------------------------------------------------------------------------
  Widget _buildInventoryListScreen() {
    final filteredList = _inventoryItems.where((item) {
      if (_selectedCategory == 'Papers') return item.category == 'Papers';
      if (_selectedCategory == 'Leads') return item.category == 'Graphite Lead';
      if (_selectedCategory == 'Colors') return item.category == 'Colors';
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
              const ErpHeaderBar(title: 'Inventory'),

              const SizedBox(height: 8),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    _buildCategoryChip('All Items'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Papers'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Leads'),
                    const SizedBox(width: 8),
                    _buildCategoryChip('Colors'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Main List Container Card with + button inside at bottom-right
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
                        final item = entry.value;
                        final isLast = idx == filteredList.length - 1;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () => _onSelectItem(item),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
                                child: Row(
                                  children: [
                                    // Image Thumbnail Container
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: item.iconBgColor,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          item.icon,
                                          color: const Color(0xFF475569),
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Metric Stock Value
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          item.metric,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: item.metricColor,
                                          ),
                                        ),
                                        Text(
                                          item.unit,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: item.metricColor,
                                          ),
                                        ),
                                      ],
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

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
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
  // SCREEN 2.2: INVENTORY ITEM DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildItemDetailsScreen() {
    final item = _selectedItem ?? _inventoryItems[1];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              ErpHeaderBar(
                title: 'Inventory',
                onBackTap: _onBackToList,
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GlassContainer(
                  useGradientBorder: true,
                  borderRadius: 26,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Hero Image Block
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(color: const Color(0xFF334155)),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item.icon, size: 54, color: const Color(0xFF94A3B8)),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title & In Stock Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'In Stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Grid Table
                      _buildInfoRow('Item Code', item.itemCode),
                      const SizedBox(height: 12),
                      _buildInfoRow('Type', item.type),
                      const SizedBox(height: 12),
                      _buildInfoRow('Category', item.category),
                      const SizedBox(height: 12),
                      _buildInfoRow('Unit', item.unit),
                      const SizedBox(height: 12),
                      _buildInfoRow('Stock Quantity', item.stockQuantity),
                      const SizedBox(height: 12),
                      _buildInfoRow('Minimum Quantity', item.minQuantity),

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
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

  Widget _buildInfoRow(String key, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          val,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 2.3: ADD NEW ITEM
  // ---------------------------------------------------------------------------
  Widget _buildAddNewItemScreen() {
    final nameCtrl = TextEditingController();
    final minQtyCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 85.0),
          child: Column(
            children: [
              ErpHeaderBar(
                title: 'New Item',
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
                      // Upload Item Image Preview
                      const Text(
                        'Item Image',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, color: Color(0xFF64748B), size: 28),
                            SizedBox(height: 2),
                            Text(
                              'Preview\n(Only .jpg,.png)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Upload Image',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5B3DF5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Item Name
                      ErpInputField(
                        label: 'Item Name',
                        hintText: 'Enter Name of Item',
                        controller: nameCtrl,
                      ),
                      const SizedBox(height: 14),

                      // Item Category Dropdown
                      _buildDropdownField('Item category', 'Select Item Category'),
                      const SizedBox(height: 14),

                      // Item Volume Dropdown
                      _buildDropdownField('Item Volume', 'Select Item Volume'),
                      const SizedBox(height: 14),

                      // Minimum Quantity
                      ErpInputField(
                        label: 'Minimum Quantity',
                        hintText: 'Enter Minimum Quantity',
                        controller: minQtyCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),

                      // Description
                      ErpInputField(
                        label: 'Description',
                        hintText: 'Write note as your need',
                        controller: descCtrl,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      CustomButton(
                        text: 'Add New Item',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New Item Added Successfully!')),
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

  Widget _buildDropdownField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hint,
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ],
    );
  }
}
