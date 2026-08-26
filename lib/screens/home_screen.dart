import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';
import 'package:jharudyam_citizen/providers/problems_provider.dart';
import 'package:jharudyam_citizen/screens/create_report_screen.dart';
import 'package:jharudyam_citizen/screens/problem_detail_screen.dart';
import 'package:jharudyam_citizen/widgets/problem_card.dart';
import 'package:jharudyam_citizen/widgets/category_chips.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initial data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProblemsProvider>().fetchAllProblems();
      context.read<ProblemsProvider>().fetchMyReports();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final provider = context.read<ProblemsProvider>();
    if (_tabController.index == 0) {
      provider.fetchAllProblems();
    } else {
      provider.fetchMyReports();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance, size: 22),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JharUdyam',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Jharkhand Civic Desk',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.primaryDark,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'All Issues'),
                Tab(text: 'My Reports'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) {
                context.read<ProblemsProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search issues...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Category chips (only for All Issues tab)
          Consumer<ProblemsProvider>(
            builder: (context, provider, _) {
              return CategoryChips(
                selectedCategory: provider.selectedCategory,
                onSelected: (category) {
                  provider.setCategory(category);
                },
              );
            },
          ),
          const SizedBox(height: 8),
          // Feed body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeed(isMyReports: false),
                _buildFeed(isMyReports: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateReportScreen(),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text(
          'Report Issue',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFeed({required bool isMyReports}) {
    return Consumer<ProblemsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        final problems =
            isMyReports ? provider.myReports : provider.allProblems;

        if (problems.isEmpty) {
          return _buildEmptyState(isMyReports);
        }

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            if (isMyReports) {
              await provider.fetchMyReports();
            } else {
              await provider.fetchAllProblems();
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 80),
            itemCount: problems.length,
            itemBuilder: (context, index) {
              final problem = problems[index];
              return ProblemCard(
                problem: problem,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProblemDetailScreen(problem: problem),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isMyReports) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMyReports
                  ? Icons.assignment_outlined
                  : Icons.explore_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isMyReports
                  ? 'No reports yet'
                  : 'No issues found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMyReports
                  ? 'Tap the "Report Issue" button to submit your first civic report.'
                  : 'No civic issues have been reported in this category yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
