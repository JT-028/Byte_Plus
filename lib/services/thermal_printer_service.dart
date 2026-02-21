// lib/services/thermal_printer_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ESC/POS Commands for thermal printers
/// Compatible with GOOJPRT PT-210 and similar ESC/POS printers
class EscPosCommands {
  // Initialize printer
  static List<int> initialize() => [0x1B, 0x40];

  // Line feed
  static List<int> lineFeed([int lines = 1]) => [0x1B, 0x64, lines];

  // Feed and cut paper
  static List<int> cut() => [0x1D, 0x56, 0x01];

  // Text alignment
  static List<int> alignLeft() => [0x1B, 0x61, 0x00];
  static List<int> alignCenter() => [0x1B, 0x61, 0x01];
  static List<int> alignRight() => [0x1B, 0x61, 0x02];

  // Bold text
  static List<int> boldOn() => [0x1B, 0x45, 0x01];
  static List<int> boldOff() => [0x1B, 0x45, 0x00];

  // Double height text
  static List<int> doubleHeightOn() => [0x1B, 0x21, 0x10];
  static List<int> doubleHeightOff() => [0x1B, 0x21, 0x00];

  // Double width text
  static List<int> doubleWidthOn() => [0x1B, 0x21, 0x20];
  static List<int> doubleWidthOff() => [0x1B, 0x21, 0x00];

  // Double height and width (large text)
  static List<int> largeTextOn() => [0x1B, 0x21, 0x30];
  static List<int> largeTextOff() => [0x1B, 0x21, 0x00];

  // Underline
  static List<int> underlineOn() => [0x1B, 0x2D, 0x01];
  static List<int> underlineOff() => [0x1B, 0x2D, 0x00];

  // Print horizontal line (using dashes)
  static List<int> horizontalLine([int width = 32, String char = '-']) {
    final line = char * width;
    return [...textToBytes(line), 0x0A];
  }

  // Convert text to bytes (Latin-1 encoding for printer compatibility)
  static List<int> textToBytes(String text) {
    try {
      return latin1.encode(text);
    } catch (e) {
      // Fallback to ASCII-safe characters
      return text.codeUnits.map((c) => c > 127 ? 0x3F : c).toList();
    }
  }

  // Print text with newline
  static List<int> printLine(String text) {
    return [...textToBytes(text), 0x0A];
  }

  // Print centered text
  static List<int> printCentered(String text, [int width = 32]) {
    final padding = ((width - text.length) / 2).floor();
    final paddedText = ' ' * padding + text;
    return [...textToBytes(paddedText), 0x0A];
  }

  // Print right-aligned text
  static List<int> printRight(String text, [int width = 32]) {
    final padding = width - text.length;
    final paddedText = ' ' * padding + text;
    return [...textToBytes(paddedText), 0x0A];
  }

  // Print two columns (left and right aligned)
  static List<int> printTwoColumns(
    String left,
    String right, [
    int width = 32,
  ]) {
    final space = width - left.length - right.length;
    final line = left + ' ' * (space > 0 ? space : 1) + right;
    return [...textToBytes(line), 0x0A];
  }

  // Print three columns
  static List<int> printThreeColumns(
    String left,
    String center,
    String right, [
    int width = 32,
  ]) {
    final leftWidth = (width * 0.5).floor();
    final centerWidth = (width * 0.2).floor();
    final rightWidth = width - leftWidth - centerWidth;

    String leftPart =
        left.length > leftWidth
            ? left.substring(0, leftWidth)
            : left.padRight(leftWidth);

    String centerPart =
        center.length > centerWidth
            ? center.substring(0, centerWidth)
            : center
                .padLeft((centerWidth + center.length) ~/ 2)
                .padRight(centerWidth);

    String rightPart =
        right.length > rightWidth
            ? right.substring(0, rightWidth)
            : right.padLeft(rightWidth);

    return [...textToBytes(leftPart + centerPart + rightPart), 0x0A];
  }
}

/// Connection type for thermal printer
enum PrinterConnectionType { bluetooth, wifi }

