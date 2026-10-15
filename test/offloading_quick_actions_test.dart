import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/screens/start_delivery/start_delivery_screen.dart';
import 'package:wildlife_transport/features/delivery/screens/start_delivery/steps/photos_step.dart';
import 'package:wildlife_transport/features/delivery/widgets/trip_document_actions.dart';

void main() {
  testWidgets(
    'off-loading steps keep invoice, permit, and navigation actions',
    (tester) async {
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
              maps: const ['uploads/maps/map.png'],
              assignment: const DeliveryAssignment(
                driverId: 'driver-1',
                vehicleId: 'vehicle-1',
                lotNumbers: ['1', '2', '3', '4', '5'],
              ),
            ),
          ),
        ),
      );

      expect(find.byTooltip('View invoice PDF'), findsOneWidget);
      expect(find.byTooltip('View permits'), findsOneWidget);
      expect(find.byTooltip('View map'), findsOneWidget);
      expect(find.byTooltip('Open navigation'), findsOneWidget);
      expect(find.text('Off Loading Checking').hitTestable(), findsOneWidget);
      expect(
        tester.getSize(find.byType(TripDocumentActions)).height,
        lessThan(100),
      );
      final pageView = tester.widget<PageView>(find.byType(PageView));
      final pages =
          (pageView.childrenDelegate as SliverChildListDelegate).children;
      final photosStep = pages.whereType<PhotosStep>().single;
      expect(photosStep.isOffLoading, isTrue);

      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pump();
      expect(
        find.text('Customer latitude and longitude are unavailable.'),
        findsOneWidget,
      );
    },
  );
}
