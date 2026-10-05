import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_model.dart';

class CategorySpendData {
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;

  const CategorySpendData({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class CategoryExpensePieChartCard extends StatefulWidget {
  final List<SangamTransaction> transactions;

  const CategoryExpensePieChartCard({
    super.key,
    required this.transactions,
  });

  @override
  State<CategoryExpensePieChartCard> createState() =>
      _CategoryExpensePieChartCardState();
}

class _CategoryExpensePieChartCardState
    extends State<CategoryExpensePieChartCard> {
  int? _selectedIndex;

  static const List<Color> _palette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Rose
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF3B82F6), // Blue
    Color(0xFF84CC16), // Lime
    Color(0xFF64748B), // Slate
  ];

  List<CategorySpendData> _computeCategorySpends() {
    final expenseTransactions = widget.transactions
        .where((t) => t.isExpense && t.amount > 0)
        .toList();

    if (expenseTransactions.isEmpty) return [];

    final Map<String, double> categoryTotals = {};
    double totalExpense = 0.0;

    for (final t in expenseTransactions) {
      final name =
          (t.category?.name != null && t.category!.name.trim().isNotEmpty)
              ? t.category!.name.trim()
              : 'General';
      categoryTotals[name] = (categoryTotals[name] ?? 0.0) + t.amount;
      totalExpense += t.amount;
    }

    if (totalExpense <= 0) return [];

    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<CategorySpendData> list = [];
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final color = _palette[i % _palette.length];
      final pct = (entry.value / totalExpense) * 100.0;
      list.add(CategorySpendData(
        categoryName: entry.key,
        amount: entry.value,
        percentage: pct,
        color: color,
      ));
    }

    return list;
  }

  void _handleTap(
    Offset localPosition,
    Size size,
    List<CategorySpendData> items,
  ) {
    if (items.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final baseRadius = (min(size.width, size.height) / 2) - 8;

    if (distance < baseRadius - 28 || distance > baseRadius + 18) {
      setState(() => _selectedIndex = null);
      return;
    }

    var angle = atan2(dy, dx) + (pi / 2);
    if (angle < 0) {
      angle += 2 * pi;
    }

    double accumulated = 0.0;
    int? tappedIndex;
    for (int i = 0; i < items.length; i++) {
      final sweep = (items[i].percentage / 100.0) * 2 * pi;
      if (angle >= accumulated && angle < accumulated + sweep) {
        tappedIndex = i;
        break;
      }
      accumulated += sweep;
    }

    setState(() {
      if (_selectedIndex == tappedIndex) {
        _selectedIndex = null;
      } else {
        _selectedIndex = tappedIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final items = _computeCategorySpends();

    final totalExpense = items.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.pie_chart_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Spending',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          items.isNotEmpty
                              ? '${items.length} ${items.length == 1 ? 'category' : 'categories'} spent'
                              : 'No expenses recorded',
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (totalExpense > 0)
                  Text(
                    CurrencyFormatter.format(totalExpense),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            if (items.isEmpty) ...[
              // Empty State
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 36,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No category expense data',
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expense breakdown will appear as transactions are recorded.',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Donut Pie Chart Visual with Interactive Center
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) =>
                            _handleTap(details.localPosition, size, items),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: size,
                              painter: _DonutChartPainter(
                                categories: items,
                                selectedIndex: _selectedIndex,
                              ),
                            ),
                            // Center Interactive Label
                            Container(
                              width: 120,
                              height: 120,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.surface,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _selectedIndex != null &&
                                            _selectedIndex! < items.length
                                        ? items[_selectedIndex!].categoryName
                                        : 'Total Spent',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedIndex != null &&
                                              _selectedIndex! < items.length
                                          ? items[_selectedIndex!].color
                                          : colors.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    CurrencyFormatter.format(
                                      _selectedIndex != null &&
                                              _selectedIndex! < items.length
                                          ? items[_selectedIndex!].amount
                                          : totalExpense,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  if (_selectedIndex != null &&
                                      _selectedIndex! < items.length) ...[
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: items[_selectedIndex!]
                                            .color
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${items[_selectedIndex!].percentage.toStringAsFixed(1)}%',
                                        style: text.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: items[_selectedIndex!].color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Category Legend & Breakdown List
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 12,
                    color: colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedIndex == index;

                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          if (_selectedIndex == index) {
                            _selectedIndex = null;
                          } else {
                            _selectedIndex = index;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? item.color.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.categoryName,
                                style: text.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? item.color
                                      : colors.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.percentage.toStringAsFixed(1)}%',
                                style: text.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: item.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              CurrencyFormatter.format(item.amount),
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategorySpendData> categories;
  final int? selectedIndex;

  _DonutChartPainter({
    required this.categories,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (min(size.width, size.height) / 2) - 8;
    const strokeWidth = 24.0;
    const selectedStrokeWidth = 30.0;

    double startAngle = -pi / 2; // 12 o'clock start
    const gapAngle = 0.04;

    for (int i = 0; i < categories.length; i++) {
      final item = categories[i];
      final sweepAngle = (item.percentage / 100.0) * 2 * pi;
      final isSelected = selectedIndex == i;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? selectedStrokeWidth : strokeWidth
        ..strokeCap = StrokeCap.butt;

      final effectiveSweep = categories.length > 1
          ? max(0.01, sweepAngle - gapAngle)
          : sweepAngle;
      final effectiveStart = categories.length > 1
          ? startAngle + (gapAngle / 2)
          : startAngle;

      final radius = isSelected ? baseRadius + 3 : baseRadius;
      final rect = Rect.fromCircle(center: center, radius: radius);

      canvas.drawArc(rect, effectiveStart, effectiveSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.categories != categories ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
