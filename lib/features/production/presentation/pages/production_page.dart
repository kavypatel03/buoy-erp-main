import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/services/production_service.dart';
import '../../../../core/services/inventory_service.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/erp_input_field.dart';

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
  List<dynamic> _wastageReport = [];
  List<dynamic> _inventoryItems = [];

  // 0 = Orders, 1 = Order Details, 2 = Wastage Report
  int _currentSubIndex = 0;
  dynamic _selectedOrder;

  late TabController _tabController;

  // Form controllers
  final _orderNameCtrl = TextEditingController();
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderNameCtrl.dispose();
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

  Future<void> _fetchOrders() async {
    if (mounted) setState(() => _isLoading = true);
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
    final res = await ProductionService.getWastageReport();
    if (mounted) {
      setState(() {
        if (res['success']) _wastageReport = res['data'];
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

  void _showAddOrderModal() {
    _orderNameCtrl.clear();
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
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.precision_manufacturing_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('New Production Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      )),
                ],
              ),
              const SizedBox(height: 20),
              ErpInputField(
                controller: _orderNameCtrl,
                label: 'Product Name',
                hintText: 'e.g. Apsara Pencil — Batch #12',
                prefixIcon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 20),
              _PrimaryButton(
                label: 'Start Production Order',
                icon: Icons.play_circle_outline_rounded,
                onPressed: () async {
                  if (_orderNameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  final res = await ProductionService.createOrder(
                      _orderNameCtrl.text.trim());
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
  }

  void _showAddLogModal() {
    _processNameCtrl.clear();
    _inputQtyCtrl.clear();
    _outputQtyCtrl.clear();
    _selectedItemId = null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      Text('Log Process Step',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ErpInputField(
                    controller: _processNameCtrl,
                    label: 'Process Name',
                    hintText: 'e.g. Paper Cutting, Assembly, Packing',
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
                      ..._inventoryItems.map((item) => DropdownMenuItem<String>(
                            value: item['id'] as String,
                            child: Text(
                              '${item['title'] ?? item['name'] ?? 'Unknown'}'
                              ' · ${item['stock_quantity'] ?? '0'} ${item['unit'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (val) =>
                        setModal(() => _selectedItemId = val),
                  ),
                  const SizedBox(height: 14),

                  ErpInputField(
                    controller: _inputQtyCtrl,
                    keyboardType: TextInputType.number,
                    label: 'Input Quantity',
                    hintText: 'Units consumed in this step',
                    prefixIcon: Icons.input_rounded,
                  ),
                  const SizedBox(height: 20),

                  _PrimaryButton(
                    label: 'Save Process Log',
                    icon: Icons.save_alt_rounded,
                    onPressed: () async {
                      if (_processNameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      final logData = {
                        'process_name': _processNameCtrl.text.trim(),
                        'input_item_id': _selectedItemId,
                        'input_qty': double.tryParse(_inputQtyCtrl.text) ?? 0,
                        'output_qty': 0,
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

  // ─── Wastage Report ──────────────────────────────────────────────────────────

  Widget _buildWastageReport() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalWastage = _wastageReport.fold<double>(0, (sum, r) {
      return sum + (double.tryParse(r['total_wastage']?.toString() ?? '0') ?? 0);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ErpHeaderBar(title: 'Wastage Report', onBackTap: popSubScreen),

            if (!_isLoading && _wastageReport.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Wastage Across All Processes',
                              style: TextStyle(
                                  fontSize: 11.5, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            totalWastage.toStringAsFixed(2),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error),
                          ),
                        ],
                      ),
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 22),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _wastageReport.isEmpty
                      ? const _EmptyState(
                          icon: Icons.bar_chart_outlined,
                          title: 'No Wastage Data',
                          subtitle: 'Complete process steps to generate report',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          itemCount: _wastageReport.length,
                          itemBuilder: (_, i) => RepaintBoundary(
                            child: _WastageCard(
                                report: _wastageReport[i], isDark: isDark),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
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
