import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'data/datasources/local/route_local_datasource.dart';
import 'data/datasources/local/settings_local_datasource.dart';
import 'data/datasources/local/tracking_local_datasource.dart';
import 'data/repositories/route_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/repositories/tracking_repository_impl.dart';
import 'domain/usecases/route/delete_route_usecase.dart';
import 'domain/usecases/route/get_all_routes_usecase.dart';
import 'domain/usecases/route/get_route_usecase.dart';
import 'domain/usecases/route/save_route_usecase.dart';
import 'domain/usecases/settings/get_settings_usecase.dart';
import 'domain/usecases/settings/save_settings_usecase.dart';
import 'domain/usecases/tracking/add_gps_point_usecase.dart';
import 'domain/usecases/tracking/add_stop_usecase.dart';
import 'domain/usecases/tracking/pause_tracking_usecase.dart';
import 'domain/usecases/tracking/resume_tracking_usecase.dart';
import 'domain/usecases/tracking/start_tracking_usecase.dart';
import 'domain/usecases/tracking/stop_tracking_usecase.dart';
import 'domain/usecases/tracking/get_sessions_for_route_usecase.dart';
import 'domain/usecases/tracking/validate_gps_point_usecase.dart';
import 'presentation/bloc/route/route_bloc.dart';
import 'presentation/bloc/tracking/tracking_bloc.dart';
import 'presentation/cubit/location/location_cubit.dart';
import 'presentation/cubit/settings/settings_cubit.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open Hive boxes (Box<String> - no code generation needed)
  final routesBox = await Hive.openBox<String>(AppConstants.routesBox);
  final trackingBox = await Hive.openBox<String>(AppConstants.trackingBox);

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Create datasources
  final routeLocalDatasource = RouteLocalDatasource(routesBox);
  final trackingLocalDatasource = TrackingLocalDatasource(trackingBox);
  final settingsLocalDatasource = SettingsLocalDatasource(sharedPreferences);

  // Create repositories
  final routeRepository = RouteRepositoryImpl(routeLocalDatasource);
  final trackingRepository = TrackingRepositoryImpl(trackingLocalDatasource);
  final settingsRepository = SettingsRepositoryImpl(settingsLocalDatasource);

  // Create use cases
  final getAllRoutesUseCase = GetAllRoutesUseCase(routeRepository);
  final getRouteUseCase = GetRouteUseCase(routeRepository);
  final saveRouteUseCase = SaveRouteUseCase(routeRepository);
  final deleteRouteUseCase =
      DeleteRouteUseCase(routeRepository, trackingRepository);
  final getSettingsUseCase = GetSettingsUseCase(settingsRepository);
  final saveSettingsUseCase = SaveSettingsUseCase(settingsRepository);
  final startTrackingUseCase = StartTrackingUseCase(trackingRepository);
  final stopTrackingUseCase = StopTrackingUseCase(trackingRepository);
  final pauseTrackingUseCase = PauseTrackingUseCase(trackingRepository);
  final resumeTrackingUseCase = ResumeTrackingUseCase(trackingRepository);
  final addGpsPointUseCase = AddGpsPointUseCase(trackingRepository);
  final addStopUseCase = AddStopUseCase(trackingRepository);
  final validateGpsPointUseCase = ValidateGpsPointUseCase();
  final getSessionsForRouteUseCase =
      GetSessionsForRouteUseCase(trackingRepository);

  // Restore any unfinished tracking session from previous app run
  final unfinishedSession = await trackingRepository.getUnfinishedSession();

  // Create router
  final appRouter = AppRouter(saveRouteUseCase: saveRouteUseCase);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: routeRepository),
        RepositoryProvider.value(value: trackingRepository),
        RepositoryProvider.value(value: settingsRepository),
        RepositoryProvider.value(value: saveRouteUseCase),
        RepositoryProvider.value(value: getSessionsForRouteUseCase),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RouteBloc>(
            create: (_) => RouteBloc(
              getAllRoutes: getAllRoutesUseCase,
              getRoute: getRouteUseCase,
              saveRoute: saveRouteUseCase,
              deleteRoute: deleteRouteUseCase,
            ),
          ),
          BlocProvider<TrackingBloc>(
            create: (_) {
              final bloc = TrackingBloc(
                startTracking: startTrackingUseCase,
                stopTracking: stopTrackingUseCase,
                pauseTracking: pauseTrackingUseCase,
                resumeTracking: resumeTrackingUseCase,
                addGpsPoint: addGpsPointUseCase,
                validateGpsPoint: validateGpsPointUseCase,
                addStop: addStopUseCase,
              );
              if (unfinishedSession != null) {
                bloc.add(RestoreSession(unfinishedSession));
              }
              return bloc;
            },
          ),
          BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(
              getSettings: getSettingsUseCase,
              saveSettings: saveSettingsUseCase,
            ),
          ),
          BlocProvider<LocationCubit>(
            create: (_) => LocationCubit(),
          ),
        ],
        child: RouteBuilderApp(
          appRouter: appRouter,
          saveRouteUseCase: saveRouteUseCase,
        ),
      ),
    ),
  );
}

class RouteBuilderApp extends StatelessWidget {
  final AppRouter appRouter;
  final SaveRouteUseCase saveRouteUseCase;

  const RouteBuilderApp({
    super.key,
    required this.appRouter,
    required this.saveRouteUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Builder',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: appRouter.onGenerateRoute,
      initialRoute: '/splash',
    );
  }
}
