import 'package:flutter/material.dart';
import 'package:jharudyam_citizen/constants/app_constants.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';

class CategoryChips extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const CategoryChips({
    super.key,
    this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categoryFilters[index];
          final isSelected = (selectedCategory == null && category == 'All') ||
              selectedCategory == category;

          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            selectedColor: AppTheme.primaryColor,
            backgroundColor: AppTheme.primaryTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}
