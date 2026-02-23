// lib/pages/printer_settings_page.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/thermal_printer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_modal_dialog.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final ThermalPrinterService _printerService = ThermalPrinterService();

  List<DiscoveredPrinter> _discoveredPrinters = [];
  bool _isScanning = false;
  // ignore: unused_field - reserved for WiFi printer connection feature
  String? _wifiIp;
  // ignore: unused_field - reserved for WiFi printer connection feature
  final int _wifiPort = 9100;
  StreamSubscription<PrinterStatus>? _statusSubscription;
  StreamSubscription<List<DiscoveredPrinter>>? _scanSubscription;

  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '9100');

  @override
  void initState() {
    super.initState();
    _loadSavedPrinter();
    _statusSubscription = _printerService.statusStream.listen((status) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _scanSubscription?.cancel();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPrinter() async {
    final saved = await _printerService.getSavedPrinterInfo();
    if (saved != null && mounted) {
      setState(() {
        if (saved['type'] == 'wifi') {
          final parts = saved['address']!.split(':');
          if (parts.length == 2) {
            _ipController.text = parts[0];
            _portController.text = parts[1];
          }
        }
      });
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    if (kIsWeb) return;

    // Request Bluetooth permissions
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final location = await Permission.locationWhenInUse.request();

    if (bluetoothScan.isDenied ||
        bluetoothConnect.isDenied ||
        location.isDenied) {
      if (mounted) {
        AppModalDialog.error(
          context: context,
          title: 'Permissions Required',
          message:
              'Bluetooth and location permissions are required to scan for printers.',
        );
      }
    }
  }

  Future<void> _startBluetoothScan() async {
    if (kIsWeb) {
      AppModalDialog.error(
        context: context,
        title: 'Not Supported',
        message:
            'Bluetooth printing is not supported on web. Please use WiFi printing or run the app on a mobile device.',
      );
      return;
    }

    await _requestBluetoothPermissions();

    setState(() {
      _isScanning = true;
      _discoveredPrinters = [];
    });

    _scanSubscription?.cancel();
    _scanSubscription = _printerService.scanBluetoothPrinters().listen(
      (printers) {
        if (mounted) {
          setState(() {
            _discoveredPrinters = printers;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      },
      onError: (e) {
        debugPrint('Scan error: $e');
        if (mounted) {
          setState(() => _isScanning = false);
        }
      },
    );

    // Stop scan after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (_isScanning && mounted) {
        _stopScan();
      }
    });
  }

  Future<void> _stopScan() async {
    await _printerService.stopScan();
    _scanSubscription?.cancel();
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectBluetooth(DiscoveredPrinter printer) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildConnectingDialog(),
    );

    final success = await _printerService.connectBluetooth(printer);

    if (mounted) Navigator.pop(context);

    if (mounted) {
      if (success) {
        AppModalDialog.success(
          context: context,
          title: 'Connected',
          message: 'Successfully connected to ${printer.name}',
        );
      } else {
        AppModalDialog.error(
          context: context,
          title: 'Connection Failed',
          message: 'Could not connect to ${printer.name}. Please try again.',
        );
      }
    }
  }

  Future<void> _connectWifi() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;

    if (ip.isEmpty) {
      AppModalDialog.error(
        context: context,
        title: 'Invalid IP',
        message: 'Please enter a valid IP address.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildConnectingDialog(),
    );

    final success = await _printerService.connectWifi(ip, port: port);

    if (mounted) Navigator.pop(context);

    if (mounted) {
      if (success) {
        AppModalDialog.success(
          context: context,
          title: 'Connected',
          message: 'Successfully connected to WiFi printer at $ip:$port',
        );
      } else {
        AppModalDialog.error(
          context: context,
          title: 'Connection Failed',
          message:
              'Could not connect to $ip:$port. Please check the IP address and ensure the printer is on the same network.',
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    if (mounted) {
      AppModalDialog.success(
        context: context,
        title: 'Disconnected',
        message: 'Printer has been disconnected.',
      );
    }
  }

  Future<void> _printTestPage() async {
    const subtotal = 175.00;
    final vat = ReceiptData.calculateVat(subtotal);
    final total = subtotal + vat;

    final receipt = ReceiptData(
      storeName: 'Test Store',
      orderNumber: 'TEST-001',
      dateTime: DateTime.now().toString().substring(0, 19),
      pickupTime: 'Now',
      customerName: 'Test Customer',
      items: [
        ReceiptItem(name: 'Test Item 1', quantity: 2, price: 50.00),
        ReceiptItem(
          name: 'Test Item 2',
          quantity: 1,
          price: 75.00,
          variations: 'Large',
        ),
      ],
      subtotal: subtotal,
      vat: vat,
      total: total,
      note: 'This is a test print',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPrintingDialog(),
    );

    final success = await _printerService.printReceipt(receipt);

    if (mounted) Navigator.pop(context);

    if (mounted) {
      if (success) {
        AppModalDialog.success(
          context: context,
          title: 'Print Success',
          message: 'Test page printed successfully!',
        );
      } else {
        AppModalDialog.error(
          context: context,
          title: 'Print Failed',
          message:
              'Could not print test page. Please check the printer connection.',
        );
      }
    }
  }

  Widget _buildConnectingDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Connecting...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrintingDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Printing...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = _printerService.status == PrinterStatus.connected;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Printer Settings',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status card
            _buildStatusCard(isDark, isConnected),
            const SizedBox(height: 24),

            // Bluetooth section
            _buildSectionHeader('Bluetooth Printers', isDark),
            const SizedBox(height: 12),
            _buildBluetoothSection(isDark),
            const SizedBox(height: 24),

            // WiFi section
            _buildSectionHeader('WiFi Printer', isDark),
            const SizedBox(height: 12),
            _buildWifiSection(isDark),
            const SizedBox(height: 24),

            // Actions
            if (isConnected) ...[
              _buildSectionHeader('Actions', isDark),
              const SizedBox(height: 12),
              _buildActionsSection(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark, bool isConnected) {
    final printer = _printerService.connectedPrinter;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isConnected
                  ? AppColors.success
                  : (isDark ? AppColors.borderDark : AppColors.border),
          width: isConnected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  isConnected
                      ? AppColors.success.withOpacity(0.1)
                      : (isDark
                          ? AppColors.backgroundDark
                          : AppColors.background),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.printer,
              color: isConnected ? AppColors.success : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        isConnected
                            ? AppColors.success
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary),
                  ),
                ),
                if (printer != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${printer.name} (${printer.type == PrinterConnectionType.bluetooth ? 'Bluetooth' : 'WiFi'})',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Scan for Bluetooth printers or enter WiFi IP',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBluetoothSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Scan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? _stopScan : _startBluetoothScan,
              icon: Icon(_isScanning ? Iconsax.stop : Iconsax.bluetooth),
              label: Text(_isScanning ? 'Stop Scanning' : 'Scan for Printers'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isScanning ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Scanning indicator
          if (_isScanning) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Scanning...',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Discovered printers
          if (_discoveredPrinters.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._discoveredPrinters.map(
              (printer) => _buildPrinterTile(printer, isDark),
            ),
          ],

          // Empty state
          if (!_isScanning && _discoveredPrinters.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'No printers found. Make sure your printer is turned on and in pairing mode.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrinterTile(DiscoveredPrinter printer, bool isDark) {
    final isConnected =
        _printerService.connectedPrinter?.address == printer.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isConnected
                  ? AppColors.success
                  : (isDark ? AppColors.borderDark : AppColors.border),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Iconsax.printer,
          color: isConnected ? AppColors.success : AppColors.primary,
        ),
        title: Text(
          printer.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          printer.address,
          style: TextStyle(
            fontSize: 12,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        trailing:
            isConnected
                ? Icon(Iconsax.tick_circle, color: AppColors.success)
                : TextButton(
                  onPressed: () => _connectBluetooth(printer),
                  child: const Text('Connect'),
                ),
      ),
    );
  }

  Widget _buildWifiSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // IP Address field
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'IP Address',
              hintText: '192.168.1.100',
              prefixIcon: const Icon(Iconsax.wifi),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDark : AppColors.background,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          // Port field
          TextField(
            controller: _portController,
            decoration: InputDecoration(
              labelText: 'Port',
              hintText: '9100',
              prefixIcon: const Icon(Iconsax.code),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.backgroundDark : AppColors.background,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Connect button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _connectWifi,
              icon: const Icon(Iconsax.wifi),
              label: const Text('Connect via WiFi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Test print button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _printTestPage,
              icon: const Icon(Iconsax.document_text),
              label: const Text('Print Test Page'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Disconnect button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Iconsax.close_circle),
              label: const Text('Disconnect'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
