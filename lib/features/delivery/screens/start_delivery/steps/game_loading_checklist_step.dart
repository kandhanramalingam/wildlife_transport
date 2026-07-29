import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class GameLoadingChecklistStep extends StatefulWidget {
  final VoidCallback onNext;
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

class _GameLoadingChecklistStepState extends State<GameLoadingChecklistStep> {
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

  @override
  Widget build(BuildContext context) {
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
                '${_items.where((item) => item.checked).length}/${_items.length} completed',
                style: TextStyle(
                  fontSize: 13,
                  color: _allChecked
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
                const Divider(height: 1, indent: 56, endIndent: 16),
            itemBuilder: (_, index) {
              final item = _items[index];
              return CheckboxListTile(
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
                  horizontal: 16,
                  vertical: 2,
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

class _GameLoadingCheckItem {
  final String title;
  bool checked;

  _GameLoadingCheckItem(this.title) : checked = false;
}
