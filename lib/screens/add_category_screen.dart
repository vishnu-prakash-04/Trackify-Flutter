import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/category.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final AuthService _authService = AuthService();

  String _selectedColor = '#FF6B6B'; // Default red color
  String _selectedIcon = 'shopping_cart'; // Default icon
  bool _isLoading = false;

  final List<Map<String, String>> _colors = [
    {'name': 'Red', 'value': '#FF6B6B'},
    {'name': 'Blue', 'value': '#4ECDC4'},
    {'name': 'Green', 'value': '#45B7D1'},
    {'name': 'Purple', 'value': '#9B59B6'},
    {'name': 'Orange', 'value': '#F39C12'},
    {'name': 'Pink', 'value': '#E91E63'},
    {'name': 'Teal', 'value': '#009688'},
    {'name': 'Indigo', 'value': '#3F51B5'},
  ];

  final List<Map<String, String>> _icons = [
    {'name': 'Food', 'value': 'restaurant'},
    {'name': 'Shopping', 'value': 'shopping_cart'},
    {'name': 'Transport', 'value': 'directions_car'},
    {'name': 'Entertainment', 'value': 'movie'},
    {'name': 'Bills', 'value': 'receipt'},
    {'name': 'Healthcare', 'value': 'local_hospital'},
    {'name': 'Education', 'value': 'school'},
    {'name': 'Other', 'value': 'category'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate() && _authService.currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final category = Category(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _authService.currentUser!.uid,
          name: _nameController.text.trim(),
          color: _selectedColor,
          icon: _selectedIcon,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('categories')
            .doc(category.id)
            .set(category.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully!')),
        );

        // Clear form
        _nameController.clear();
        setState(() {
          _selectedColor = '#FF6B6B';
          _selectedIcon = 'shopping_cart';
        });

        // Navigate back to home
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding category: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category'), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Category',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Customize your expense category',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Category Name',
                            prefixIcon: Icon(
                              Icons.edit,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a category name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Choose Color',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _colors.map((color) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = color['value']!;
                                });
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse(
                                          color['value']!.replaceFirst('#', ''),
                                          radix: 16,
                                        ) +
                                        0xFF000000,
                                  ),
                                  shape: BoxShape.circle,
                                  border: _selectedColor == color['value']
                                      ? Border.all(
                                          color: const Color(0xFF6366F1),
                                          width: 3,
                                        )
                                      : Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                  boxShadow: _selectedColor == color['value']
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Choose Icon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _icons.map((icon) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon['value']!;
                                });
                              },
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: _selectedIcon == icon['value']
                                      ? const Color(0xFF6366F1).withOpacity(0.1)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _selectedIcon == icon['value']
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey.shade300,
                                    width: _selectedIcon == icon['value']
                                        ? 2
                                        : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: _selectedIcon == icon['value']
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  _getIconData(icon['value']!),
                                  size: 32,
                                  color: _selectedIcon == icon['value']
                                      ? const Color(0xFF6366F1)
                                      : Colors.grey,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveCategory,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Save Category',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'category':
      default:
        return Icons.category;
    }
  }
}
