import 'package:flutter/material.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';

class CategoryChips extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onSelected;
  final List<String> categories;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
    this.categories = const ['All'],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = (cat == 'All' && selectedCategory == null) || cat == selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (_) => onSelected(cat),
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