/// Printer connection status
enum PrinterStatus { disconnected, connecting, connected, printing, error }

/// Model for discovered printers
class DiscoveredPrinter {
  final String name;
  final String address;
  final PrinterConnectionType type;
  final BluetoothDevice? bluetoothDevice;

  DiscoveredPrinter({
    required this.name,
    required this.address,
    required this.type,
    this.bluetoothDevice,
  });

  @override
  String toString() => '$name ($address)';
}

/// Thermal Printer Service
/// Supports Bluetooth and WiFi connectivity for GOOJPRT PT-210 and similar ESC/POS printers
class ThermalPrinterService {
  static final ThermalPrinterService _instance =
      ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  // Connection state
  PrinterStatus _status = PrinterStatus.disconnected;
  DiscoveredPrinter? _connectedPrinter;
  BluetoothCharacteristic? _writeCharacteristic;
  Socket? _wifiSocket;

  // Streams
  final _statusController = StreamController<PrinterStatus>.broadcast();
  Stream<PrinterStatus> get statusStream => _statusController.stream;
  PrinterStatus get status => _status;
  DiscoveredPrinter? get connectedPrinter => _connectedPrinter;

  // Paper settings for GOOJPRT PT-210 (57mm paper, 48mm print width)
  static const int paperWidth = 384; // dots (48mm at 203 DPI)
  static const int charsPerLine = 32; // characters for normal font

  // SharedPreferences keys
  static const String _prefPrinterName = 'printer_name';
  static const String _prefPrinterAddress = 'printer_address';
  static const String _prefPrinterType = 'printer_type';

  /// Initialize the printer service
  Future<void> initialize() async {
    // Try to reconnect to last used printer
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString(_prefPrinterAddress);
    final savedType = prefs.getString(_prefPrinterType);
    final savedName = prefs.getString(_prefPrinterName);

    if (savedAddress != null && savedType != null && savedName != null) {
      debugPrint('[ThermalPrinter] Found saved printer: $savedName');
      // Don't auto-connect, just remember the settings
    }
  }

  /// Scan for Bluetooth printers
  Stream<List<DiscoveredPrinter>> scanBluetoothPrinters() async* {
    if (kIsWeb) {
      debugPrint('[ThermalPrinter] Bluetooth not supported on web');
      yield [];
      return;
    }

    final List<DiscoveredPrinter> printers = [];

    try {
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isSupported) {
        debugPrint('[ThermalPrinter] Bluetooth not supported on this device');
        yield [];
        return;
      }

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      await for (final results in FlutterBluePlus.scanResults) {
        printers.clear();
        for (final r in results) {
          if (r.device.platformName.isNotEmpty) {
            printers.add(
              DiscoveredPrinter(
                name: r.device.platformName,
                address: r.device.remoteId.str,
                type: PrinterConnectionType.bluetooth,
                bluetoothDevice: r.device,
              ),
            );
          }
        }
        yield printers;
      }
    } catch (e) {
      debugPrint('[ThermalPrinter] Scan error: $e');
      yield [];
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    if (!kIsWeb) {
      await FlutterBluePlus.stopScan();
    }
  }

  /// Connect to a Bluetooth printer
  Future<bool> connectBluetooth(DiscoveredPrinter printer) async {
    if (kIsWeb || printer.bluetoothDevice == null) return false;

    _setStatus(PrinterStatus.connecting);

    try {
      final device = printer.bluetoothDevice!;

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));

      // Discover services
      final services = await device.discoverServices();

