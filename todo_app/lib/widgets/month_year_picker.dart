import 'package:flutter/material.dart';

/// A dialog that lets the user jump straight to any month/year, instead of
/// stepping one month at a time. Returns the 1st of the chosen month, or
/// null if cancelled.
Future<DateTime?> showMonthYearPicker(BuildContext context, {required DateTime initial}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _MonthYearPickerDialog(initial: initial),
  );
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initial;
  const _MonthYearPickerDialog({required this.initial});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _year = widget.initial.year;

  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _year--)),
          Text('$_year', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _year++)),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.6,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final isFuture = _year > now.year || (_year == now.year && month > now.month);
            final isSelected = _year == widget.initial.year && month == widget.initial.month;
            return OutlinedButton(
              onPressed: isFuture ? null : () => Navigator.pop(context, DateTime(_year, month, 1)),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_monthLabels[index]),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}
