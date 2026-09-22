import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/screens/start_delivery/start_delivery_screen.dart';

void main() {
  testWidgets('off-loading steps keep invoice, permit, and navigation actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StartDeliveryScreen(
          workflow: DeliveryWorkflow.arrival,
          delivery: DeliveryModel(
            id: 'lot-1',
            dateTime: DateTime(2026, 8, 15),
            clientName: 'Johan du Toit',
            clientAddress: 'Delivery address',
            invoicePath: 'uploads/invoices/invoice.pdf',
            permits: const ['uploads/permits/permit.pdf'],
          ),
        ),
      ),
    );

    expect(find.byTooltip('View invoice PDF'), findsOneWidget);
    expect(find.byTooltip('View permits'), findsOneWidget);
    expect(find.byTooltip('Open navigation'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pump();
    expect(
      find.text('Customer latitude and longitude are unavailable.'),
      findsOneWidget,
    );
  });
}
