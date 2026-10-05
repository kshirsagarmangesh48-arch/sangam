import 'package:flutter/material.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';

class MemberDistributionCard extends StatelessWidget {
  final List<MemberDistribution> distribution;

  const MemberDistributionCard({
    super.key,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    if (distribution.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'No family member distribution recorded yet.',
          style: text.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Distribution per Family Member',
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: distribution.length,
            separatorBuilder: (context, index) => Divider(
              height: 12,
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final item = distribution[index];
              final isPositive = item.isPositive;
              final amountColor =
                  isPositive ? familyTheme.success : colors.error;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isPositive
                          ? familyTheme.successContainer
                          : colors.errorContainer,
                      child: Text(
                        item.memberName.isNotEmpty
                            ? item.memberName[0].toUpperCase()
                            : '?',
                        style: text.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.memberName,
                        style: text.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.formatWithSign(item.total),
                      style: text.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
