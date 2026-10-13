import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/screens/trip_customers_screen.dart';

void main() {
  test('resolves a relative invoice path against the API host', () {
    expect(
      resolveInvoiceUri(
        'http://transport.wildlifeauctions.co.za:8081/',
        'uploads/invoices/invoice.pdf',
      ).toString(),
      'http://transport.wildlifeauctions.co.za:8081/uploads/invoices/invoice.pdf',
    );
  });

  test('keeps an absolute invoice URL unchanged', () {
    expect(
      resolveInvoiceUri(
        'http://transport.wildlifeauctions.co.za:8081/',
        'https://cdn.example.com/invoice.pdf',
      ).toString(),
      'https://cdn.example.com/invoice.pdf',
    );
  });

  testWidgets('shows the invoice icon even when the path is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TripCustomersScreen(
          delivery: DeliveryModel(
            id: 'delivery-1',
            buyerId: '3068',
            dateTime: DateTime(2026, 8, 15),
            clientName: 'User #3068',
            clientAddress: 'Delivery address',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
    await tester.pump();
    expect(
      find.text('Invoice PDF is not available for this customer.'),
      findsOneWidget,
    );
  });

  testWidgets('shows Invoice as the preview title instead of the file name', (
    tester,
  ) async {
    const fileName = '6bc974f6-9de0-40de-83da-519a4a.pdf';
    await tester.pumpWidget(
      MaterialApp(
        home: TripCustomersScreen(
          delivery: DeliveryModel(
            id: 'delivery-1',
            buyerId: '3068',
            dateTime: DateTime(2026, 8, 15),
            clientName: 'User #3068',
            clientAddress: 'Delivery address',
            invoicePath: 'uploads/invoices/$fileName',
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
    await tester.pump();

    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text(fileName), findsNothing);
  });

  testWidgets('hides trip partial progress but keeps permits visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TripCustomersScreen(
          delivery: DeliveryModel(
            id: 'delivery-1',
            dateTime: DateTime(2026, 8, 15),
            clientName: 'Johan du Toit',
            clientAddress: 'Delivery address',
            partialDelivery: true,
            totalLots: 2,
            balanceLots: 2,
            permits: const ['uploads/permits/permit-1.pdf'],
          ),
        ),
      ),
    );

    expect(find.text('Permits (1)'), findsOneWidget);
    expect(find.text('Partial • 0/2 Lots Delivered'), findsNothing);
    expect(find.text('Remaining Lots: 2'), findsNothing);
  });
}
