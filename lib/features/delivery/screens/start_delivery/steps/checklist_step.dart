import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../models/start_delivery_submission.dart';

class ChecklistStep extends StatefulWidget {
  final ValueChanged<List<DeliveryChecklistItem>> onNext;
  const ChecklistStep({super.key, required this.onNext});

  @override
  State<ChecklistStep> createState() => _ChecklistStepState();
}

class _ChecklistStepState extends State<ChecklistStep>
    with AutomaticKeepAliveClientMixin<ChecklistStep> {
  bool _showMissingReasons = false;
  final List<_CheckItem> _items = [
    _CheckItem('Check plotter in vehicle'),
    _CheckItem('Check odometer reading'),
    _CheckItem('Petrol Card in Vehicle'),
    _CheckItem('Spare wheels for vehicle'),
    _CheckItem('Toolbox for Game Handling'),
    _CheckItem('Windscreen Cracks'),
    _CheckItem('Speedometer working'),
    _CheckItem('Wipers Working'),
    _CheckItem('Seats clean and working condition'),
    _CheckItem('Front Indicators'),
    _CheckItem('Cab clean inside'),
    _CheckItem('Front Headlights'),
    _CheckItem('Gauges Working'),
    _CheckItem('Taillights'),
    _CheckItem('Brakes working'),
    _CheckItem('Spotlights'),
    _CheckItem('Dash neat and clean'),
    _CheckItem('Rear Indicators'),
    _CheckItem('Steering OK'),
    _CheckItem('Front Tyres'),
    _CheckItem('Wheel Spanner'),
    _CheckItem('1st set rear tyres'),
    _CheckItem('Jack'),
    _CheckItem('2nd set rear tyres'),
    _CheckItem('Triangles'),
    _CheckItem('Wheelnuts'),
    _CheckItem('Mirrors'),
    _CheckItem('Batteries'),
    _CheckItem('Door Handles'),
    _CheckItem('Engine Check Sheet Before Start'),
    _CheckItem('Engine Check Sheet After Start'),
    _CheckItem('Engine Oil Level'),
    _CheckItem('Air Gauge Working'),
    _CheckItem('Water Level'),
    _CheckItem('All Instruments Functional'),
  ];

  bool get _allChecked => _items.every((item) => item.checked);
  bool get _canProceed => _items.every((item) => item.isValid);

  void _handleNext() {
    if (!_canProceed) {
      setState(() => _showMissingReasons = true);
      return;
    }

    widget.onNext(
      _items
          .map(
            (item) => DeliveryChecklistItem(
              item: item.title,
              checked: item.checked,
              reason: item.checked ? null : item.reason.trim(),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final completedCount = _items.where((i) => i.checked).length;
    final reasonedCount = _items
        .where((i) => !i.checked && i.reason.trim().isNotEmpty)
        .length;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Vehicle Check List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Text(
                '$completedCount/${_items.length} checked'
                '${reasonedCount > 0 ? ' ($reasonedCount skipped with reason)' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  color: _canProceed
                      ? Colors.green.shade700
                      : AppTheme.textSecondary,
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
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (_, i) {
              final item = _items[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: item.checked,
                      onChanged: (v) =>
                          setState(() => item.checked = v ?? false),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: item.checked
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration: item.checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      activeColor: AppTheme.primary,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    ),
                    if (_showMissingReasons && !item.checked)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(48, 0, 16, 8),
                        child: TextFormField(
                          initialValue: item.reason,
                          onChanged: (val) => setState(() => item.reason = val),
                          decoration: InputDecoration(
                            hintText: 'Reason for skipping this item *',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            filled: true,
                            fillColor: item.reason.trim().isEmpty
                                ? Colors.amber.shade50.withValues(alpha: 0.5)
                                : Colors.grey.shade50,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: item.reason.trim().isEmpty
                                    ? Colors.amber.shade600
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showMissingReasons && !_canProceed)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Please check all items or provide reasons for unchecked items',
                    style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckItem {
  final String title;
  bool checked;
  String reason;
  _CheckItem(this.title) : checked = false, reason = '';

  bool get isValid => checked || reason.trim().isNotEmpty;
}
