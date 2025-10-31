import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/expense.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  List<Expense> _expenses = [];
  double _totalExpenses = 0.0;
  double? _budget;
  double _remainingBudget = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_authService.currentUser == null) return;

    try {
      // Load budget
      _budget = await _authService.getUserBudget();

      // Load expenses
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
        _remainingBudget = (_budget ?? 0.0) - _totalExpenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> _setBudget() async {
    final TextEditingController budgetController = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(budgetController.text);
              if (budget != null && budget > 0) {
                Navigator.of(context).pop(budget);
              }
            },
            child: const Text('Set Budget'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _authService.setUserBudget(result);
      setState(() {
        _budget = result;
        _remainingBudget = result - _totalExpenses;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget set successfully!')));
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackify'),
        actions: [
          IconButton(
            onPressed: () async {
              await _authService.signOut();
              // Navigation will be handled by auth state listener
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Budget Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.8),
                          const Color(0xFF8B5CF6).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Monthly Budget',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: _setBudget,
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                tooltip: 'Set Budget',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_budget == null) ...[
                            const Text(
                              'No budget set',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _setBudget,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6366F1),
                                elevation: 2,
                              ),
                              child: const Text('Set Your Budget'),
                            ),
                          ] else ...[
                            // Budget Progress Bar
                            LinearProgressIndicator(
                              value: _budget! > 0
                                  ? (_totalExpenses / _budget!).clamp(0.0, 1.0)
                                  : 0,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _remainingBudget >= 0
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Budget',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '\$${_budget!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Remaining',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '\$${_remainingBudget.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: _remainingBudget >= 0
                                              ? Colors.green.shade300
                                              : Colors.red.shade300,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Spent',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        '\$${_totalExpenses.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Stats Row
                  if (_expenses.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Spent',
                            '\$${_totalExpenses.toStringAsFixed(2)}',
                            Icons.account_balance_wallet,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'This Month',
                            '${_expenses.where((e) => e.date.month == DateTime.now().month).length}',
                            Icons.calendar_month,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Avg/Day',
                            _expenses.isNotEmpty
                                ? '\$${(_totalExpenses / _expenses.length).toStringAsFixed(1)}'
                                : '\$0',
                            Icons.trending_up,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildActionButton(
                        'Add Expense',
                        Icons.add_circle_outline,
                        Colors.green,
                        () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/add-expense',
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                      ),
                      _buildActionButton(
                        'View Expenses',
                        Icons.receipt_long,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/view-expenses'),
                      ),
                      _buildActionButton(
                        'Add Category',
                        Icons.category_outlined,
                        Colors.purple,
                        () => Navigator.pushNamed(context, '/add-category'),
                      ),
                      if (_expenses.isNotEmpty)
                        _buildActionButton(
                          'View Chart',
                          Icons.pie_chart_outline,
                          Colors.orange,
                          () => Navigator.pushNamed(context, '/expense-chart'),
                        )
                      else
                        _buildActionButton(
                          'Get Started',
                          Icons.rocket_launch,
                          Colors.teal,
                          () async {
                            final result = await Navigator.pushNamed(
                              context,
                              '/add-expense',
                            );
                            if (result == true) {
                              _loadData();
                            }
                          },
                        ),
                    ],
                  ),

                  // Empty State
                  if (_expenses.isEmpty) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start tracking your expenses to see insights here',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