      // Find the write characteristic (typically on service FFE0, characteristic FFE1)
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _writeCharacteristic = char;
            debugPrint(
              '[ThermalPrinter] Found write characteristic: ${char.uuid}',
            );
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }

      if (_writeCharacteristic == null) {
        debugPrint('[ThermalPrinter] No write characteristic found');
        await device.disconnect();
        _setStatus(PrinterStatus.error);
        return false;
      }

      _connectedPrinter = printer;
      _setStatus(PrinterStatus.connected);

      // Save printer info
      await _savePrinterInfo(printer);

      debugPrint('[ThermalPrinter] Connected to ${printer.name}');
      return true;
    } catch (e) {
      debugPrint('[ThermalPrinter] Connection error: $e');
      _setStatus(PrinterStatus.error);
      return false;
    }
  }

  /// Connect to a WiFi printer
  Future<bool> connectWifi(String ipAddress, {int port = 9100}) async {
    _setStatus(PrinterStatus.connecting);

    try {
      _wifiSocket = await Socket.connect(
        ipAddress,
        port,
        timeout: const Duration(seconds: 10),
      );

      _connectedPrinter = DiscoveredPrinter(
        name: 'WiFi Printer',
        address: '$ipAddress:$port',
        type: PrinterConnectionType.wifi,
      );

      _setStatus(PrinterStatus.connected);

      // Save printer info
      await _savePrinterInfo(_connectedPrinter!);

      debugPrint(
        '[ThermalPrinter] Connected to WiFi printer at $ipAddress:$port',
      );
      return true;
    } catch (e) {
      debugPrint('[ThermalPrinter] WiFi connection error: $e');
      _setStatus(PrinterStatus.error);
      return false;
    }
  }

  /// Disconnect from the current printer
  Future<void> disconnect() async {
    try {
      if (_connectedPrinter?.type == PrinterConnectionType.bluetooth) {
        await _connectedPrinter?.bluetoothDevice?.disconnect();
        _writeCharacteristic = null;
      } else if (_connectedPrinter?.type == PrinterConnectionType.wifi) {
        await _wifiSocket?.close();
        _wifiSocket = null;
      }
    } catch (e) {
      debugPrint('[ThermalPrinter] Disconnect error: $e');
    }

    _connectedPrinter = null;
    _setStatus(PrinterStatus.disconnected);
  }

  /// Print raw bytes to the printer
  Future<bool> printBytes(List<int> bytes) async {
    if (_status != PrinterStatus.connected) {
      debugPrint('[ThermalPrinter] Not connected');
      return false;
    }

    _setStatus(PrinterStatus.printing);

    try {
      if (_connectedPrinter?.type == PrinterConnectionType.bluetooth) {
        // Send via Bluetooth in chunks
        final chunkSize = 20; // BLE MTU typically 20 bytes
        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          final chunk = bytes.sublist(i, end);
          await _writeCharacteristic?.write(
            Uint8List.fromList(chunk),
            withoutResponse: true,
          );
          await Future.delayed(const Duration(milliseconds: 20));
        }
      } else if (_connectedPrinter?.type == PrinterConnectionType.wifi) {
        _wifiSocket?.add(Uint8List.fromList(bytes));
        await _wifiSocket?.flush();
      }

      _setStatus(PrinterStatus.connected);
      debugPrint('[ThermalPrinter] Print completed');
      return true;
    } catch (e) {
      debugPrint('[ThermalPrinter] Print error: $e');
      _setStatus(PrinterStatus.error);
      return false;
    }
  }

  /// Generate and print a receipt
  Future<bool> printReceipt(ReceiptData receipt) async {
    try {
      List<int> bytes = [];

      // Initialize printer
      bytes.addAll(EscPosCommands.initialize());

      // Store name (centered, bold, large)
      bytes.addAll(EscPosCommands.alignCenter());
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(EscPosCommands.largeTextOn());
      bytes.addAll(EscPosCommands.printLine(receipt.storeName));
      bytes.addAll(EscPosCommands.largeTextOff());
      bytes.addAll(EscPosCommands.lineFeed(1));

      // Order number
      bytes.addAll(EscPosCommands.doubleHeightOn());
      bytes.addAll(EscPosCommands.printLine('Order #${receipt.orderNumber}'));
      bytes.addAll(EscPosCommands.doubleHeightOff());
      bytes.addAll(EscPosCommands.boldOff());

      // Date and time
      bytes.addAll(EscPosCommands.printLine(receipt.dateTime));

      // Horizontal line
      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '='));

      // Pickup info
      if (receipt.pickupTime != null) {
        bytes.addAll(EscPosCommands.boldOn());
        bytes.addAll(EscPosCommands.printLine('Pickup: ${receipt.pickupTime}'));
        bytes.addAll(EscPosCommands.boldOff());
        bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '-'));
      }

      // Customer info
      bytes.addAll(EscPosCommands.alignLeft());
      if (receipt.customerName != null) {
        bytes.addAll(
          EscPosCommands.printLine('Customer: ${receipt.customerName}'),
        );
      }
      bytes.addAll(EscPosCommands.lineFeed(1));

      // Items header
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(
        EscPosCommands.printThreeColumns('Item', 'Qty', 'Price', charsPerLine),
      );
      bytes.addAll(EscPosCommands.boldOff());
      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '-'));

      // Items
      for (final item in receipt.items) {
        // Item name
        bytes.addAll(EscPosCommands.boldOn());
        bytes.addAll(EscPosCommands.printLine(item.name));
        bytes.addAll(EscPosCommands.boldOff());

        // Quantity and price
        final priceStr = 'P${item.price.toStringAsFixed(2)}';
        final qtyStr = 'x${item.quantity}';
        bytes.addAll(
          EscPosCommands.printThreeColumns('', qtyStr, priceStr, charsPerLine),
        );

        // Variations
        if (item.variations != null && item.variations!.isNotEmpty) {
          bytes.addAll(EscPosCommands.printLine('  ${item.variations}'));
        }

        // Choice groups
        if (item.choiceGroups != null && item.choiceGroups!.isNotEmpty) {
          bytes.addAll(EscPosCommands.printLine('  ${item.choiceGroups}'));
        }
      }

      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '-'));

      // Subtotal
      bytes.addAll(
        EscPosCommands.printTwoColumns(
          'Subtotal:',
          'P${receipt.subtotal.toStringAsFixed(2)}',
          charsPerLine,
        ),
      );

      // VAT (12%)
      bytes.addAll(
        EscPosCommands.printTwoColumns(
          'VAT (12%):',
          'P${receipt.vat.toStringAsFixed(2)}',
          charsPerLine,
        ),
      );

      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '-'));

      // Total (bold, larger)
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(EscPosCommands.doubleHeightOn());
      bytes.addAll(
        EscPosCommands.printTwoColumns(
          'TOTAL:',
          'P${receipt.total.toStringAsFixed(2)}',
          charsPerLine,
        ),
      );
      bytes.addAll(EscPosCommands.doubleHeightOff());
      bytes.addAll(EscPosCommands.boldOff());

      // Note
      if (receipt.note != null && receipt.note!.isNotEmpty) {
        bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '-'));
        bytes.addAll(EscPosCommands.printLine('Note: ${receipt.note}'));
      }

      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '='));

      // Footer
      bytes.addAll(EscPosCommands.alignCenter());
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(EscPosCommands.printLine('Thank you for your order!'));
      bytes.addAll(EscPosCommands.boldOff());
      bytes.addAll(EscPosCommands.printLine('Powered by BytePlus'));

      // Feed and cut
      bytes.addAll(EscPosCommands.lineFeed(3));
      bytes.addAll(EscPosCommands.cut());

      return await printBytes(bytes);
    } catch (e) {
      debugPrint('[ThermalPrinter] Receipt generation error: $e');
      return false;
    }
  }

  /// Print a test page
  Future<bool> printTestPage() async {
    try {
      List<int> bytes = [];

      // Initialize
      bytes.addAll(EscPosCommands.initialize());

      // Header
      bytes.addAll(EscPosCommands.alignCenter());
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(EscPosCommands.largeTextOn());
      bytes.addAll(EscPosCommands.printLine('TEST PRINT'));
      bytes.addAll(EscPosCommands.largeTextOff());
      bytes.addAll(EscPosCommands.boldOff());

      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '='));

      // Printer info
      bytes.addAll(EscPosCommands.alignLeft());
      bytes.addAll(
        EscPosCommands.printLine(
          'Printer: ${_connectedPrinter?.name ?? "Unknown"}',
        ),
      );
      bytes.addAll(
        EscPosCommands.printLine(
          'Connection: ${_connectedPrinter?.type.name ?? "Unknown"}',
        ),
      );
      bytes.addAll(
        EscPosCommands.printLine(
          'Time: ${DateTime.now().toString().substring(0, 19)}',
        ),
      );

      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '-'));

      // Text samples
      bytes.addAll(EscPosCommands.printLine('Normal text'));
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(EscPosCommands.printLine('Bold text'));
      bytes.addAll(EscPosCommands.boldOff());
      bytes.addAll(EscPosCommands.doubleHeightOn());
      bytes.addAll(EscPosCommands.printLine('Double height'));
      bytes.addAll(EscPosCommands.doubleHeightOff());

      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '-'));

      // Alignment tests
      bytes.addAll(EscPosCommands.alignLeft());
      bytes.addAll(EscPosCommands.printLine('Left aligned'));
      bytes.addAll(EscPosCommands.alignCenter());
      bytes.addAll(EscPosCommands.printLine('Center aligned'));
      bytes.addAll(EscPosCommands.alignRight());
      bytes.addAll(EscPosCommands.printLine('Right aligned'));

      bytes.addAll(EscPosCommands.alignCenter());
      bytes.addAll(EscPosCommands.horizontalLine(charsPerLine, '='));

      // Footer
      bytes.addAll(EscPosCommands.boldOn());
      bytes.addAll(EscPosCommands.printLine('BytePlus Canteen'));
      bytes.addAll(EscPosCommands.boldOff());
      bytes.addAll(EscPosCommands.printLine('Test Complete'));

      // Feed and cut
      bytes.addAll(EscPosCommands.lineFeed(3));
      bytes.addAll(EscPosCommands.cut());

      return await printBytes(bytes);
    } catch (e) {
      debugPrint('[ThermalPrinter] Test page error: $e');
      return false;
    }
  }

  /// Save printer info to SharedPreferences
  Future<void> _savePrinterInfo(DiscoveredPrinter printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPrinterName, printer.name);
    await prefs.setString(_prefPrinterAddress, printer.address);
    await prefs.setString(
      _prefPrinterType,
      printer.type == PrinterConnectionType.bluetooth ? 'bluetooth' : 'wifi',
    );
  }

  /// Clear saved printer info
  Future<void> clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPrinterName);
    await prefs.remove(_prefPrinterAddress);
    await prefs.remove(_prefPrinterType);
  }

  /// Get saved printer info
  Future<Map<String, String>?> getSavedPrinterInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefPrinterName);
    final address = prefs.getString(_prefPrinterAddress);
    final type = prefs.getString(_prefPrinterType);

    if (name != null && address != null && type != null) {
      return {'name': name, 'address': address, 'type': type};
    }
    return null;
  }

  void _setStatus(PrinterStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    _statusController.close();
    disconnect();
  }
}

/// Receipt data model
class ReceiptData {
  final String storeName;
  final String orderNumber;
  final String dateTime;
  final String? pickupTime;
  final String? customerName;
  final List<ReceiptItem> items;
  final double subtotal;
  final double vat; // 12% VAT (Philippines standard)
  final double total;
  final String? note;

  ReceiptData({
    required this.storeName,
    required this.orderNumber,
    required this.dateTime,
    this.pickupTime,
    this.customerName,
    required this.items,
    required this.subtotal,
    required this.vat,
    required this.total,
    this.note,
  });

  /// Calculate VAT from subtotal (12% VAT-exclusive)
  static double calculateVat(double subtotal) => subtotal * 0.12;

  /// Calculate total with VAT
  static double calculateVatInclusive(double subtotal) => subtotal * 1.12;
}

/// Receipt item model
class ReceiptItem {
  final String name;
  final int quantity;
  final double price;
  final String? variations;
  final String? choiceGroups;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.variations,
    this.choiceGroups,
  });
}
