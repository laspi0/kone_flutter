part of '../cash_journal_screen.dart';

class _CashSessionCard extends StatelessWidget {
  final CashSessionSummary summary;
  final bool isAdmin;
  final void Function(int sessionId) onDelete;

  const _CashSessionCard({
    required this.summary,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final session = summary.session;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isOpen = session.status == 'open';
    final closingAmount = session.closingAmount;
    final expectedAmount = summary.expectedAmount;
    final difference = session.difference;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Session #${session.id ?? '-'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isAdmin && session.id != null) ...[
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(session.id!),
                ),
                const SizedBox(width: 4),
              ],
              _StatusPill(status: session.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                'Ouverture: ${dateFormat.format(session.openedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.lock_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                session.closedAt != null
                    ? 'Cloture: ${dateFormat.format(session.closedAt!)}'
                    : 'Cloture: en cours',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.receipt_long_outlined,
                label: '${summary.totalCount} vente${summary.totalCount > 1 ? 's' : ''}',
              ),
              _InfoChip(
                icon: Icons.account_balance_wallet_outlined,
                label:
                    'Ouverture ${session.openingAmount.toStringAsFixed(0)} FCFA',
              ),
              _InfoChip(
                icon: Icons.payments_outlined,
                label: closingAmount == null
                    ? 'Comptage: en cours'
                    : 'Comptage ${closingAmount.toStringAsFixed(0)} FCFA',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TotalsGrid(summary: summary),
          const SizedBox(height: 12),
          _DifferenceRow(
            isOpen: isOpen,
            difference: difference,
          ),
        ],
      ),
    );
  }
}

class _TotalsGrid extends StatelessWidget {
  final CashSessionSummary summary;

  const _TotalsGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _TotalItem(
          label: 'Ventes',
          value: summary.totalSales,
          icon: Icons.shopping_bag_outlined,
        ),
        _TotalItem(
          label: 'Encaisse',
          value: summary.totalReceived,
          icon: Icons.payments_outlined,
        ),
        _TotalItem(
          label: 'Monnaie rendue',
          value: summary.totalChange,
          icon: Icons.currency_exchange,
        ),
        _TotalItem(
          label: 'Attendu',
          value: summary.expectedAmount,
          icon: Icons.analytics_outlined,
        ),
      ],
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _TotalItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(0)} FCFA',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifferenceRow extends StatelessWidget {
  final bool isOpen;
  final double? difference;

  const _DifferenceRow({
    required this.isOpen,
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    if (isOpen) {
      return Text(
        'Ecart: session en cours',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    final diff = difference ?? 0;
    final isPositive = diff >= 0;
    final color = isPositive
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    final sign = isPositive ? '+' : '-';

    return Row(
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          'Ecart: $sign${diff.abs().toStringAsFixed(0)} FCFA',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'open';
    final bg = isOpen
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.secondaryContainer;
    final fg = isOpen
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Ouverte' : 'Cloturee',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
