import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/expense.dart';
import 'dart:async';

class ExpenseChartScreen extends StatefulWidget {
  const ExpenseChartScreen({super.key});

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  List<Expense> _expenses = [];
  double _totalExpenses = 0.0;
  bool _isLoading = true;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadExpenses();
  }

  void _initializeAnimations() {
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chartAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Start fade animation
    _fadeController.forward();

    // Start chart animation after a delay
    Timer(const Duration(milliseconds: 500), () {
      _chartAnimationController.forward();
    });
  }

  Future<void> _loadExpenses() async {
    if (_authService.currentUser == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: _authService.currentUser!.uid)
          .get();

      setState(() {
        _expenses = snapshot.docs
            .map((doc) => Expense.fromDocument(doc))
            .toList();
        _totalExpenses = _expenses.fold(
          0.0,
          (sum, expense) => sum + expense.amount,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading expenses: $e')));
    }
  }

  Map<String, double> _getCategoryTotals() {
    Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  Color _getColorForCategory(String category) {
    final colors = [
      const Color(0xFF6366F1), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF97316), // Orange
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
    ];
    final index = category.hashCode % colors.length;
    return colors[index];
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String _chartType = 'pie'; // 'pie' or 'bar'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Chart'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _chartType = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'pie',
                child: Text('Pie Chart'),
              ),
              const PopupMenuItem<String>(
                value: 'bar',
                child: Text('Bar Chart'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
          ? const Center(
              child: Text(
                'No expenses to display',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expenses by Category',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Total Expenses: \$${_totalExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: _chartType == 'pie'
                          ? AnimatedBuilder(
                              animation: _chartAnimation,
                              builder: (context, child) {
                                return PieChart(
                                  PieChartData(
                                    sections: _getCategoryTotals().entries.map((
                                      entry,
                                    ) {
                                      final percentage = (_totalExpenses > 0)
                                          ? (entry.value / _totalExpenses) * 100
                                          : 0;
                                      return PieChartSectionData(
                                        value: entry.value,
                                        title:
                                            '${entry.key}\n${percentage.toStringAsFixed(1)}%',
                                        radius: 80 * _chartAnimation.value,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        color: _getColorForCategory(entry.key),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            )
                          : AnimatedBuilder(
                              animation: _chartAnimation,
                              builder: (context, child) {
                                return BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY:
                                        _getCategoryTotals().values.reduce(
                                          (a, b) => a > b ? a : b,
                                        ) *
                                        1.2,
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                              final category =
                                                  _getCategoryTotals().keys
                                                      .elementAt(groupIndex);
                                              final value = rod.toY;
                                              final percentage =
                                                  (_totalExpenses > 0)
                                                  ? (value / _totalExpenses) *
                                                        100
                                                  : 0;
                                              return BarTooltipItem(
                                                '$category\n\$${value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                                const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final categories =
                                                _getCategoryTotals().keys
                                                    .toList();
                                            if (value.toInt() <
                                                categories.length) {
                                              return Text(
                                                categories[value.toInt()],
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                    barGroups: _getCategoryTotals().entries.map(
                                      (entry) {
                                        final index = _getCategoryTotals().keys
                                            .toList()
                                            .indexOf(entry.key);
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY:
                                                  entry.value *
                                                  _chartAnimation.value,
                                              color: _getColorForCategory(
                                                entry.key,
                                              ),
                                              width: 20,
                                            ),
                                          ],
                                        );
                                      },
                                    ).toList(),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Category Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._getCategoryTotals().entries.map((entry) {
                      final percentage = (_totalExpenses > 0)
                          ? (entry.value / _totalExpenses) * 100
                          : 0;
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            // Highlight category in chart
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${entry.key}: \$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getColorForCategory(entry.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\$${entry.value.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement export/share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Export functionality coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Export Chart'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
