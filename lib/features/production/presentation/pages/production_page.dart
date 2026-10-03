import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/production_service.dart';
import '../../../../core/services/inventory_service.dart';
import '../../../../core/widgets/erp_header_bar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/erp_input_field.dart';
import '../../../../core/widgets/custom_button.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => ProductionPageState();
}

class ProductionPageState extends State<ProductionPage> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  List<dynamic> _wastageReport = [];
  List<dynamic> _inventoryItems = [];

  // 0 = Orders List, 1 = Order Details, 2 = Wastage Report
  int _currentSubIndex = 0;
  dynamic _selectedOrder;

  // Controllers for new order
  final _orderNameCtrl = TextEditingController();

  // Controllers for new log
  final _processNameCtrl = TextEditingController();
  final _inputQtyCtrl = TextEditingController();
  final _outputQtyCtrl = TextEditingController();
  String? _selectedItemId;

  bool get hasSubScreen => _currentSubIndex > 0;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    final res = await InventoryService.getItems();
    if (res['success']) {
      setState(() {
        _inventoryItems = res['data'];
      });
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final res = await ProductionService.getOrders();
    if (res['success']) {
      setState(() {
        _orders = res['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWastageReport() async {
    setState(() => _isLoading = true);
    final res = await ProductionService.getWastageReport();
    if (res['success']) {
      setState(() {
        _wastageReport = res['data'];
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

  void _showAddOrderModal() {
    _orderNameCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Start New Production', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _orderNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Product Name (e.g. Apsara Pencil Batch 1)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_orderNameCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  final res = await ProductionService.createOrder(_orderNameCtrl.text);
                  if (res['success']) {
                    _fetchOrders();
                  } else {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'])));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DF5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateOutputModal(dynamic log) {
    _outputQtyCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Output (Log Process Complete)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _outputQtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Output Qty',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_outputQtyCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  
                  final outputQty = double.tryParse(_outputQtyCtrl.text) ?? 0;
                  final res = await ProductionService.updateProcessLog(log['id'], outputQty);
                  
                  if (res['success']) {
                    _fetchOrders();
                  } else {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'])));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Complete Process', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Log Process Step', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _processNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Process Name (e.g. Paper Cutting)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Raw Material Used (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: _selectedItemId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ..._inventoryItems.map((item) => DropdownMenuItem(
                            value: item['id'] as String,
                            child: Text('${item['title'] ?? item['name'] ?? 'Unknown'} (${item['stock_quantity'] ?? item['quantity'] ?? '0'} ${item['unit'] ?? ''})'),
                          ))
                    ],
                    onChanged: (val) => setModalState(() => _selectedItemId = val),
                  ),
                  const SizedBox(height: 16),
                  ErpInputField(
                    controller: _inputQtyCtrl,
                    keyboardType: TextInputType.number,
                    label: 'Input Qty',
                    hintText: 'Enter input quantity',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_processNameCtrl.text.isEmpty) return;
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      
                      final logData = {
                        'process_name': _processNameCtrl.text,
                        'input_item_id': _selectedItemId,
                        'input_qty': double.tryParse(_inputQtyCtrl.text) ?? 0,
                        'output_qty': 0, // initially 0, updated later when complete
                      };

                      final res = await ProductionService.addProcessLog(_selectedOrder['id'], logData);
                      if (res['success']) {
                        // Refresh specific order locally to avoid full fetch delay
                        setState(() {
                           final newLog = res['data'];
                           if (_selectedOrder['production_logs'] == null) {
                             _selectedOrder['production_logs'] = [];
                           }
                           _selectedOrder['production_logs'].insert(0, newLog);
                           _isLoading = false;
                        });
                        _fetchInventory(); // refresh inventory stock
                      } else {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'])));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B3DF5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSubIndex == 1 && _selectedOrder != null) {
      return _buildOrderDetailsScreen();
    } else if (_currentSubIndex == 2) {
      return _buildWastageReportScreen();
    }
    return _buildOrdersListScreen();
  }

  Widget _buildOrdersListScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ErpHeaderBar(
              title: 'Factory Production',
              trailing: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined, color: Colors.black),
                    onPressed: () {
                      setState(() => _currentSubIndex = 2);
                      _fetchWastageReport();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.black),
                    onPressed: _showAddOrderModal,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? const Center(child: Text('No active production orders.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20).copyWith(bottom: 100),
                          itemCount: _orders.length,
                          itemBuilder: (ctx, i) {
                            final order = _orders[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GlassContainer(
                                useGradientBorder: true,
                                borderRadius: 20,
                                padding: const EdgeInsets.all(16),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(order['product_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Status: ${order['status']}', style: const TextStyle(color: Color(0xFF5B3DF5), fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('Started: ${order['start_date'].toString().split('T')[0]}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF0F172A)),
                                  onTap: () {
                                    setState(() {
                                      _selectedOrder = order;
                                      _currentSubIndex = 1;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsScreen() {
    final logs = (_selectedOrder['production_logs'] as List?) ?? [];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ErpHeaderBar(
              title: _selectedOrder['product_name'],
              onBackTap: popSubScreen,
              trailing: IconButton(
                icon: const Icon(Icons.add_task, color: Colors.black),
                onPressed: _showAddLogModal,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : logs.isEmpty
                      ? const Center(child: Text('No processes logged yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20).copyWith(bottom: 100),
                          itemCount: logs.length,
                          itemBuilder: (ctx, i) {
                            final log = logs[i];
                            final bool needsOutput = (log['output_qty'] == null || log['output_qty'] == 0);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GlassContainer(
                                useGradientBorder: true,
                                borderRadius: 16,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(log['process_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (needsOutput)
                                          ElevatedButton(
                                            onPressed: () => _showUpdateOutputModal(log),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF5B3DF5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                              minimumSize: const Size(0, 32),
                                            ),
                                            child: const Text('Add Output', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _infoChip('Input Qty', '${log['input_qty']}', Colors.blue),
                                        _infoChip('Output Qty', needsOutput ? 'Pending' : '${log['output_qty']}', needsOutput ? Colors.grey : Colors.green),
                                        _infoChip('Wastage', needsOutput ? '-' : '${log['wastage_qty']}', needsOutput ? Colors.grey : Colors.red),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWastageReportScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            ErpHeaderBar(
              title: 'Wastage Report',
              onBackTap: popSubScreen,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _wastageReport.isEmpty
                      ? const Center(child: Text('No wastage data available.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20).copyWith(bottom: 100),
                          itemCount: _wastageReport.length,
                          itemBuilder: (ctx, i) {
                            final report = _wastageReport[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: GlassContainer(
                                useGradientBorder: true,
                                borderRadius: 16,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(report['process_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Divider(color: Colors.black12),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total Input:', style: TextStyle(color: Colors.grey.shade700)),
                                        Text('${report['total_input']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total Output:', style: TextStyle(color: Colors.grey.shade700)),
                                        Text('${report['total_output']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Wastage:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                        Text('${report['total_wastage']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
