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
}
