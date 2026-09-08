import 'package:flutter/material.dart';

const ratingLabels = {
  1: 'Very Poor',
  2: 'Poor',
  3: 'Average',
  4: 'Good',
  5: 'Excellent',
};

/// A 1-5 rating control. Deliberately not star icons — a labelled scale
/// reads clearer for a formal evaluation than a star rating does.
class RatingSelector extends StatelessWidget {
  const RatingSelector({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(5, (i) {
        final rating = i + 1;
        final selected = value == rating;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: rating == 5 ? 0 : 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged(rating),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Text(
                      '$rating',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
