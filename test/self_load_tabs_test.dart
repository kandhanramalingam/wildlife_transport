import 'package:dio/dio.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildlife_transport/core/di/app_dependencies.dart';
import 'package:wildlife_transport/core/storage/token_storage.dart';
import 'package:wildlife_transport/features/auth/data/auth_remote_data_source.dart';
import 'package:wildlife_transport/features/auth/data/auth_repository_impl.dart';
import 'package:wildlife_transport/features/auth/data/login_response_dto.dart';
import 'package:wildlife_transport/features/delivery/screens/delivery_screen.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  for (final role in [true, false, null]) {
    test(
      'login retains isSelfLoad=$role and defaults missing values to false',
      () async {
        final dto = LoginResponseDto.fromJson({
          'access_token': 'test-token',
          'driver': {
            'id': 'driver-1',
            'name': 'Driver',
            'phone': '123456789',
            'isSelfLoad': ?role,
          },
        });
        final storage = _Storage()..isSelfLoad = true;
        final result = await AuthRepositoryImpl(
          _LoginSource(dto),
          storage,
        ).login(phone: '123456789', password: 'password');
        expect(result.driver.isSelfLoad, role == true);
        expect(storage.isSelfLoad, role == true);
      },
    );
  }

  for (final selfLoad in [true, false]) {
    testWidgets('delivery tabs for isSelfLoad=$selfLoad', (tester) async {
      final dio = AppDependencies.apiClient.dio;
      final original = dio.interceptors.toList();
      dio.interceptors.clear();
      final requests = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options.path);
            handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: []),
            );
          },
        ),
      );
      addTearDown(() {
        dio.interceptors.clear();
        dio.interceptors.addAll(original);
      });
      await tester.pumpWidget(
        MaterialApp(home: DeliveryScreen(isSelfLoad: selfLoad)),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Tab, 'Today'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Completed'), findsOneWidget);
      expect(
        find.widgetWithText(Tab, 'Upcoming'),
        selfLoad ? findsNothing : findsOneWidget,
      );
      final bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.controller!.length, selfLoad ? 2 : 3);
      expect(
        tester.widget<TabBarView>(find.byType(TabBarView)).children.length,
        bar.controller!.length,
      );
      await tester.tap(find.widgetWithText(Tab, 'Completed'));
      await tester.pumpAndSettle();
      expect(bar.controller!.index, selfLoad ? 1 : 2);
      final before = requests.length;
      await tester.tap(find.widgetWithText(Tab, 'Today'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Tab, 'Completed'));
      await tester.pumpAndSettle();
      expect(requests.length, greaterThan(before));
      if (selfLoad) {
        expect(requests.where((path) => path.contains('upcoming')), isEmpty);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _LoginSource implements AuthRemoteDataSource {
  final LoginResponseDto response;
  _LoginSource(this.response);
  @override
  Future<LoginResponseDto> login({
    required String phone,
    required String password,
    CancelToken? cancelToken,
  }) async => response;
}

class _Storage implements TokenStorage {
  bool isSelfLoad = false;
  @override
  Future<bool> readIsSelfLoad() async => isSelfLoad;
  @override
  Future<void> saveIsSelfLoad(bool value) async {
    isSelfLoad = value;
  }

  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readDriverId() async => null;
  @override
  Future<void> saveAccessToken(String token) async {}
  @override
  Future<void> saveDriverId(String driverId) async {}
  @override
  Future<void> clear() async {
    isSelfLoad = false;
  }
}
