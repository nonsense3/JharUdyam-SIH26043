import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/providers/problems_provider.dart';
import 'package:jharudyam_citizen/screens/problem_detail_screen.dart';
import 'package:jharudyam_citizen/widgets/problem_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProblemsProvider>();
      provider.fetchAllProblems();
      provider.fetchActiveCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jhar Udayam', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            Text('Jharkhand Civic Desk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => context.read<ProblemsProvider>().setSearchQuery(v),
              decoration: InputDecoration(
                hintText: 'Search issues...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
              ),
            ),
          ),
          // Dynamic category chips
          Consumer<ProblemsProvider>(
            builder: (context, provider, _) {
              final categories = ['All', ...provider.activeCategories];
              final selected = provider.selectedCategory;
              return SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = (cat == 'All' && selected == null) || cat == selected;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => provider.setCategory(cat),
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
            },
          ),
          const SizedBox(height: 8),
          // Feed
          Expanded(
            child: Consumer<ProblemsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }
                final problems = provider.allProblems;
                if (problems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No issues found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        Text('No civic issues in this category yet.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () => provider.refreshAll(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: problems.length,
                    itemBuilder: (context, index) {
                      return ProblemCard(
                        problem: problems[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProblemDetailScreen(problem: problems[index])),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
