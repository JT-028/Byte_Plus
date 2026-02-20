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
  int selectedPeriod = 0; // 0: Today, 1: Week, 2: Month
  SalesSummary? summary;
  List<DailyRevenue>? revenueHistory;
  bool isLoading = true;
  bool storeIdLoaded = false;
  String? errorMessage;

  final periodLabels = ['Today', 'This Week', 'This Month'];

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
        final loadedStoreId = userDoc.data()?['storeId']?.toString();
        setState(() {
          storeId = (loadedStoreId?.isNotEmpty == true) ? loadedStoreId : null;
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
          data = await AnalyticsService.getTodaySummary(storeId!);
      }

      final history = await AnalyticsService.getDailyRevenueHistory(
        storeId: storeId!,
        days: 7,
      );

      setState(() {
        summary = data;
        revenueHistory = history;
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
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(isDark)),
                      SliverToBoxAdapter(child: _buildPeriodSelector(isDark)),
                      SliverToBoxAdapter(child: const SizedBox(height: 20)),
                      if (isLoading)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        SliverToBoxAdapter(child: _buildSummaryCards(isDark)),
                        SliverToBoxAdapter(child: const SizedBox(height: 24)),
                        SliverToBoxAdapter(child: _buildRevenueChart(isDark)),
                        SliverToBoxAdapter(child: const SizedBox(height: 24)),
                        SliverToBoxAdapter(child: _buildTopProducts(isDark)),
                        SliverToBoxAdapter(child: const SizedBox(height: 24)),
                        SliverToBoxAdapter(
                          child: _buildHourlyDistribution(isDark),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ],
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your store performance',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAnalytics,
            icon: Icon(
              Iconsax.refresh,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (i) {
          final selected = selectedPeriod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => selectedPeriod = i);
                _loadAnalytics();
              },
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? AppColors.merchantPrimary
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      selected
                          ? [
                            BoxShadow(
                              color: AppColors.merchantPrimary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  periodLabels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        selected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    if (summary == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              title: 'Revenue',
              value: '₱${summary!.totalRevenue.toStringAsFixed(0)}',
              icon: Iconsax.wallet_2,
              color: AppColors.success,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              title: 'Orders',
              value: summary!.totalOrders.toString(),
              icon: Iconsax.receipt_2,
              color: AppColors.merchantPrimary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard(
              title: 'Avg Order',
              value: '₱${summary!.averageOrderValue.toStringAsFixed(0)}',
              icon: Iconsax.chart,
              color: AppColors.warning,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(bool isDark) {
    if (revenueHistory == null || revenueHistory!.isEmpty) {
      return const SizedBox();
    }

    final maxRevenue = revenueHistory!
        .map((e) => e.revenue)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue (Last 7 Days)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  revenueHistory!.map((day) {
                    final height =
                        maxRevenue > 0 ? (day.revenue / maxRevenue * 120) : 0.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (day.revenue > 0)
                              Text(
                                '₱${day.revenue.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color:
                                      isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              height: height.toDouble().clamp(4.0, 120.0),
                              decoration: BoxDecoration(
                                color: AppColors.merchantPrimary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('E').format(day.date),
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
    );
  }

  Widget _buildTopProducts(bool isDark) {
    if (summary == null || summary!.topProducts.isEmpty) {
      return _emptySection('No sales data yet', isDark);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...summary!.topProducts.take(5).map((product) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.merchantPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Iconsax.box_1,
                      color: AppColors.merchantPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${product.quantity} sold',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₱${product.revenue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
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

  Widget _buildHourlyDistribution(bool isDark) {
    if (summary == null || summary!.hourlyDistribution.isEmpty) {
      return const SizedBox();
    }

    final sortedHours =
        summary!.hourlyDistribution.entries.toList()
          ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders by Hour',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                sortedHours.map((entry) {
                  final hour = int.parse(entry.key);
                  final count = entry.value;
                  final timeLabel =
                      hour == 0
                          ? '12 AM'
                          : hour < 12
                          ? '$hour AM'
                          : hour == 12
                          ? '12 PM'
                          : '${hour - 12} PM';

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.merchantPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$timeLabel: $count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.merchantPrimary,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _emptySection(String message, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
