import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/features/delivery/domain/delivery_repository.dart';
import 'package:wildlife_transport/features/delivery/models/delivery_model.dart';
import 'package:wildlife_transport/features/delivery/presentation/today_deliveries_controller.dart';
import 'package:wildlife_transport/features/delivery/tabs/completed_tab.dart';

void main() {
  testWidgets(
    'Completed excludes queued offloading and shows it only after server confirmation',
    (tester) async {
      final pendingIds = {'pending-delivery'};
      final repository = _ScheduleRepository([
        _delivery(
          'confirmed-delivery',
          'Confirmed customer',
          DeliveryStatus.completed,
        ),
        _delivery(
          'pending-delivery',
          'Pending customer',
          DeliveryStatus.offloading,
        ),
      ]);
      final controller = TodayDeliveriesController(
        repository,
        pendingOffloadingIds: () => pendingIds,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompletedTab(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Confirmed customer'), findsOneWidget);
      expect(find.text('Pending customer'), findsNothing);
      expect(controller.deliveries.last.deliveryCompleted, isTrue);
      expect(controller.deliveries.last.completionSynced, isFalse);

      // Removing a local flag alone cannot make an Offloading record completed.
      pendingIds.clear();
      await controller.load();
      await tester.pumpAndSettle();
      expect(find.text('Pending customer'), findsNothing);

      repository.deliveries = [
        repository.deliveries.first,
        _delivery(
          'pending-delivery',
          'Pending customer',
          DeliveryStatus.completed,
        ),
      ];
      await controller.load();
      await tester.pumpAndSettle();
      expect(find.text('Pending customer'), findsOneWidget);
      expect(controller.deliveries.last.completionSynced, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

DeliveryModel _delivery(String id, String customer, DeliveryStatus status) =>
    DeliveryModel(
      id: id,
      dateTime: DateTime(2026, 10, 11, 7, 58),
      clientName: customer,
      clientAddress: 'Farm',
      status: status,
      lots: [
        DeliveryLot(
          clientName: customer,
          buyerId: 'buyer-$id',
          mainBuyer: true,
          deliveryId: id,
          address: 'Farm',
          status: status,
        ),
      ],
    );

class _ScheduleRepository implements DeliveryRepository {
  List<DeliveryModel> deliveries;
  _ScheduleRepository(this.deliveries);

  @override
  Future<List<DeliveryModel>> getTodaySchedule({
    CancelToken? cancelToken,
  }) async => deliveries;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
