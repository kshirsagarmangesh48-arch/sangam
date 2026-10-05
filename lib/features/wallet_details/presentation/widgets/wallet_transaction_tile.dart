import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';

class WalletTransactionTile extends StatelessWidget {
  final SangamTransaction transaction;

  const WalletTransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? familyTheme.success : colors.error;
    final iconColor = isIncome ? familyTheme.success : colors.error;
    final iconBgColor =
        isIncome ? familyTheme.successContainer : colors.errorContainer;

    final formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date);

    final memberDetails = <String>[];
    if (transaction.spentBy != null) {
      memberDetails.add('For: ${transaction.spentBy!.name}');
    }
    if (transaction.paidBy != null) {
      memberDetails.add('Paid by: ${transaction.paidBy!.name}');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income / Expense Indicator Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Middle: Category, Description, and Member metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category?.name ??
                        (isIncome ? 'General Income' : 'General Expense'),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (transaction.description != null &&
                      transaction.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.description!,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (memberDetails.isNotEmpty)
                    Text(
                      memberDetails.join(' • '),
                      style: text.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount with Sign (+ / -)
            Text(
              isIncome
                  ? '+${CurrencyFormatter.format(transaction.amount)}'
                  : '-${CurrencyFormatter.format(transaction.amount)}',
              style: text.titleMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
