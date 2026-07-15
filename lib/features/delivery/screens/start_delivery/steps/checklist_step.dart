import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class ChecklistStep extends StatefulWidget {
  final VoidCallback onNext;
  const ChecklistStep({super.key, required this.onNext});

  @override
  State<ChecklistStep> createState() => _ChecklistStepState();
}

class _ChecklistStepState extends State<ChecklistStep> {
  final List<_CheckItem> _items = [
    _CheckItem('Animal properly secured in transport crate'),
    _CheckItem('First aid kit available and stocked'),
    _CheckItem('Sufficient water supply for animals'),
    _CheckItem('Required documents ready (permits, health certificates)'),
    _CheckItem('Vehicle condition checked and OK'),
    _CheckItem('Emergency contacts noted'),
    _CheckItem('Route planned and confirmed'),
    _CheckItem('Temperature control checked'),
  ];

  bool get _allChecked => _items.every((item) => item.checked);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                '${_items.where((i) => i.checked).length}/${_items.length} completed',
                style: TextStyle(
                  fontSize: 13,
                  color: _allChecked ? Colors.green.shade700 : AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (!_allChecked)
                TextButton(
                  onPressed: () => setState(() {
                    for (final item in _items) {
                      item.checked = true;
                    }
                  }),
                  child: const Text('Check All'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 56, endIndent: 16),
            itemBuilder: (_, i) {
              final item = _items[i];
              return CheckboxListTile(
                value: item.checked,
                onChanged: (v) => setState(() => item.checked = v ?? false),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.checked
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    decoration: item.checked ? TextDecoration.lineThrough : null,
                  ),
                ),
                activeColor: AppTheme.primary,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _allChecked ? widget.onNext : null,
              child: const Text('Next'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckItem {
  final String title;
  bool checked;
  _CheckItem(this.title, {this.checked = false});
}
