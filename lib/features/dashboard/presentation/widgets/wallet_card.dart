import 'package:flutter/material.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/core/utils/currency_formatter.dart';
import '../../data/models/account_model.dart';

class WalletCard extends StatelessWidget {
  final SangamAccount account;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.account,
    this.onTap,
  });

  IconData _resolveWalletIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cash')) {
      return Icons.payments_outlined;
    }
    if (lower.contains('bank') ||
        lower.contains('sbi') ||
        lower.contains('hdfc') ||
        lower.contains('icici') ||
        lower.contains('axis')) {
      return Icons.account_balance_outlined;
    }
    if (lower.contains('card') || lower.contains('credit')) {
      return Icons.credit_card_outlined;
    }
    if (lower.contains('pay') || lower.contains('upi')) {
      return Icons.qr_code_rounded;
    }
    return Icons.account_balance_wallet_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    // Green for positive (>= 0), Red for deficit (< 0)
    final isNegative = account.isNegative;
    final balanceColor = isNegative ? colors.error : familyTheme.success;
    final balanceBgColor =
        isNegative ? colors.errorContainer : familyTheme.successContainer;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Wallet Icon & Deficit Badge (shown when balance is negative)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _resolveWalletIcon(account.name),
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  if (isNegative)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: balanceBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: balanceColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Deficit',
                            style: text.bodySmall?.copyWith(
                              color: balanceColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Middle: Wallet Name & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      account.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (account.description != null &&
                        account.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.description!,
                        style: text.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Bottom: Balance / Deficit Label & Prominent Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNegative ? 'Deficit' : 'Balance',
                    style: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: isNegative ? colors.error : colors.onSurfaceVariant,
                      fontWeight: isNegative ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.format(account.balance),
                      style: text.headlineSmall?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
