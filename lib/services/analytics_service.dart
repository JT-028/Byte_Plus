// lib/services/analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for generating sales reports and analytics.
/// Provides daily, weekly, and monthly summaries for merchants.
/// Now includes both active orders and archived orders for complete analytics.
class AnalyticsService {
  static final _firestore = FirebaseFirestore.instance;

  /// Helper to get orders from both active and archived collections
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getAllOrdersWithFilter({
    required String storeId,
    required String status,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Query active orders
    final activeOrders =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('orders')
            .where('status', isEqualTo: status)
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();

    // Query archived orders
    final archivedOrders =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('archivedOrders')
            .where('status', isEqualTo: status)
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .get();

    // Combine results
    return [...activeOrders.docs, ...archivedOrders.docs];
  }

  /// Get sales summary for a specific date range
  static Future<SalesSummary> getSalesSummary({
    required String storeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final orderDocs = await _getAllOrdersWithFilter(
      storeId: storeId,
      status: 'done',
      startDate: startDate,
      endDate: endDate,
    );

    double totalRevenue = 0;
    int totalOrders = orderDocs.length;
    int totalItems = 0;
    Map<String, int> productCounts = {};
    Map<String, double> productRevenue = {};
    Map<String, int> hourlyDistribution = {};

    for (var doc in orderDocs) {
      final data = doc.data();
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      totalRevenue += total;

      // Count items
      final items = data['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final qty = (item['qty'] as num?)?.toInt() ?? 1;
        final productName = item['name']?.toString() ?? 'Unknown';
        final lineTotal = (item['lineTotal'] as num?)?.toDouble() ?? 0;

        totalItems += qty;
        productCounts[productName] = (productCounts[productName] ?? 0) + qty;
        productRevenue[productName] =
            (productRevenue[productName] ?? 0) + lineTotal;
      }

      // Hourly distribution
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (timestamp != null) {
        final hour = timestamp.hour.toString().padLeft(2, '0');
        hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + 1;
      }
    }

    // Sort products by quantity sold
    final sortedProducts =
        productCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return SalesSummary(
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      totalItems: totalItems,
      averageOrderValue: totalOrders > 0 ? totalRevenue / totalOrders : 0,
      topProducts:
          sortedProducts
              .take(10)
              .map(
                (e) => TopProduct(
                  name: e.key,
                  quantity: e.value,
                  revenue: productRevenue[e.key] ?? 0,
                ),
              )
              .toList(),
      hourlyDistribution: hourlyDistribution,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get today's sales summary
  static Future<SalesSummary> getTodaySummary(String storeId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getSalesSummary(
      storeId: storeId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Get this week's sales summary
  static Future<SalesSummary> getWeekSummary(String storeId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final endDate = now;

    return getSalesSummary(
      storeId: storeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get this month's sales summary
  static Future<SalesSummary> getMonthSummary(String storeId) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = now;

    return getSalesSummary(
      storeId: storeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get daily revenue for the past N days (for chart)
  static Future<List<DailyRevenue>> getDailyRevenueHistory({
    required String storeId,
    int days = 7,
  }) async {
    final now = DateTime.now();
    final results = <DailyRevenue>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      // Query both active and archived orders
      final orderDocs = await _getAllOrdersWithFilter(
        storeId: storeId,
        status: 'done',
        startDate: date,
        endDate: nextDate,
      );

      double revenue = 0;
      for (var doc in orderDocs) {
        final total = (doc.data()['total'] as num?)?.toDouble() ?? 0;
        revenue += total;
      }

      results.add(
        DailyRevenue(
          date: date,
          revenue: revenue,
          orderCount: orderDocs.length,
        ),
      );
    }

    return results;
  }

  /// Get order status breakdown (includes both active and archived orders)
  static Future<Map<String, int>> getOrderStatusBreakdown(
    String storeId,
  ) async {
    // Get active orders
    final activeOrders =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('orders')
            .get();

    // Get archived orders (only done/cancelled)
    final archivedOrders =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('archivedOrders')
            .get();

    final counts = <String, int>{
      'to-do': 0,
      'in-progress': 0,
      'ready': 0,
      'done': 0,
      'cancelled': 0,
    };

    // Count active orders
    for (var doc in activeOrders.docs) {
      final status = doc.data()['status']?.toString() ?? 'to-do';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    // Add archived orders (only done/cancelled)
    for (var doc in archivedOrders.docs) {
      final status = doc.data()['status']?.toString() ?? 'done';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  /// Get total products and out of stock count for a store
  static Future<Map<String, int>> getProductStats(String storeId) async {
    final products =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('menu')
            .get();

    int totalProducts = products.docs.length;
    int outOfStock = 0;

    for (var doc in products.docs) {
      final data = doc.data();
      final available = data['available'] ?? true;
      final stock = (data['stock'] as num?)?.toInt() ?? -1;

      if (!available || stock == 0) {
        outOfStock++;
      }
    }

    return {'totalProducts': totalProducts, 'outOfStock': outOfStock};
  }

  /// Get daily customer/order count for the past 7 days (for chart)
  static Future<List<DailyRevenue>> getDailyCustomerHistory({
    required String storeId,
    int days = 7,
  }) async {
    final now = DateTime.now();
    final results = <DailyRevenue>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));

      // Query both active and archived orders
      final orderDocs = await _getAllOrdersWithFilter(
        storeId: storeId,
        status: 'done',
        startDate: date,
        endDate: nextDate,
      );

      // Count unique customers
      final Set<String> uniqueCustomers = {};
      for (var doc in orderDocs) {
        final customerId = doc.data()['userId']?.toString() ?? '';
        if (customerId.isNotEmpty) {
          uniqueCustomers.add(customerId);
        }
      }

      results.add(
        DailyRevenue(
          date: date,
          revenue: uniqueCustomers.length.toDouble(),
          orderCount: orderDocs.length,
        ),
      );
    }

    return results;
  }
}

/// Sales summary data model
class SalesSummary {
  final double totalRevenue;
  final int totalOrders;
  final int totalItems;
  final double averageOrderValue;
  final List<TopProduct> topProducts;
  final Map<String, int> hourlyDistribution;
  final DateTime startDate;
  final DateTime endDate;

  SalesSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalItems,
    required this.averageOrderValue,
    required this.topProducts,
    required this.hourlyDistribution,
    required this.startDate,
    required this.endDate,
  });
}

/// Top selling product model
class TopProduct {
  final String name;
  final int quantity;
  final double revenue;

  TopProduct({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

/// Daily revenue data point
class DailyRevenue {
  final DateTime date;
  final double revenue;
  final int orderCount;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });
}
