import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';
import 'core/network/response_cache_manager.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/documents/data/datasources/document_local_data_source.dart';
import 'features/documents/data/datasources/document_remote_data_source.dart';
import 'features/documents/data/repositories/document_repository_impl.dart';
import 'features/documents/data/services/document_file_service.dart';
import 'features/documents/domain/repositories/document_repository.dart';
import 'features/documents/presentation/bloc/document_bloc.dart';
import 'features/wallet_details/data/datasources/wallet_details_remote_data_source.dart';
import 'features/wallet_details/data/repositories/wallet_details_repository_impl.dart';
import 'features/wallet_details/domain/repositories/wallet_details_repository.dart';
import 'features/wallet_details/presentation/bloc/wallet_details_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final cacheManager = ResponseCacheManager(prefs: prefs);
  final storageService = SecureStorageService();
  late final AuthBloc authBloc;

  final apiClient = ApiClient(
    storageService: storageService,
    cacheManager: cacheManager,
    onUnauthorized: () {
      authBloc.add(const AuthSessionExpired());
    },
  );

  final authRemoteDataSource = AuthRemoteDataSourceImpl(apiClient);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    storageService: storageService,
    cacheManager: cacheManager,
  );

  authBloc = AuthBloc(authRepository: authRepository);

  final dashboardRemoteDataSource = DashboardRemoteDataSourceImpl(apiClient);
  final dashboardRepository = DashboardRepositoryImpl(
    remoteDataSource: dashboardRemoteDataSource,
  );
  final dashboardBloc = DashboardBloc(dashboardRepository: dashboardRepository);

  final walletDetailsRemoteDataSource =
      WalletDetailsRemoteDataSourceImpl(apiClient);
  final walletDetailsRepository = WalletDetailsRepositoryImpl(
    remoteDataSource: walletDetailsRemoteDataSource,
  );
  final walletDetailsBloc =
      WalletDetailsBloc(walletDetailsRepository: walletDetailsRepository);

  final documentFileService = DocumentFileService();
  final documentRemoteDataSource = DocumentRemoteDataSourceImpl(apiClient);
  final documentLocalDataSource = DocumentLocalDataSourceImpl(
    prefs: prefs,
    fileService: documentFileService,
  );
  final documentRepository = DocumentRepositoryImpl(
    remoteDataSource: documentRemoteDataSource,
    localDataSource: documentLocalDataSource,
  );
  final documentBloc = DocumentBloc(documentRepository: documentRepository);

  runApp(
    ExpensesApp(
      authRepository: authRepository,
      authBloc: authBloc,
      dashboardRepository: dashboardRepository,
      dashboardBloc: dashboardBloc,
      walletDetailsRepository: walletDetailsRepository,
      walletDetailsBloc: walletDetailsBloc,
      documentRepository: documentRepository,
      documentBloc: documentBloc,
      documentFileService: documentFileService,
    ),
  );
}

class ExpensesApp extends StatelessWidget {
  final AuthRepository authRepository;
  final AuthBloc authBloc;
  final DashboardRepository dashboardRepository;
  final DashboardBloc dashboardBloc;
  final WalletDetailsRepository walletDetailsRepository;
  final WalletDetailsBloc walletDetailsBloc;
  final DocumentRepository documentRepository;
  final DocumentBloc documentBloc;
  final DocumentFileService documentFileService;

  const ExpensesApp({
    super.key,
    required this.authRepository,
    required this.authBloc,
    required this.dashboardRepository,
    required this.dashboardBloc,
    required this.walletDetailsRepository,
    required this.walletDetailsBloc,
    required this.documentRepository,
    required this.documentBloc,
    required this.documentFileService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<DashboardRepository>.value(
            value: dashboardRepository),
        RepositoryProvider<WalletDetailsRepository>.value(
            value: walletDetailsRepository),
        RepositoryProvider<DocumentRepository>.value(
            value: documentRepository),
        RepositoryProvider<DocumentFileService>.value(
            value: documentFileService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<DashboardBloc>.value(value: dashboardBloc),
          BlocProvider<WalletDetailsBloc>.value(value: walletDetailsBloc),
          BlocProvider<DocumentBloc>.value(value: documentBloc),
        ],
        child: MaterialApp(
          title: 'Sangam Home',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
