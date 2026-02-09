import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/empty_state.dart';

part 'cash_journal/cash_journal_widgets.dart';

class CashJournalScreen extends StatefulWidget {
  const CashJournalScreen({super.key});

  @override
  State<CashJournalScreen> createState() => _CashJournalScreenState();
}

class _CashJournalScreenState extends State<CashJournalScreen> {
  int _daysFilter = 7;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) const AppSidebar(currentPage: '/cash-journal'),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Column(
                  children: [
                    _buildHeader(context, isDesktop),
                    Expanded(
                      child: FutureBuilder<List<CashSessionSummary>>(
                        future: auth.getCashSessionSummaries(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Erreur: ${snapshot.error}'),
                            );
                          }
                          final summaries = snapshot.data ?? [];
                          final filtered = _applyFilter(summaries, _daysFilter);
                          if (filtered.isEmpty) {
                            return const EmptyState(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Aucune session de caisse',
                              subtitle: 'Les sessions apparaitront ici apres ouverture.',
                            );
                          }
                          final isAdmin = auth.currentUser?.isAdmin ?? false;
                          return _buildSessionsList(filtered, isAdmin: isAdmin);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Journal de caisse',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Resume des sessions et totaux',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildFilterChips(context),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _FilterChip(
          label: 'Aujourd\'hui',
          selected: _daysFilter == 1,
          onTap: () => setState(() => _daysFilter = 1),
        ),
        _FilterChip(
          label: '7 jours',
          selected: _daysFilter == 7,
          onTap: () => setState(() => _daysFilter = 7),
        ),
        _FilterChip(
          label: '30 jours',
          selected: _daysFilter == 30,
          onTap: () => setState(() => _daysFilter = 30),
        ),
      ],
    );
  }

  List<CashSessionSummary> _applyFilter(
    List<CashSessionSummary> items,
    int days,
  ) {
    final from = DateTime.now().subtract(Duration(days: days));
    return items.where((s) => s.session.openedAt.isAfter(from)).toList();
  }

  Widget _buildSessionsList(
    List<CashSessionSummary> summaries, {
    required bool isAdmin,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return _CashSessionCard(
          summary: summary,
          isAdmin: isAdmin,
          onDelete: (sessionId) => _confirmDelete(context, sessionId),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: summaries.length,
    );
  }

  Future<void> _confirmDelete(BuildContext context, int sessionId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la session'),
        content: const Text(
          'Cette action supprime la session du journal. Les ventes restent conservees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await context.read<AuthProvider>().deleteCashSession(sessionId);
      if (mounted) {
        setState(() {});
      }
    }
  }
}
