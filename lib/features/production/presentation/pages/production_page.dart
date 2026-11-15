import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/services/production_service.dart';
import '../../../../core/services/inventory_service.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/erp_input_field.dart';
import '../../../../core/utils/download_helper.dart';

// ─── Status helpers ───────────────────────────────────────────────────────────

Color _statusColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'completed': return AppColors.success;
    case 'in progress': return AppColors.warning;
    case 'paused': return AppColors.info;
    default: return AppColors.textSecondary;
  }
}

Color _statusBg(String? status, bool isDark) {
  switch ((status ?? '').toLowerCase()) {
    case 'completed': return isDark ? AppColors.darkSuccessBg : AppColors.successBg;
    case 'in progress': return isDark ? AppColors.darkWarningBg : AppColors.warningBg;
    case 'paused': return isDark ? AppColors.darkInfoBg : AppColors.infoBg;
    default: return isDark ? AppColors.darkCard : AppColors.background;
  }
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => ProductionPageState();
}

class ProductionPageState extends State<ProductionPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  dynamic _wastageReport; // Map with ML summary & horizons, or fallback List
  List<dynamic> _inventoryItems = [];
  List<dynamic> _productTypes = [];
  dynamic _selectedProductType;
  String _selectedHorizon = 'by_production';

  // 0 = Orders, 1 = Order Details, 2 = Wastage Report
  int _currentSubIndex = 0;
  dynamic _selectedOrder;

  late TabController _tabController;

  // Form controllers
  final _orderNameCtrl = TextEditingController();
  final _batchCodeCtrl = TextEditingController();
  final _processNameCtrl = TextEditingController();
  final _inputQtyCtrl = TextEditingController();
  final _outputQtyCtrl = TextEditingController();
  String? _selectedItemId;

  bool get hasSubScreen => _currentSubIndex > 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
    _fetchInventory();
    _fetchProductTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderNameCtrl.dispose();
    _batchCodeCtrl.dispose();
    _processNameCtrl.dispose();
    _inputQtyCtrl.dispose();
    _outputQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInventory() async {
    final res = await InventoryService.getItems();
    if (res['success'] && mounted) {
      setState(() => _inventoryItems = res['data']);
    }
  }

  Future<void> _fetchProductTypes() async {
    final res = await ProductionService.getProductTypes();
    if (res['success'] && mounted) {
      setState(() {
        _productTypes = res['data'] ?? [];
        if (_productTypes.isNotEmpty && _selectedProductType == null) {
          _selectedProductType = _productTypes[0];
        }
      });
    }
  }

  Future<void> _fetchOrders() async {
    final isFirstLoad = _orders.isEmpty;
    if (isFirstLoad && mounted) setState(() => _isLoading = true);
    final res = await ProductionService.getOrders();
    if (mounted) {
      setState(() {
        if (res['success']) _orders = res['data'];
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWastageReport() async {
    if (mounted) setState(() => _isLoading = true);
    final res = await ProductionService.getWastageReport(horizon: _selectedHorizon);
    if (mounted) {
      setState(() {
        if (res['success'] && res['data'] != null) {
          _wastageReport = res['data'];
        } else if (!res['success'] && _wastageReport == null) {
          // Only set null if we have no prior data
          _wastageReport = null;
        }
        _isLoading = false;
      });
    }
  }

  void popSubScreen() {
    if (_currentSubIndex > 0) {
      setState(() {
        _currentSubIndex = 0;
        _selectedOrder = null;
      });
      _fetchOrders();
    }
  }

  // ─── Modals ─────────────────────────────────────────────────────────────────

  Future<void> _showAddOrderModal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _batchCodeCtrl.text = 'Batch #${_orders.length + 1}';
    if (_productTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading product types...'), duration: Duration(seconds: 1)),
      );
      await _fetchProductTypes();
      if (!mounted) return;
    }
    if (_productTypes.isNotEmpty && _selectedProductType == null) {
      _selectedProductType = _productTypes[0];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setModal) {
        final steps = (_selectedProductType?['steps'] as List?) ?? [];

        return _ThemedSheet(
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetHandle(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.precision_manufacturing_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Start Production Batch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(ctx).colorScheme.onSurface,
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Product Type Selection Dropdown (Admin-Managed)
                  Text('Select Product Type',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      )),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProductType?['id']?.toString() ?? (_productTypes.isNotEmpty ? _productTypes[0]['id']?.toString() : null),
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                        items: _productTypes.map<DropdownMenuItem<String>>((prod) {
                          final pId = prod['id']?.toString() ?? '';
                          final pName = prod['name']?.toString() ?? 'Product';
                          final pSteps = (prod['steps'] as List?)?.length ?? 0;
                          return DropdownMenuItem<String>(
                            value: pId,
                            child: Row(
                              children: [
                                Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(
                                    color: _parseColor(prod['color']),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$pSteps Steps',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModal(() {
                            _selectedProductType = _productTypes.firstWhere(
                              (p) => p['id']?.toString() == val,
                              orElse: () => _selectedProductType,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pre-defined Steps Sequence Preview
                  if (steps.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.route_rounded, size: 15, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Pre-defined Recipe (${steps.length} Stages):',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: steps.map<Widget>((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isDark ? AppColors.darkCardBorder : const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  '${s['step_number'] ?? ''}. ${s['process_name'] ?? s['name']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF334155),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Batch code / identifier
                  ErpInputField(
                    controller: _batchCodeCtrl,
                    label: 'Batch Code / Lot Number',
                    hintText: 'e.g. Batch #102',
                    prefixIcon: Icons.tag_rounded,
                  ),
                  const SizedBox(height: 20),

                  _PrimaryButton(
                    label: 'Start Production Order',
                    icon: Icons.play_circle_outline_rounded,
                    onPressed: () async {
                      final prodName = _selectedProductType?['name'] ?? 'Production Item';
                      final batch = _batchCodeCtrl.text.trim();
                      final fullName = batch.isNotEmpty ? '$prodName — $batch' : prodName;

                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      final res = await ProductionService.createOrder(
                        fullName,
                        productId: _selectedProductType?['id'],
                        batchCode: batch,
                      );
                      if (res['success']) {
                        _fetchOrders();
                      } else {
                        setState(() => _isLoading = false);
                        if (mounted) _showError(res['error'] ?? 'Failed');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  static Color _parseColor(dynamic c) {
    if (c == null) return AppColors.primary;
    final str = c.toString().replaceAll('#', '');
    try {
      if (str.length == 6) return Color(int.parse('FF$str', radix: 16));
      if (str.length == 8) return Color(int.parse(str, radix: 16));
    } catch (_) {}
    return AppColors.primary;
  }

  Future<void> _showAddLogModal() async {
    _processNameCtrl.clear();
    _inputQtyCtrl.clear();
    _outputQtyCtrl.clear();
    _selectedItemId = null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_productTypes.isEmpty) {
      await _fetchProductTypes();
      if (!mounted) return;
    }

    // Determine matching product recipe and pre-select the NEXT planned stage
    final orderTitle = _selectedOrder?['product_name']?.toString() ?? '';
    dynamic matchedProd;
    // First: match by product_id (most reliable)
    final productId = _selectedOrder?['product_id']?.toString();
    if (productId != null && productId.isNotEmpty) {
      for (final p in _productTypes) {
        if (p['id']?.toString() == productId) {
          matchedProd = p;
          break;
        }
      }
    }
    // Second: match by name substring
    if (matchedProd == null) {
      for (final p in _productTypes) {
        final pName = p['name']?.toString().toLowerCase() ?? '';
        // Strip batch code suffix (everything after " — ") before comparing
        final cleanTitle = orderTitle.toLowerCase().split(' — ').first.trim();
        if (cleanTitle.contains(pName) || pName.contains(cleanTitle) || cleanTitle == pName) {
          matchedProd = p;
          break;
        }
      }
    }
    // Fallback: use first product type
    if (matchedProd == null && _productTypes.isNotEmpty) {
      matchedProd = _productTypes[0];
    }

    final steps = (matchedProd?['steps'] as List?) ?? [];
    final existingLogs = (_selectedOrder?['production_logs'] as List?) ?? [];
    final nextStepIdx = existingLogs.length < steps.length ? existingLogs.length : (steps.isNotEmpty ? steps.length - 1 : 0);

    if (steps.isNotEmpty) {
      _processNameCtrl.text = steps[nextStepIdx]['process_name'] ?? steps[nextStepIdx]['name'] ?? 'Step 1';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setModal) {
        return _ThemedSheet(
          isDark: isDark,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SheetHandle(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_task_rounded,
                            color: AppColors.warning, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Log Process Stage',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                )),
                            if (steps.isNotEmpty)
                              Text(
                                'Step ${nextStepIdx + 1} of ${steps.length} for ${matchedProd?['name']}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Recipe / Product selection
                  if (_productTypes.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recipe / Product:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            )),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: matchedProd?['id']?.toString() ?? _productTypes[0]['id']?.toString(),
                            isDense: true,
                            dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                            items: _productTypes.map<DropdownMenuItem<String>>((p) {
                              return DropdownMenuItem<String>(
                                value: p['id']?.toString() ?? '',
                                child: Text(
                                  p['name']?.toString() ?? 'Recipe',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setModal(() {
                                matchedProd = _productTypes.firstWhere(
                                  (p) => p['id']?.toString() == val,
                                  orElse: () => matchedProd,
                                );
                                final newSteps = (matchedProd?['steps'] as List?) ?? [];
                                if (newSteps.isNotEmpty) {
                                  _processNameCtrl.text = newSteps[0]['process_name'] ?? newSteps[0]['name'] ?? 'Step 1';
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Auto-suggested stage selector chip bar
                  Builder(builder: (ctx) {
                    final currentSteps = (matchedProd?['steps'] as List?) ?? [];
                    if (currentSteps.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pre-defined Recipe Stages (Click to Select):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            )),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: currentSteps.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (context, idx) {
                              final s = currentSteps[idx];
                              final stepName = s['process_name'] ?? s['name'] ?? 'Step ${idx + 1}';
                              final isSelected = _processNameCtrl.text == stepName;
                              return InkWell(
                                onTap: () {
                                  setModal(() {
                                    _processNameCtrl.text = stepName;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBorder : const Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${idx + 1}. $stepName',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : const Color(0xFF334155)),
                                        ),
                                      ),
                                      if (s['expected_tolerance_pct'] != null)
                                        Text(
                                          ' (${s['expected_tolerance_pct']}%)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    );
                  }),

                  ErpInputField(
                    controller: _processNameCtrl,
                    label: 'Process Name',
                    hintText: 'e.g. Paper Cutting, Rolling, Packaging',
                    prefixIcon: Icons.settings_suggest_outlined,
                  ),
                  const SizedBox(height: 14),

                  // Material dropdown
                  _buildDarkDropdown(
                    context: context,
                    isDark: isDark,
                    value: _selectedItemId,
                    label: 'Raw Material Used (Optional)',
                    icon: Icons.category_outlined,
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('None')),
                      ..._inventoryItems.map((item) {
                        final rawStock = double.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0;
                        final stock = rawStock < 0 ? 0.0 : rawStock;
                        final stockDisplay = stock.truncateToDouble() == stock ? stock.toInt().toString() : stock.toString();
                        final title = item['title'] ?? item['name'] ?? 'Unknown';
                        final isOutOfStock = stock <= 0;
                        return DropdownMenuItem<String>(
                          value: item['id'] as String,
                          child: Text(
                            '$title · ${isOutOfStock ? 'Out of Stock (0)' : '$stockDisplay ${item['unit'] ?? ''}'}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isOutOfStock ? AppColors.error : null,
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) =>
                        setModal(() => _selectedItemId = val),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: ErpInputField(
                          controller: _inputQtyCtrl,
                          keyboardType: TextInputType.number,
                          label: 'Input Quantity',
                          hintText: 'Units in',
                          prefixIcon: Icons.input_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ErpInputField(
                          controller: _outputQtyCtrl,
                          keyboardType: TextInputType.number,
                          label: 'Output Quantity',
                          hintText: 'Units out',
                          prefixIcon: Icons.output_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _PrimaryButton(
                    label: 'Save Process Stage Log',
                    icon: Icons.save_alt_rounded,
                    onPressed: () async {
                      if (_processNameCtrl.text.trim().isEmpty) return;
                      final inQ = double.tryParse(_inputQtyCtrl.text) ?? 0;
                      final outQ = double.tryParse(_outputQtyCtrl.text) ?? 0;

                      // Prevent negative inventory
                      if (_selectedItemId != null && inQ > 0) {
                        final matchedItem = _inventoryItems.firstWhere(
                          (it) => it['id']?.toString() == _selectedItemId,
                          orElse: () => null,
                        );
                        if (matchedItem != null) {
                          final rawStock = double.tryParse(matchedItem['stock_quantity']?.toString() ?? '0') ?? 0;
                          final availableStock = rawStock < 0 ? 0.0 : rawStock;
                          if (inQ > availableStock) {
                            _showError('Insufficient stock for "${matchedItem['title'] ?? 'item'}". Available: $availableStock, requested: $inQ. Inventory cannot be negative.');
                            return;
                          }
                        }
                      }

                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      final logData = {
                        'process_name': _processNameCtrl.text.trim(),
                        'input_item_id': _selectedItemId,
                        'input_qty': inQ,
                        'output_qty': outQ,
                      };
                      final res = await ProductionService.addProcessLog(
                          _selectedOrder['id'], logData);
                      if (res['success'] && mounted) {
                        setState(() {
                          final newLog = res['data'];
                          (_selectedOrder['production_logs'] as List?) ??
                              (_selectedOrder['production_logs'] = []);
                          (_selectedOrder['production_logs'] as List)
                              .insert(0, newLog);
                          _isLoading = false;
                        });
                        _fetchInventory();
                      } else {
                        setState(() => _isLoading = false);
                        if (mounted) _showError(res['error'] ?? 'Failed');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showUpdateOutputModal(dynamic log) {
    _outputQtyCtrl.clear();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ThemedSheet(
        isDark: isDark,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHandle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Complete: ${log['process_name']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Input used: ${log['input_qty']} units',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ErpInputField(
                controller: _outputQtyCtrl,
                keyboardType: TextInputType.number,
                label: 'Output Quantity',
                hintText: 'Good units produced',
                prefixIcon: Icons.output_rounded,
              ),
              const SizedBox(height: 20),
              _PrimaryButton(
                label: 'Mark as Complete',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                onPressed: () async {
                  if (_outputQtyCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  final outputQty =
                      double.tryParse(_outputQtyCtrl.text) ?? 0;
                  final res = await ProductionService.updateProcessLog(
                      log['id'], outputQty);
                  if (res['success'] && mounted) {
                    setState(() {
                      log['output_qty'] = outputQty;
                      log['wastage_qty'] =
                          (log['input_qty'] ?? 0) - outputQty;
                      _isLoading = false;
                    });
                    _fetchOrders();
                  } else {
                    setState(() => _isLoading = false);
                    if (mounted) _showError(res['error'] ?? 'Failed');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_currentSubIndex == 1 && _selectedOrder != null) {
      return _buildOrderDetails();
    }
    if (_currentSubIndex == 2) {
      return _buildWastageReport();
    }
    return _buildOrdersList();
  }

  // ─── Orders List ─────────────────────────────────────────────────────────────

  Widget _buildOrdersList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _orders.where((o) =>
        (o['status'] ?? '').toString().toLowerCase() != 'completed').toList();
    final done = _orders.where((o) =>
        (o['status'] ?? '').toString().toLowerCase() == 'completed').toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ErpHeaderBar(
              title: 'Factory Production',
              trailing: Row(children: [
                _IconBtn(
                  icon: Icons.bar_chart_rounded,
                  onTap: () {
                    setState(() => _currentSubIndex = 2);
                    _fetchWastageReport();
                  },
                  tooltip: 'Wastage Report',
                ),
                const SizedBox(width: 6),
                _IconBtn(
                  icon: Icons.add_rounded,
                  onTap: _showAddOrderModal,
                  tooltip: 'New Order',
                  filled: true,
                ),
              ]),
            ),

            // Summary strip
            if (!_isLoading && _orders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(children: [
                  _SummaryChip(
                    label: '${active.length} Active',
                    color: AppColors.warning,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _SummaryChip(
                    label: '${done.length} Completed',
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _SummaryChip(
                    label: '${_orders.length} Total',
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ]),
              ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _orders.isEmpty
                      ? _EmptyState(
                          icon: Icons.precision_manufacturing_outlined,
                          title: 'No Production Orders',
                          subtitle: 'Tap + to start your first batch',
                          onAction: _showAddOrderModal,
                          actionLabel: 'Start Order',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _fetchOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => RepaintBoundary(
                              child: _OrderCard(
                                order: _orders[i],
                                isDark: isDark,
                                onTap: () => setState(() {
                                  _selectedOrder = _orders[i];
                                  _currentSubIndex = 1;
                                }),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Order Details ───────────────────────────────────────────────────────────

  Widget _buildOrderDetails() {
    final logs = (_selectedOrder['production_logs'] as List?) ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _selectedOrder['status']?.toString() ?? 'In Progress';
    final isCompleted = status.toLowerCase() == 'completed';

    // Calculate stats
    final totalInput = logs.fold<double>(
        0, (sum, l) => sum + (double.tryParse(l['input_qty']?.toString() ?? '0') ?? 0));
    final totalOutput = logs.fold<double>(
        0, (sum, l) => sum + (double.tryParse(l['output_qty']?.toString() ?? '0') ?? 0));
    final totalWastage = totalInput - totalOutput;
    final efficiency = totalInput > 0
        ? ((totalOutput / totalInput) * 100).clamp(0, 100).toStringAsFixed(1)
        : '—';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ErpHeaderBar(
              title: _selectedOrder['product_name'] ?? 'Order',
              onBackTap: popSubScreen,
              trailing: Row(children: [
                if (!isCompleted)
                  _IconBtn(
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    tooltip: 'Complete Order',
                    onTap: () async {
                      final confirm = await _confirmDialog(
                        'Complete Order',
                        'Mark "${_selectedOrder['product_name']}" as fully completed?',
                      );
                      if (confirm != true) return;
                      setState(() => _isLoading = true);
                      final res = await ProductionService.completeOrder(
                          _selectedOrder['id']);
                      if (res['success'] && mounted) {
                        setState(() {
                          _selectedOrder['status'] = 'Completed';
                          _isLoading = false;
                        });
                        HapticFeedback.lightImpact();
                      } else {
                        setState(() => _isLoading = false);
                        if (mounted) _showError(res['error'] ?? 'Failed');
                      }
                    },
                  ),
                const SizedBox(width: 6),
                _IconBtn(
                  icon: Icons.add_task_rounded,
                  tooltip: 'Log Step',
                  onTap: _showAddLogModal,
                  filled: !isCompleted,
                ),
              ]),
            ),

            // Status banner
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBg(status, isDark),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        )),
                  ]),
                ),
                const SizedBox(width: 10),
                Text(
                  'Started ${_selectedOrder['start_date']?.toString().split('T')[0] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ]),
            ),

            // Stats row
            if (logs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(children: [
                  _StatMini('Input', totalInput.toStringAsFixed(1), AppColors.info, isDark),
                  const SizedBox(width: 10),
                  _StatMini('Output', totalOutput.toStringAsFixed(1), AppColors.success, isDark),
                  const SizedBox(width: 10),
                  _StatMini('Wastage', totalWastage > 0 ? totalWastage.toStringAsFixed(1) : '0', AppColors.error, isDark),
                  const SizedBox(width: 10),
                  _StatMini('Efficiency', '$efficiency%', AppColors.warning, isDark),
                ]),
              ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : logs.isEmpty
                      ? _EmptyState(
                          icon: Icons.playlist_add_rounded,
                          title: 'No Process Steps',
                          subtitle: 'Log each step as production progresses',
                          onAction: isCompleted ? null : _showAddLogModal,
                          actionLabel: 'Log First Step',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          itemCount: logs.length,
                          itemBuilder: (_, i) => RepaintBoundary(
                            child: _ProcessLogCard(
                              log: logs[i],
                              isDark: isDark,
                              stepNumber: logs.length - i,
                              onAddOutput: isCompleted
                                  ? null
                                  : () => _showUpdateOutputModal(logs[i]),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Wastage Report (ML & Statistical Monitoring) ───────────────────────────

  Widget _buildWastageReport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if _wastageReport is the new ML analytics map or legacy list
    Map<String, dynamic> summary = {};
    List<dynamic> byProduction = [];
    List<dynamic> byProcess = [];
    List<dynamic> daily = [];
    List<dynamic> weekly = [];
    List<dynamic> monthly = [];
    List<dynamic> yearly = [];
    List<dynamic> anomalies = [];

    if (_wastageReport is Map) {
      final map = _wastageReport as Map;
      summary = (map['summary'] as Map?)?.cast<String, dynamic>() ?? {};
      byProduction = (map['by_production'] as List?) ?? [];
      byProcess = (map['by_process'] as List?) ?? [];
      daily = (map['daily'] as List?) ?? [];
      weekly = (map['weekly'] as List?) ?? [];
      monthly = (map['monthly'] as List?) ?? [];
      yearly = (map['yearly'] as List?) ?? [];
      anomalies = (map['anomalies'] as List?) ?? [];
    } else if (_wastageReport is List) {
      byProcess = _wastageReport as List;
      final totalIn = byProcess.fold<double>(0, (s, r) => s + (double.tryParse(r['total_input']?.toString() ?? '0') ?? 0));
      final totalOut = byProcess.fold<double>(0, (s, r) => s + (double.tryParse(r['total_output']?.toString() ?? '0') ?? 0));
      final totalW = byProcess.fold<double>(0, (s, r) => s + (double.tryParse(r['total_wastage']?.toString() ?? '0') ?? 0));
      summary = {
        'total_input': totalIn,
        'total_output': totalOut,
        'total_wastage': totalW,
        'overall_yield_pct': totalIn > 0 ? (totalOut / totalIn * 100) : 0,
        'overall_wastage_pct': totalIn > 0 ? (totalW / totalIn * 100) : 0,
        'efficiency_grade': 'B',
        'anomaly_count': 0,
      };
    }

    final overallYield = double.tryParse(summary['overall_yield_pct']?.toString() ?? '0') ?? 0;
    final overallWaste = double.tryParse(summary['overall_wastage_pct']?.toString() ?? '0') ?? 0;
    final grade = summary['efficiency_grade']?.toString() ?? '—';
    final anomalyCount = int.tryParse(summary['anomaly_count']?.toString() ?? '0') ?? 0;

    // Pick active list according to selected horizon
    List<dynamic> currentList = [];
    switch (_selectedHorizon) {
      case 'by_production':
        currentList = byProduction;
        break;
      case 'daily':
        currentList = daily;
        break;
      case 'weekly':
        currentList = weekly;
        break;
      case 'monthly':
        currentList = monthly;
        break;
      case 'yearly':
        currentList = yearly;
        break;
      case 'by_process':
      default:
        currentList = byProcess;
        break;
    }

    final hasData = _wastageReport != null && summary.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ErpHeaderBar(
              title: 'ML Wastage Analytics',
              onBackTap: popSubScreen,
              trailing: Row(
                children: [
                  _IconBtn(
                    icon: Icons.table_view_rounded,
                    color: AppColors.success,
                    tooltip: 'Export Excel / CSV',
                    onTap: () async {
                      final url = await ProductionService.getExportExcelUrlWithAuth();
                      downloadFileFromUrl(url, filename: 'buoy-factory-wastage-report.csv');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloading Wastage Report (Excel / CSV)...'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: Icons.picture_as_pdf_rounded,
                    color: AppColors.error,
                    tooltip: 'Export Executive PDF',
                    onTap: () async {
                      final url = await ProductionService.getExportPdfUrlWithAuth();
                      downloadFileFromUrl(url, filename: 'buoy-factory-wastage-report.html');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Executive Wastage Report for Print / PDF...'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Refresh',
                    onTap: _fetchWastageReport,
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (!hasData)
              const Expanded(
                child: _EmptyState(
                  icon: Icons.analytics_outlined,
                  title: 'No Production Data Recorded',
                  subtitle: 'Log production batches and stages to activate the ML Wastage Engine',
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchWastageReport,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      // 1. Executive ML Scorecard
                      _MlScorecard(
                        overallYield: overallYield,
                        overallWaste: overallWaste,
                        grade: grade,
                        anomalyCount: anomalyCount,
                        totalInput: double.tryParse(summary['total_input']?.toString() ?? '0') ?? 0,
                        totalOutput: double.tryParse(summary['total_output']?.toString() ?? '0') ?? 0,
                        totalWastage: double.tryParse(summary['total_wastage']?.toString() ?? '0') ?? 0,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // 2. Horizon Switcher Bar
                      _HorizonBar(
                        selected: _selectedHorizon,
                        onSelect: (h) => setState(() => _selectedHorizon = h),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // 3. ML Anomaly Alert Section (if anomalies detected)
                      if (anomalies.isNotEmpty) ...[
                        _AnomalyBanner(
                          anomalies: anomalies,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 4. Section Heading
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _horizonTitle(_selectedHorizon),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${currentList.length} records',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 5. Data cards list
                      if (currentList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No records found for this aggregation horizon.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else if (_selectedHorizon == 'by_production')
                        ...currentList.map((batch) => _BatchWastageCard(batch: batch, isDark: isDark))
                      else if (_selectedHorizon == 'by_process')
                        ...currentList.map((proc) => _WastageCard(report: proc, isDark: isDark))
                      else
                        ...currentList.map((period) => _PeriodWastageCard(
                              period: period,
                              horizonKey: _selectedHorizon == 'daily' ? 'date' : (_selectedHorizon == 'weekly' ? 'week' : (_selectedHorizon == 'monthly' ? 'month' : 'year')),
                              isDark: isDark,
                            )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _horizonTitle(String horizon) {
    switch (horizon) {
      case 'by_production': return 'Batch-by-Batch Production Analysis';
      case 'daily': return 'Day-by-Day Wastage History';
      case 'weekly': return 'Weekly Production Yields';
      case 'monthly': return 'Monthly Aggregated Wastage';
      case 'yearly': return 'Yearly Efficiency Comparison';
      case 'by_process': return 'Stage & Process Tolerances';
      default: return 'Production Analytics';
    }
  }

  // ─── Confirm Dialog ──────────────────────────────────────────────────────────

  Future<bool?> _confirmDialog(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkDropdown({
    required BuildContext context,
    required bool isDark,
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
        dropdownColor: isDark ? AppColors.darkCard : Colors.white,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontSize: 14,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Reusable Sub-Widgets ──────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final bool isDark;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'In Progress';
    final logs = (order['production_logs'] as List?) ?? [];
    final completedLogs =
        logs.where((l) => (l['output_qty'] ?? 0).toString() != '0').length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 20,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _statusBg(status, isDark),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  status.toLowerCase() == 'completed'
                      ? Icons.check_circle_rounded
                      : Icons.precision_manufacturing_rounded,
                  color: _statusColor(status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['product_name']?.toString() ?? 'Untitled Order',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusBg(status, isDark),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(status),
                            )),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order['start_date']?.toString().split('T')[0] ?? '',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ]),
                    if (logs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _MiniProgressBar(
                          value: logs.isEmpty ? 0 : completedLogs / logs.length,
                          label: '$completedLogs/${logs.length} steps done'),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessLogCard extends StatelessWidget {
  final dynamic log;
  final bool isDark;
  final int stepNumber;
  final VoidCallback? onAddOutput;
  const _ProcessLogCard({
    required this.log, required this.isDark,
    required this.stepNumber, this.onAddOutput,
  });

  @override
  Widget build(BuildContext context) {
    final inputQty = double.tryParse(log['input_qty']?.toString() ?? '0') ?? 0;
    final outputQty = double.tryParse(log['output_qty']?.toString() ?? '0') ?? 0;
    final wastageQty = double.tryParse(log['wastage_qty']?.toString() ?? '0') ?? 0;
    final isPending = outputQty == 0;
    final efficiency = inputQty > 0
        ? ((outputQty / inputQty) * 100).clamp(0, 100).toStringAsFixed(0)
        : '—';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 18,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Step number badge
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('$stepNumber',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          )),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      log['process_name']?.toString() ?? 'Process',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isPending && onAddOutput != null)
                    GestureDetector(
                      onTap: onAddOutput,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.edit_rounded, size: 13, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text('Add Output',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning)),
                        ]),
                      ),
                    )
                  else if (!isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(children: [
                        Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('Done',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                      ]),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Metric row
              Row(children: [
                _LogStat('Input', inputQty.toStringAsFixed(1), AppColors.info, isDark),
                const SizedBox(width: 8),
                _LogStat('Output',
                    isPending ? '—' : outputQty.toStringAsFixed(1),
                    isPending ? AppColors.textSecondary : AppColors.success,
                    isDark),
                const SizedBox(width: 8),
                _LogStat('Wastage',
                    isPending ? '—' : wastageQty.toStringAsFixed(1),
                    isPending ? AppColors.textSecondary
                        : (wastageQty > 0 ? AppColors.error : AppColors.success),
                    isDark),
                const SizedBox(width: 8),
                _LogStat('Efficiency', isPending ? '—' : '$efficiency%',
                    isPending ? AppColors.textSecondary : AppColors.warning, isDark),
              ]),

              // Progress bar for non-pending
              if (!isPending && inputQty > 0) ...[
                const SizedBox(height: 10),
                _MiniProgressBar(
                  value: (outputQty / inputQty).clamp(0, 1),
                  label: 'Yield rate',
                  color: outputQty >= inputQty * 0.8
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MlScorecard extends StatelessWidget {
  final double overallYield;
  final double overallWaste;
  final String grade;
  final int anomalyCount;
  final double totalInput;
  final double totalOutput;
  final double totalWastage;
  final bool isDark;

  const _MlScorecard({
    required this.overallYield,
    required this.overallWaste,
    required this.grade,
    required this.anomalyCount,
    required this.totalInput,
    required this.totalOutput,
    required this.totalWastage,
    required this.isDark,
  });

  Color _gradeColor(String g) {
    switch (g.toUpperCase()) {
      case 'A+':
      case 'A': return AppColors.success;
      case 'B': return const Color(0xFF3B82F6);
      case 'C': return AppColors.warning;
      case 'D': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradeColor = _gradeColor(grade);

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Model indicator & Anomaly Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ML Wastage Predictor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: anomalyCount > 0
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (anomalyCount > 0 ? AppColors.error : AppColors.success).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      anomalyCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                      size: 13,
                      color: anomalyCount > 0 ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      anomalyCount > 0 ? '$anomalyCount ML Outliers' : 'Nominal Tolerances',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: anomalyCount > 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Middle Row: Grade + Yield Rate Big display
          Row(
            children: [
              // Efficiency Grade Box
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradeColor.withValues(alpha: 0.25),
                      gradeColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gradeColor.withValues(alpha: 0.4), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      grade,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: gradeColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GRADE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Overall Yield & Wastage text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${overallYield.toStringAsFixed(1)}% Factory Yield',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Average Wastage Rate: ${overallWaste.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Dual colored bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (overallYield * 10).round().clamp(1, 1000),
                            child: Container(height: 6, color: AppColors.success),
                          ),
                          Expanded(
                            flex: (overallWaste * 10).round().clamp(1, 1000),
                            child: Container(height: 6, color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Stats grid (3 columns)
          Row(
            children: [
              _StatMini('Total In', totalInput.toStringAsFixed(1), AppColors.info, isDark),
              const SizedBox(width: 8),
              _StatMini('Total Out', totalOutput.toStringAsFixed(1), AppColors.success, isDark),
              const SizedBox(width: 8),
              _StatMini('Total Waste', totalWastage.toStringAsFixed(1), AppColors.error, isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizonBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final bool isDark;

  const _HorizonBar({
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  static const _horizons = [
    {'id': 'by_production', 'label': 'By Batch'},
    {'id': 'daily', 'label': 'Day by Day'},
    {'id': 'weekly', 'label': 'Weekly'},
    {'id': 'monthly', 'label': 'Monthly'},
    {'id': 'yearly', 'label': 'Yearly'},
    {'id': 'by_process', 'label': 'By Process'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _horizons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final item = _horizons[idx];
          final isSelected = selected == item['id'];

          return InkWell(
            onTap: () => onSelect(item['id']!),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  item['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnomalyBanner extends StatelessWidget {
  final List<dynamic> anomalies;
  final bool isDark;

  const _AnomalyBanner({required this.anomalies, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.crisis_alert_rounded, color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ML Gaussian Anomalies Detected (${anomalies.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Processes exceeding standard Gaussian statistical tolerance thresholds (Z-Score > 2.0σ)',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...anomalies.take(3).map((a) {
            final zScore = a['z_score']?.toString() ?? '2.0';
            final wastePct = a['wastage_pct']?.toString() ?? '0';
            final proc = a['process_name'] ?? 'Process';
            final prod = a['product_name'] ?? 'Production';
            final severity = a['severity'] ?? 'High';

            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$proc ($prod)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Wastage Rate: $wastePct%  •  Deviance: Z = +$zScoreσ',
                          style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      severity,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BatchWastageCard extends StatefulWidget {
  final dynamic batch;
  final bool isDark;

  const _BatchWastageCard({required this.batch, required this.isDark});

  @override
  State<_BatchWastageCard> createState() => _BatchWastageCardState();
}

class _BatchWastageCardState extends State<_BatchWastageCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.batch;
    final totalIn = double.tryParse(b['total_input']?.toString() ?? '0') ?? 0;
    final totalOut = double.tryParse(b['total_output']?.toString() ?? '0') ?? 0;
    final totalWaste = double.tryParse(b['total_wastage']?.toString() ?? '0') ?? 0;
    final yieldPct = double.tryParse(b['yield_pct']?.toString() ?? '0') ?? 0;
    final prodName = b['product_name'] ?? 'Production Batch';
    final bottleneck = b['bottleneck_step']?.toString();
    final steps = (b['steps'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prodName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Order #${b['order_id']?.toString().substring(0, b['order_id'].toString().length > 8 ? 8 : b['order_id'].toString().length) ?? ''}  •  ${b['status'] ?? 'In Progress'}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: yieldPct >= 90
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${yieldPct.toStringAsFixed(1)}% yield',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: yieldPct >= 90 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottleneck Callout
                if (bottleneck != null && bottleneck.isNotEmpty && bottleneck != 'None') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_down_rounded, color: AppColors.warning, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ML Bottleneck Stage: $bottleneck',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    _LogStat('Input', totalIn.toStringAsFixed(1), AppColors.info, widget.isDark),
                    const SizedBox(width: 8),
                    _LogStat('Output', totalOut.toStringAsFixed(1), AppColors.success, widget.isDark),
                    const SizedBox(width: 8),
                    _LogStat('Waste', totalWaste.toStringAsFixed(1), AppColors.error, widget.isDark),
                  ],
                ),

                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (yieldPct / 100).clamp(0, 1),
                    backgroundColor: AppColors.error.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    minHeight: 5,
                  ),
                ),

                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _expanded ? 'Hide ${steps.length} Stages' : 'View ${steps.length} Stages Breakdown',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_expanded && steps.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(
                  top: BorderSide(
                    color: widget.isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: steps.map<Widget>((s) {
                  final sIn = s['input_qty'] ?? 0;
                  final sOut = s['output_qty'] ?? 0;
                  final sWaste = s['wastage_qty'] ?? 0;
                  final sYield = s['yield_pct'] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s['process_name'] ?? 'Stage',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          'In: $sIn  Out: $sOut  Waste: $sWaste ($sYield% yield)',
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodWastageCard extends StatelessWidget {
  final dynamic period;
  final String horizonKey;
  final bool isDark;

  const _PeriodWastageCard({
    required this.period,
    required this.horizonKey,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final label = period[horizonKey]?.toString() ?? 'Period';
    final totalIn = double.tryParse(period['total_input']?.toString() ?? '0') ?? 0;
    final totalOut = double.tryParse(period['total_output']?.toString() ?? '0') ?? 0;
    final totalWaste = double.tryParse(period['total_wastage']?.toString() ?? '0') ?? 0;
    final yieldPct = double.tryParse(period['yield_pct']?.toString() ?? '0') ?? 0;
    final wastePct = double.tryParse(period['wastage_pct']?.toString() ?? '0') ?? 0;
    final count = period['log_count'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: yieldPct >= 90
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${yieldPct.toStringAsFixed(1)}% yield',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: yieldPct >= 90 ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LogStat('Input', totalIn.toStringAsFixed(1), AppColors.info, isDark),
              const SizedBox(width: 8),
              _LogStat('Output', totalOut.toStringAsFixed(1), AppColors.success, isDark),
              const SizedBox(width: 8),
              _LogStat('Waste', totalWaste.toStringAsFixed(1), AppColors.error, isDark),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (yieldPct * 10).round().clamp(1, 1000),
                  child: Container(height: 5, color: AppColors.success),
                ),
                Expanded(
                  flex: (wastePct * 10).round().clamp(1, 1000),
                  child: Container(height: 5, color: AppColors.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count production logs analyzed in this period',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WastageCard extends StatelessWidget {
  final dynamic report;
  final bool isDark;
  const _WastageCard({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final totalIn = double.tryParse(report['total_input']?.toString() ?? '0') ?? 0;
    final totalOut = double.tryParse(report['total_output']?.toString() ?? '0') ?? 0;
    final totalWaste = double.tryParse(report['total_wastage']?.toString() ?? '0') ?? 0;
    final pct = totalIn > 0 ? (totalWaste / totalIn * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 18,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report['process_name']?.toString() ?? 'Process',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: pct > 20
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pct.toStringAsFixed(1)}% waste',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pct > 20 ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                _LogStat('Input', totalIn.toStringAsFixed(1), AppColors.info, isDark),
                const SizedBox(width: 10),
                _LogStat('Output', totalOut.toStringAsFixed(1), AppColors.success, isDark),
                const SizedBox(width: 10),
                _LogStat('Wastage', totalWaste.toStringAsFixed(1), AppColors.error, isDark),
              ]),
              const SizedBox(height: 10),
              // Wastage bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0, 1),
                  backgroundColor: isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation(
                    pct > 20 ? AppColors.error : AppColors.warning,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Micro UI Components ───────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _SummaryChip({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _LogStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _LogStat(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _StatMini(this.label, this.value, this.color, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const _MiniProgressBar({
    required this.value, required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            backgroundColor: isDark ? AppColors.darkCardBorder : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool filled;
  final Color? color;
  const _IconBtn({
    required this.icon, required this.onTap,
    this.tooltip, this.filled = false, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: filled
                ? c
                : c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: filled ? Colors.white : c, size: 20),
        ),
      ),
    );
  }
}

class _ThemedSheet extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _ThemedSheet({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBorder : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel ?? 'Add'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
