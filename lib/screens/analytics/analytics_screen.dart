import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../theme/app_theme.dart';

const _categoryColors = [
  AppColors.priorityHigh,
  AppColors.priorityMedium,
  AppColors.priorityLow,
  AppColors.primary,
  AppColors.accent,
  AppColors.success,
  Color(0xFF9D8DF1),
];

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          StreamBuilder<List<TaskItem>>(
            stream: fs.tasksStream(),
            builder: (context, taskSnap) {
              final tasks = taskSnap.data ?? [];
              final completed = tasks.where((t) => t.completed).length;
              return StreamBuilder<List<GoalItem>>(
                stream: fs.goalsStream(),
                builder: (context, goalSnap) {
                  final goals = goalSnap.data ?? [];
                  final avgProgress = goals.isEmpty ? 0 : goals.map((g) => g.progress).reduce((a, b) => a + b) ~/ goals.length;
                  return StreamBuilder<List<HabitItem>>(
                    stream: fs.habitsStream(),
                    builder: (context, habitSnap) {
                      final habits = habitSnap.data ?? [];
                      final bestStreak = habits.isEmpty ? 0 : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _StatCard(label: 'Tasks completed', value: '$completed / ${tasks.length}', icon: Icons.checklist_rounded),
                          _StatCard(label: 'Avg goal progress', value: '$avgProgress%', icon: Icons.flag_outlined),
                          _StatCard(label: 'Best habit streak', value: '$bestStreak days', icon: Icons.local_fire_department_outlined),
                          _StatCard(label: 'Active habits', value: '${habits.length}', icon: Icons.repeat_rounded),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          StreamBuilder<List<TransactionItem>>(
            stream: fs.transactionsStream(),
            builder: (context, snap) {
              final txns = (snap.data ?? []).where((t) => t.date.year == now.year && t.date.month == now.month).toList();
              final income = txns.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
              final expense = txns.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
              final byCategory = <String, double>{};
              for (final t in txns.where((t) => t.type == 'expense')) {
                byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'This month: income vs expense'),
                  if (income == 0 && expense == 0)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No transactions logged yet this month.'))
                  else
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (income > expense ? income : expense) * 1.2 + 1,
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(value == 0 ? 'Income' : 'Expense', style: theme.textTheme.bodySmall),
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: income, color: AppColors.success, width: 40, borderRadius: BorderRadius.circular(8))]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: expense, color: AppColors.priorityHigh, width: 40, borderRadius: BorderRadius.circular(8))]),
                          ],
                        ),
                      ),
                    ),
                  if (byCategory.isNotEmpty) ...[
                    const SectionHeader(title: 'Expense by category'),
                    SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sections: byCategory.entries.toList().asMap().entries.map((e) {
                                  final color = _categoryColors[e.key % _categoryColors.length];
                                  return PieChartSectionData(value: e.value.value, color: color, title: '', radius: 60);
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 30,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: byCategory.entries.toList().asMap().entries.map((e) {
                                final color = _categoryColors[e.key % _categoryColors.length];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text('${e.value.key} • ${currency.format(e.value.value)}', style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

