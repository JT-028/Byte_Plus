// lib/pages/analytics_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/analytics_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String? storeId;
  String? merchantName;
  int selectedPeriod = 1; // 0: Today, 1: This Week, 2: This Month
  SalesSummary? summary;
  List<DailyRevenue>? customerHistory;
  Map<String, int>? productStats;
  bool isLoading = true;
  bool storeIdLoaded = false;
  String? errorMessage;

  final periodLabels = ['Today', 'This week', 'This month'];

  @override
  void initState() {
    super.initState();
    _loadStoreId();
  }

  Future<void> _loadStoreId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        storeIdLoaded = true;
        isLoading = false;
        errorMessage = 'Not logged in';
      });
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final loadedStoreId = userData?['storeId']?.toString();
        final name = userData?['name']?.toString() ?? 'Merchant';
        setState(() {
          storeId = (loadedStoreId?.isNotEmpty == true) ? loadedStoreId : null;
          merchantName = name;
          storeIdLoaded = true;
        });
        if (storeId != null) {
          _loadAnalytics();
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() {
          storeIdLoaded = true;
          isLoading = false;
          errorMessage = 'User profile not found';
        });
      }
    } catch (e) {
      setState(() {
        storeIdLoaded = true;
        isLoading = false;
        errorMessage = 'Failed to load store: $e';
      });
    }
  }

  Future<void> _loadAnalytics() async {
    if (storeId == null) return;

    setState(() => isLoading = true);

    try {
      SalesSummary data;
      switch (selectedPeriod) {
        case 0:
          data = await AnalyticsService.getTodaySummary(storeId!);
          break;
        case 1:
          data = await AnalyticsService.getWeekSummary(storeId!);
          break;
        case 2:
          data = await AnalyticsService.getMonthSummary(storeId!);
          break;
        default:
          data = await AnalyticsService.getWeekSummary(storeId!);
      }

      final customers = await AnalyticsService.getDailyCustomerHistory(
        storeId: storeId!,
        days: 7,
      );

      final prodStats = await AnalyticsService.getProductStats(storeId!);

      setState(() {
        summary = data;
        customerHistory = customers;
        productStats = prodStats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error loading analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child:
            !storeIdLoaded
                ? const Center(child: CircularProgressIndicator())
                : storeId == null
                ? _buildNoStoreMessage(isDark)
                : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreeting(isDark),
                        const SizedBox(height: 24),
                        _buildStoreReportsHeader(isDark),
                        const SizedBox(height: 16),
                        if (isLoading)
                          const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          _buildStatsGrid(isDark),
                          const SizedBox(height: 24),
                          _buildTopSellingProducts(isDark),
                          const SizedBox(height: 24),
                          _buildCustomersChart(isDark),
                          const SizedBox(height: 100),
                        ],
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildNoStoreMessage(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.chart,
              size: 80,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage ?? 'No Store Connected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Analytics will be available once your store is set up.',
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            children: [
              const TextSpan(text: 'Hello '),
              TextSpan(
                text: '$merchantName,',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's how your shop's doing",
          style: TextStyle(
            fontSize: 14,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStoreReportsHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Store Reports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedPeriod,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
              items: List.generate(
                periodLabels.length,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    periodLabels[i],
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedPeriod = val);
                  _loadAnalytics();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    final totalSales = summary?.totalItems ?? 0;
    final totalOrders = summary?.totalOrders ?? 0;
    final totalProducts = productStats?['totalProducts'] ?? 0;
    final outOfStock = productStats?['outOfStock'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statsCard(
                title: 'Sales',
                subtitle: 'Total Sales',
                value: totalSales.toString(),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statsCard(
                title: 'Orders',
                subtitle: 'Total orders',
                value: totalOrders.toString(),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statsCard(
                title: 'Total Products',
                subtitle: null,
                value: totalProducts.toString(),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statsCard(
                title: 'Out of stock',
                subtitle: null,
                value: outOfStock.toString(),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statsCard({
    required String title,
    String? subtitle,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? AppColors.borderDark : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingProducts(bool isDark) {
    final products = summary?.topProducts ?? [];
    final maxQty =
        products.isNotEmpty
            ? products.map((e) => e.quantity).reduce((a, b) => a > b ? a : b)
            : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? AppColors.borderDark : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Selling Products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Table header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Popularity',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'Sales',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No sales data yet',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...products.take(5).map((product) {
              final percentage =
                  maxQty > 0 ? ((product.quantity / maxQty) * 100).round() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: _popularityBar(percentage, isDark),
                    ),
                    SizedBox(
                      width: 50,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isDark
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '$percentage%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
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

  Widget _popularityBar(int percentage, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      height: 8,
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.borderDark : AppColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage / 100,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.merchantPrimary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomersChart(bool isDark) {
    if (customerHistory == null || customerHistory!.isEmpty) {
      return const SizedBox();
    }

    final maxCustomers = customerHistory!
        .map((e) => e.revenue.toInt())
        .reduce((a, b) => a > b ? a : b);
    final chartMax = maxCustomers > 0 ? maxCustomers : 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? AppColors.borderDark : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Y-axis labels and chart
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chartMax.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        (chartMax * 0.75).round().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        (chartMax * 0.5).round().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        (chartMax * 0.25).round().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bars
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children:
                        customerHistory!.map((day) {
                          final customers = day.revenue.toInt();
                          final barHeight =
                              chartMax > 0
                                  ? (customers / chartMax * 140).clamp(
                                    4.0,
                                    140.0,
                                  )
                                  : 4.0;
                          final isToday =
                              DateFormat('E').format(day.date) ==
                              DateFormat('E').format(DateTime.now());

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 24,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color:
                                          isToday
                                              ? AppColors.merchantPrimary
                                              : (isDark
                                                  ? AppColors.borderDark
                                                  : AppColors.border
                                                      .withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat(
                                      'E',
                                    ).format(day.date).substring(0, 3),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isDark
                                              ? AppColors.textTertiaryDark
                                              : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
