import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../../core/theme/text_styles.dart';

class FilterSortSheet extends StatefulWidget {
  const FilterSortSheet({super.key});

  @override
  State<FilterSortSheet> createState() => _FilterSortSheetState();
}

class _FilterSortSheetState extends State<FilterSortSheet> {
  String? _sortBy;
  String? _sortOrder;

  @override
  void initState() {
    super.initState();
    final provider = context.read<HistoryProvider>();
    _sortBy = provider.sortBy;
    _sortOrder = provider.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Urutkan & Filter',
              style: textTheme.titleLarge ?? TextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Urutkan Berdasarkan',
              style: (textTheme.titleMedium ?? TextStyles.titleMedium).copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildSortChip('Tanggal', 'createdAt'),
                _buildSortChip('Confidence', 'confidenceScore'),
                _buildSortChip('Hasil', 'result'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Urutan',
              style: (textTheme.titleMedium ?? TextStyles.titleMedium).copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildOrderChip('Terbaru', 'desc'),
                _buildOrderChip('Terlama', 'asc'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _sortBy = null;
                          _sortOrder = null;
                        });
                      },
                      child: const Text('Atur Ulang'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context
                            .read<HistoryProvider>()
                            .setSort(_sortBy, _sortOrder);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return Semantics(
      label: 'Urutkan: $label',
      selected: isSelected,
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _sortBy = selected ? value : null);
        },
      ),
    );
  }

  Widget _buildOrderChip(String label, String value) {
    final isSelected = _sortOrder == value;
    return Semantics(
      label: 'Urutan: $label',
      selected: isSelected,
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _sortOrder = selected ? value : null);
        },
      ),
    );
  }
}
