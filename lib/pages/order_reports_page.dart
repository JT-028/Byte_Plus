// lib/pages/order_reports_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/thermal_printer_service.dart';

class OrderReportsPage extends StatefulWidget {
  const OrderReportsPage({super.key});

  @override
  State<OrderReportsPage> createState() => _OrderReportsPageState();
}

class _OrderReportsPageState extends State<OrderReportsPage> {
  final ThermalPrinterService _printerService = ThermalPrinterService();
  String? _storeId;
  String? _storeName;
  bool _isLoading = true;
  bool _isPrinting = false;

  // Report data
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _cancelledOrders = [];
  double _completedTotal = 0;
  double _cancelledTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final storeId = userDoc.data()?['storeId'] as String?;

      if (storeId != null) {
        final storeDoc =
            await FirebaseFirestore.instance
                .collection('stores')
                .doc(storeId)
                .get();
        _storeName = storeDoc.data()?['name'] as String? ?? 'Store';
        _storeId = storeId;
      }

      await _loadTodayOrders();
    } catch (e) {
      debugPrint('Error loading store info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTodayOrders() async {
    if (_storeId == null) return;

    // Get today's start and end timestamps
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final ordersSnapshot =
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(_storeId)
            .collection('orders')
            .where('timestamp', isGreaterThanOrEqualTo: todayStart)
            .where('timestamp', isLessThan: todayEnd)
            .get();

    _completedOrders = [];
    _cancelledOrders = [];
    _completedTotal = 0;
    _cancelledTotal = 0;

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      final total = (data['total'] as num?)?.toDouble() ?? 0;

      final orderData = {...data, 'docId': doc.id};

      if (status == 'done') {
        _completedOrders.add(orderData);
        _completedTotal += total;
      } else if (status == 'cancelled') {
        _cancelledOrders.add(orderData);
        _cancelledTotal += total;
      }
    }

    setState(() {});
  }

  Future<void> _printReport(String reportType) async {
    if (_printerService.status != PrinterStatus.connected) {
      _showSnackBar('Printer not connected. Go to printer settings first.');
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final orders =
          reportType == 'completed' ? _completedOrders : _cancelledOrders;
      final total =
          reportType == 'completed' ? _completedTotal : _cancelledTotal;
      final title =
          reportType == 'completed' ? 'COMPLETED ORDERS' : 'CANCELLED ORDERS';

      final success = await _printOrdersReport(
        title: title,
        orders: orders,
        total: total,
      );

      if (success) {
        _showSnackBar('Report printed successfully!');
      } else {
        _showSnackBar('Failed to print report.');
      }
    } catch (e) {
      _showSnackBar('Print error: $e');
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<bool> _printOrdersReport({
    required String title,
    required List<Map<String, dynamic>> orders,
    required double total,
  }) async {
    try {
      List<int> bytes = [];
      final now = DateTime.now();
      final dateStr = DateFormat('MMM dd, yyyy').format(now);
      final timeStr = DateFormat('hh:mm a').format(now);

      // Initialize printer
      bytes.addAll(EscPosCommands.initialize());

      // Store name (centered, bold, large)
      bytes.addAll(EscPosCommands.alignCenter());
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(EscPosCommands.largeTextOn());
      bytes.addAll(EscPosCommands.printLine(_storeName ?? 'Store'));
      bytes.addAll(EscPosCommands.largeTextOff());
      bytes.addAll(EscPosCommands.lineFeed(1));

      // Report title
      bytes.addAll(EscPosCommands.doubleHeightOn());
      bytes.addAll(EscPosCommands.printLine(title));
      bytes.addAll(EscPosCommands.doubleHeightOff());
      bytes.addAll(EscPosCommands.boldOff());

      // Date and time
      bytes.addAll(EscPosCommands.printLine('$dateStr $timeStr'));
      bytes.addAll(EscPosCommands.horizontalLine(32, '='));

      bytes.addAll(EscPosCommands.alignLeft());
      bytes.addAll(EscPosCommands.lineFeed(1));

      // Summary
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(EscPosCommands.printLine('SUMMARY'));
      bytes.addAll(EscPosCommands.boldOff());
      bytes.addAll(EscPosCommands.horizontalLine(32, '-'));
      bytes.addAll(
        EscPosCommands.printTwoColumns(
          'Total Orders:',
          orders.length.toString(),
          32,
        ),
      );
      bytes.addAll(
        EscPosCommands.printTwoColumns(
          'Total Amount:',
          'P${total.toStringAsFixed(2)}',
          32,
        ),
      );
      bytes.addAll(EscPosCommands.horizontalLine(32, '='));
      bytes.addAll(EscPosCommands.lineFeed(1));

      // Orders list
      if (orders.isNotEmpty) {
        bytes.addAll(EscPosCommands.boldOn());
        bytes.addAll(EscPosCommands.printLine('ORDER DETAILS'));
        bytes.addAll(EscPosCommands.boldOff());
        bytes.addAll(EscPosCommands.horizontalLine(32, '-'));

        for (int i = 0; i < orders.length; i++) {
          final order = orders[i];
          final orderId = order['orderId'] ?? order['docId'] ?? 'N/A';
          final orderTotal = (order['total'] as num?)?.toDouble() ?? 0;
          final items = order['items'] as List<dynamic>? ?? [];
          final timestamp = order['timestamp'];

          String timeDisplay = '';
          if (timestamp != null) {
            if (timestamp is Timestamp) {
              timeDisplay = DateFormat('hh:mm a').format(timestamp.toDate());
            }
          }

          // Order header
          bytes.addAll(EscPosCommands.boldOn());
          bytes.addAll(EscPosCommands.printLine('${i + 1}. Order #$orderId'));
          bytes.addAll(EscPosCommands.boldOff());

          if (timeDisplay.isNotEmpty) {
            bytes.addAll(EscPosCommands.printLine('   Time: $timeDisplay'));
          }

          // Items
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final name = item['productName'] ?? 'Item';
              final qty = item['quantity'] ?? 1;
              final price = (item['lineTotal'] as num?)?.toDouble() ?? 0;
              bytes.addAll(
                EscPosCommands.printLine(
                  '   $name x$qty - P${price.toStringAsFixed(2)}',
                ),
              );
            }
          }

          bytes.addAll(
            EscPosCommands.printTwoColumns(
              '   Subtotal:',
              'P${orderTotal.toStringAsFixed(2)}',
              32,
            ),
          );
          bytes.addAll(EscPosCommands.lineFeed(1));
        }
      } else {
        bytes.addAll(EscPosCommands.printLine('No orders to display.'));
      }

      // Footer
      bytes.addAll(EscPosCommands.horizontalLine(32, '='));
      bytes.addAll(EscPosCommands.alignCenter());
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(
        EscPosCommands.printTwoColumns(
          'GRAND TOTAL:',
          'P${total.toStringAsFixed(2)}',
          32,
        ),
      );
      bytes.addAll(EscPosCommands.boldOff());
      bytes.addAll(EscPosCommands.lineFeed(1));
      bytes.addAll(EscPosCommands.printLine('--- End of Report ---'));

      // Feed and cut
      bytes.addAll(EscPosCommands.lineFeed(3));
      bytes.addAll(EscPosCommands.cut());

      return await _printerService.printBytes(bytes);
    } catch (e) {
      debugPrint('Print report error: $e');
      return false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Order Reports'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadTodayOrders,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        "Today's Report",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Printer status
                      StreamBuilder<PrinterStatus>(
                        stream: _printerService.statusStream,
                        initialData: _printerService.status,
                        builder: (context, snapshot) {
                          final isConnected =
                              snapshot.data == PrinterStatus.connected;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isConnected
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.printer,
                                  color:
                                      isConnected
                                          ? AppColors.success
                                          : AppColors.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isConnected
                                      ? 'Printer connected'
                                      : 'Printer not connected',
                                  style: TextStyle(
                                    color:
                                        isConnected
                                            ? AppColors.success
                                            : AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Completed Orders Card
                      _reportCard(
                        title: 'Completed Orders',
                        count: _completedOrders.length,
                        total: _completedTotal,
                        color: AppColors.success,
                        icon: Iconsax.tick_circle,
                        isDark: isDark,
                        onPrint:
                            _completedOrders.isNotEmpty
                                ? () => _printReport('completed')
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Cancelled Orders Card
                      _reportCard(
                        title: 'Cancelled Orders',
                        count: _cancelledOrders.length,
                        total: _cancelledTotal,
                        color: AppColors.error,
                        icon: Iconsax.close_circle,
                        isDark: isDark,
                        onPrint:
                            _cancelledOrders.isNotEmpty
                                ? () => _printReport('cancelled')
                                : null,
                      ),
                      const SizedBox(height: 24),

                      // Print All Button
                      if (_completedOrders.isNotEmpty ||
                          _cancelledOrders.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isPrinting
                                    ? null
                                    : () async {
                                      if (_completedOrders.isNotEmpty) {
                                        await _printReport('completed');
                                      }
                                      if (_cancelledOrders.isNotEmpty) {
                                        await _printReport('cancelled');
                                      }
                                    },
                            icon:
                                _isPrinting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Iconsax.printer),
                            label: Text(
                              _isPrinting ? 'Printing...' : 'Print All Reports',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Info text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.surfaceDark : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.info_circle,
                                  size: 18,
                                  color:
                                      isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'About Daily Reports',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Orders are automatically archived at the end of each day. '
                              'Archived orders are still available for analytics but won\'t '
                              'appear in your active orders list.',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _reportCard({
    required String title,
    required int count,
    required double total,
    required Color color,
    required IconData icon,
    required bool isDark,
    VoidCallback? onPrint,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$count orders',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'P ${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              if (onPrint != null)
                OutlinedButton.icon(
                  onPressed: _isPrinting ? null : onPrint,
                  icon: const Icon(Iconsax.printer, size: 18),
                  label: const Text('Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

