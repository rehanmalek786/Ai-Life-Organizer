import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../theme/app_theme.dart';

const _expenseCategories = ['Food', 'Transport', 'Bills', 'Shopping', 'Entertainment', 'Health', 'Other'];
const _incomeCategories = ['Salary', 'Freelance', 'Gift', 'Other'];

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});
  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final _fs = FirestoreService();

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionForm(fs: _fs),
    );
  }

  bool _isThisMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Money Organizer')),
      floatingActionButton: FloatingActionButton(onPressed: _openForm, child: const Icon(Icons.add)),
      body: StreamBuilder<List<TransactionItem>>(
        stream: _fs.transactionsStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final all = snap.data!;
          final thisMonth = all.where((t) => _isThisMonth(t.date)).toList();
          final income = thisMonth.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
          final expense = thisMonth.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This month', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(currency.format(income - expense), style: theme.textTheme.displayLarge?.copyWith(fontSize: 34)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _StatChip(label: 'Income', value: currency.format(income), color: AppColors.success),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatChip(label: 'Expense', value: currency.format(expense), color: AppColors.priorityHigh),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(title: 'Recent transactions'),
              if (all.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'No transactions yet', subtitle: 'Tap + to log income or an expense.'),
                )
              else
                ...all.take(50).map((t) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (t.type == 'income' ? AppColors.success : AppColors.priorityHigh).withValues(alpha: 0.15),
                          child: Icon(t.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                              color: t.type == 'income' ? AppColors.success : AppColors.priorityHigh, size: 18),
                        ),
                        title: Text(t.category),
                        subtitle: Text(t.note.isEmpty ? DateFormat('d MMM').format(t.date) : '${t.note} • ${DateFormat('d MMM').format(t.date)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${t.type == 'income' ? '+' : '-'}${currency.format(t.amount)}',
                              style: TextStyle(fontWeight: FontWeight.w700, color: t.type == 'income' ? AppColors.success : AppColors.priorityHigh),
                            ),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _fs.deleteTransaction(t.id)),
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}

class _TransactionForm extends StatefulWidget {
  final FirestoreService fs;
  const _TransactionForm({required this.fs});
  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  String _type = 'expense';
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = _expenseCategories.first;
  DateTime _date = DateTime.now();

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    widget.fs.addTransaction(TransactionItem(
      id: '',
      type: _type,
      amount: amount,
      category: _category,
      note: _noteCtrl.text.trim(),
      date: _date,
      createdAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'income' ? _incomeCategories : _expenseCategories;
    if (!categories.contains(_category)) _category = categories.first;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(label: const Text('Expense'), selected: _type == 'expense', onSelected: (_) => setState(() => _type = 'expense')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(label: const Text('Income'), selected: _type == 'income', onSelected: (_) => setState(() => _type = 'income')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _amountCtrl, label: 'Amount', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: categories
                  .map((c) => ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _noteCtrl, label: 'Note (optional)'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

