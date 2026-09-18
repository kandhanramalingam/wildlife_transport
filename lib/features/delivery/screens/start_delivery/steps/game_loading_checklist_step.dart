import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../models/start_delivery_submission.dart';

class GameLoadingChecklistStep extends StatefulWidget {
  final ValueChanged<List<DeliveryChecklistItem>> onNext;
  final bool isOffLoading;

  const GameLoadingChecklistStep({
    super.key,
    required this.onNext,
    this.isOffLoading = false,
  });

  @override
  State<GameLoadingChecklistStep> createState() =>
      _GameLoadingChecklistStepState();
}

class _GameLoadingChecklistStepState extends State<GameLoadingChecklistStep>
    with AutomaticKeepAliveClientMixin<GameLoadingChecklistStep> {
  bool _showMissingReasons = false;
  late final List<_GameLoadingCheckItem> _items = widget.isOffLoading
      ? [
          _GameLoadingCheckItem(
            'Check the person’s identity and confirm the correct person is accepting the game. If it is not the same person, contact the office first.',
          ),
          _GameLoadingCheckItem(
            'Check the quantities of animals on the vehicle with the client.',
          ),
          _GameLoadingCheckItem(
            'Client must sign on screen accepting the animals’ health and quantities.',
          ),
          _GameLoadingCheckItem('Check the health of all animals.'),
          _GameLoadingCheckItem('Take photos of all animals on the truck.'),
          _GameLoadingCheckItem(
            'Take a video clip while the animals are being off-loaded.',
          ),
          _GameLoadingCheckItem(
            'Save the pinpoint location of the off-loading point for future reference.',
          ),
        ]
      : [
          _GameLoadingCheckItem('Confirm client contact details'),
          _GameLoadingCheckItem(
            'Confirm correct person delivering to either by cell phone number or contact details',
          ),
          _GameLoadingCheckItem(
            'Client must be able to make notes during delivery on the device',
          ),
          _GameLoadingCheckItem(
            'Driver must take video clip of animals being off loaded',
          ),
          _GameLoadingCheckItem(
            'Driver must take photo of person accepting delivery',
          ),
          _GameLoadingCheckItem(
            'Manage all paperwork electronically (see truck routing schedule)',
          ),
          _GameLoadingCheckItem('Confirm customer has paid'),
          _GameLoadingCheckItem('Confirm quantity of lots'),
          _GameLoadingCheckItem('Confirm lots of customer have been checked'),
          _GameLoadingCheckItem('How many animals have been confirmed to load'),
          _GameLoadingCheckItem('Any differences in quantities'),
          _GameLoadingCheckItem('State differences and reason'),
          _GameLoadingCheckItem('Confirm health of animals'),
          _GameLoadingCheckItem('Confirm all health of animals'),
          _GameLoadingCheckItem('If any animal is suspect, reason for health'),
          _GameLoadingCheckItem('Action taken for animal'),
          _GameLoadingCheckItem(
            'Confirm all animals have been loaded for customer',
          ),
          _GameLoadingCheckItem(
            'Confirm customer has been informed of any mortalities',
          ),
          _GameLoadingCheckItem('Confirm customer has loading ramp or not'),
          _GameLoadingCheckItem('If not, what must be done off loading'),
          _GameLoadingCheckItem(
            'Confirm delivery has been confirmed with customer',
          ),
          _GameLoadingCheckItem(
            'Confirm name and cellphone number for delivery has been confirmed',
          ),
          _GameLoadingCheckItem(
            'Confirmed special delivery instructions have been reviewed',
          ),
          _GameLoadingCheckItem('View any special delivery instructions'),
          _GameLoadingCheckItem('Any special notes to be noted for delivery'),
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
    final completedCount = _items.where((item) => item.checked).length;
    final reasonedCount = _items
        .where((i) => !i.checked && i.reason.trim().isNotEmpty)
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.isOffLoading
                  ? 'Off Loading Checking'
                  : 'Game Loading Check List',
              style: const TextStyle(
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
            itemBuilder: (_, index) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: item.checked,
                      onChanged: (value) =>
                          setState(() => item.checked = value ?? false),
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

class _GameLoadingCheckItem {
  final String title;
  bool checked;
  String reason;

  _GameLoadingCheckItem(this.title) : checked = false, reason = '';

  bool get isValid => checked || reason.trim().isNotEmpty;
}
