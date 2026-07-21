import '../../features/auth/data/auth_remote_data_source.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/presentation/login_controller.dart';
import '../../features/auth/presentation/session_controller.dart';
import '../../features/delivery/data/delivery_remote_data_source.dart';
import '../../features/delivery/data/delivery_repository_impl.dart';
import '../../features/delivery/presentation/today_deliveries_controller.dart';
import '../../features/delivery/presentation/upcoming_deliveries_controller.dart';
import '../../features/profile/data/profile_remote_data_source.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';

class AppDependencies {
  AppDependencies._();

  static final TokenStorage tokenStorage = SecureTokenStorage();
  static final SessionController sessionController = SessionController(
    tokenStorage,
  );
  static final ApiClient apiClient = ApiClient(tokenStorage);

  static LoginController createLoginController() {
    final dataSource = DioAuthRemoteDataSource(apiClient.dio);
    final repository = AuthRepositoryImpl(dataSource, tokenStorage);
    return LoginController(repository);
  }

  static TodayDeliveriesController createTodayDeliveriesController() {
    final dataSource = DioDeliveryRemoteDataSource(apiClient.dio);
    final repository = DeliveryRepositoryImpl(dataSource);
    return TodayDeliveriesController(repository);
  }

  static UpcomingDeliveriesController createUpcomingDeliveriesController() {
    final dataSource = DioDeliveryRemoteDataSource(apiClient.dio);
    final repository = DeliveryRepositoryImpl(dataSource);
    return UpcomingDeliveriesController(repository);
  }

  static ProfileController createProfileController() {
    final dataSource = DioProfileRemoteDataSource(apiClient.dio);
    final repository = ProfileRepositoryImpl(dataSource);
    return ProfileController(repository);
  }
}
