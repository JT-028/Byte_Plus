// lib/services/print_service.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Service for thermal receipt printing via Bluetooth/USB.
/// Uses ESC/POS commands for compatible thermal printers.
class PrintService {
  static PrinterConnection? _currentPrinter;
  static List<PrinterDevice> _discoveredPrinters = [];

  /// Discover available Bluetooth printers
  static Future<List<PrinterDevice>> discoverBluetoothPrinters() async {
    // Note: Requires esc_pos_bluetooth package
    // This is a scaffold - actual implementation depends on chosen package
    _discoveredPrinters = [];

    // Simulated discovery - replace with actual Bluetooth scanning
    debugPrint('Discovering Bluetooth printers...');

    // In real implementation:
    // final bluetooth = PrinterBluetoothManager();
    // await bluetooth.scanResults.listen((device) {
    //   _discoveredPrinters.add(PrinterDevice(
    //     name: device.name ?? 'Unknown',
    //     address: device.address ?? '',
    //     type: PrinterType.bluetooth,
    //   ));
    // });

    return _discoveredPrinters;
  }

  /// Connect to a printer
  static Future<bool> connectPrinter(PrinterDevice device) async {
    try {
      _currentPrinter = PrinterConnection(device: device, isConnected: true);
      debugPrint('Connected to printer: ${device.name}');
      return true;
    } catch (e) {
      debugPrint('Failed to connect to printer: $e');
      return false;
    }
  }

  /// Disconnect current printer
  static Future<void> disconnectPrinter() async {
    _currentPrinter = null;
    debugPrint('Printer disconnected');
  }

  /// Check if printer is connected
  static bool get isConnected => _currentPrinter?.isConnected ?? false;

  /// Print order receipt
  static Future<bool> printOrderReceipt({
    required OrderReceipt receipt,
    bool openCashDrawer = false,
  }) async {
    if (!isConnected) {
      debugPrint('No printer connected');
      return false;
    }

    try {
      final bytes = _generateReceiptBytes(receipt, openCashDrawer);

      // In real implementation:
      // await _currentPrinter!.device.writeBytes(bytes);

      debugPrint('Receipt printed successfully');
      debugPrint('Receipt data: ${bytes.length} bytes');
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  /// Generate ESC/POS bytes for receipt
  static Uint8List _generateReceiptBytes(
    OrderReceipt receipt,
    bool openCashDrawer,
  ) {
    final bytes = <int>[];

    // ESC/POS Commands
    const escInit = [0x1B, 0x40]; // Initialize printer
    const escCenter = [0x1B, 0x61, 0x01]; // Center align
    const escLeft = [0x1B, 0x61, 0x00]; // Left align
    const escBoldOn = [0x1B, 0x45, 0x01]; // Bold on
    const escBoldOff = [0x1B, 0x45, 0x00]; // Bold off
    const escDoubleHeight = [0x1B, 0x21, 0x10]; // Double height
    const escNormal = [0x1B, 0x21, 0x00]; // Normal text
    const escCut = [0x1D, 0x56, 0x00]; // Full cut
    const escDrawer = [0x1B, 0x70, 0x00, 0x19, 0xFA]; // Open cash drawer
    const lineFeed = [0x0A]; // Line feed

    // Initialize
    bytes.addAll(escInit);

    // Header - Store name
    bytes.addAll(escCenter);
    bytes.addAll(escDoubleHeight);
    bytes.addAll(escBoldOn);
    bytes.addAll(_textToBytes(receipt.storeName));
    bytes.addAll(lineFeed);
    bytes.addAll(escNormal);
    bytes.addAll(escBoldOff);
    bytes.addAll(lineFeed);

    // Pickup number (large)
    bytes.addAll(escDoubleHeight);
    bytes.addAll(escBoldOn);
    bytes.addAll(_textToBytes('PICKUP #${receipt.pickupNumber}'));
    bytes.addAll(lineFeed);
    bytes.addAll(escNormal);
    bytes.addAll(escBoldOff);
    bytes.addAll(lineFeed);

    // Order info
    bytes.addAll(_textToBytes('Order: ${receipt.orderId.substring(0, 8)}...'));
    bytes.addAll(lineFeed);
    bytes.addAll(
      _textToBytes(
        DateFormat('MMM dd, yyyy hh:mm a').format(receipt.timestamp),
      ),
    );
    bytes.addAll(lineFeed);
    bytes.addAll(lineFeed);

    // Divider
    bytes.addAll(_textToBytes('-' * 32));
    bytes.addAll(lineFeed);

    // Items
    bytes.addAll(escLeft);
    for (final item in receipt.items) {
      bytes.addAll(_textToBytes('${item.quantity}x ${item.name}'));
      bytes.addAll(lineFeed);

      // Customizations
      if (item.size.isNotEmpty) {
        bytes.addAll(_textToBytes('   Size: ${item.size}'));
        bytes.addAll(lineFeed);
      }
      if (item.sugarLevel.isNotEmpty) {
        bytes.addAll(_textToBytes('   Sugar: ${item.sugarLevel}'));
        bytes.addAll(lineFeed);
      }
      if (item.iceLevel.isNotEmpty) {
        bytes.addAll(_textToBytes('   Ice: ${item.iceLevel}'));
        bytes.addAll(lineFeed);
      }
      if (item.note.isNotEmpty) {
        bytes.addAll(_textToBytes('   Note: ${item.note}'));
        bytes.addAll(lineFeed);
      }

      // Price
      bytes.addAll(
        _textToBytes(_rightAlign('P${item.lineTotal.toStringAsFixed(2)}', 32)),
      );
      bytes.addAll(lineFeed);
    }

    // Divider
    bytes.addAll(_textToBytes('-' * 32));
    bytes.addAll(lineFeed);

    // Total
    bytes.addAll(escBoldOn);
    bytes.addAll(
      _textToBytes(
        _formatLine('TOTAL', 'P${receipt.total.toStringAsFixed(2)}'),
      ),
    );
    bytes.addAll(lineFeed);
    bytes.addAll(escBoldOff);
    bytes.addAll(lineFeed);

    // Payment method
    bytes.addAll(escCenter);
    bytes.addAll(_textToBytes('Payment: ${receipt.paymentMethod}'));
    bytes.addAll(lineFeed);
    bytes.addAll(lineFeed);

    // Pickup time
    if (receipt.pickupTime != null) {
      bytes.addAll(escBoldOn);
      bytes.addAll(
        _textToBytes(
          'Pickup: ${DateFormat('hh:mm a').format(receipt.pickupTime!)}',
        ),
      );
      bytes.addAll(lineFeed);
      bytes.addAll(escBoldOff);
    }
    bytes.addAll(lineFeed);

    // Footer
    bytes.addAll(_textToBytes('Thank you for ordering!'));
    bytes.addAll(lineFeed);
    bytes.addAll(_textToBytes('BytePlus - SPCF'));
    bytes.addAll(lineFeed);
    bytes.addAll(lineFeed);
    bytes.addAll(lineFeed);

    // Cut paper
    bytes.addAll(escCut);

    // Open cash drawer if requested
    if (openCashDrawer) {
      bytes.addAll(escDrawer);
    }

    return Uint8List.fromList(bytes);
  }

  static List<int> _textToBytes(String text) {
    return text.codeUnits;
  }

  static String _rightAlign(String text, int width) {
    if (text.length >= width) return text;
    return text.padLeft(width);
  }

  static String _formatLine(String left, String right) {
    const width = 32;
    final padding = width - left.length - right.length;
    if (padding < 1) return '$left $right';
    return '$left${' ' * padding}$right';
  }

  /// Print kitchen ticket (shorter format)
  static Future<bool> printKitchenTicket({
    required String pickupNumber,
    required String customerName,
    required List<ReceiptItem> items,
    DateTime? pickupTime,
  }) async {
    if (!isConnected) return false;

    // Similar ESC/POS generation but shorter format
    // Focus on pickup number and item list for kitchen
    debugPrint('Kitchen ticket printed: $pickupNumber');
    return true;
  }

  /// Test print - prints a test page
  static Future<bool> testPrint() async {
    if (!isConnected) return false;

    final testReceipt = OrderReceipt(
      orderId: 'TEST-ORDER-001',
      storeName: 'BytePlus Test',
      pickupNumber: 'T01',
      timestamp: DateTime.now(),
      items: [
        ReceiptItem(
          name: 'Test Item',
          quantity: 1,
          lineTotal: 100.0,
          size: 'Medium',
          sugarLevel: '50%',
          iceLevel: 'Regular',
          note: '',
        ),
      ],
      total: 100.0,
      paymentMethod: 'Cash on Pickup',
      pickupTime: DateTime.now().add(const Duration(minutes: 15)),
    );

    return printOrderReceipt(receipt: testReceipt);
  }
}

/// Printer device model
class PrinterDevice {
  final String name;
  final String address;
  final PrinterType type;

  PrinterDevice({
    required this.name,
    required this.address,
    required this.type,
  });
}

enum PrinterType { bluetooth, usb, network }

/// Printer connection state
class PrinterConnection {
  final PrinterDevice device;
  final bool isConnected;

  PrinterConnection({required this.device, required this.isConnected});
}

/// Order receipt data model
class OrderReceipt {
  final String orderId;
  final String storeName;
  final String pickupNumber;
  final DateTime timestamp;
  final List<ReceiptItem> items;
  final double total;
  final String paymentMethod;
  final DateTime? pickupTime;

  OrderReceipt({
    required this.orderId,
    required this.storeName,
    required this.pickupNumber,
    required this.timestamp,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.pickupTime,
  });
}

/// Receipt line item
class ReceiptItem {
  final String name;
  final int quantity;
  final double lineTotal;
  final String size;
  final String sugarLevel;
  final String iceLevel;
  final String note;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.lineTotal,
    this.size = '',
    this.sugarLevel = '',
    this.iceLevel = '',
    this.note = '',
  });
}
