import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/tracking_session_entity.dart';
import '../../domain/usecases/route/save_route_usecase.dart';
import '../cubit/location/location_cubit.dart';
import '../cubit/route_creation/route_creation_cubit.dart';
import '../pages/create_route/create_route_page.dart';
import '../pages/home/home_page.dart';
import '../pages/json_viewer/json_viewer_page.dart';
import '../pages/route_details/route_details_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/tracking/tracking_page.dart';
import '../pages/tracking_summary/tracking_summary_page.dart';

class AppRouter {
  final SaveRouteUseCase saveRouteUseCase;

  AppRouter({required this.saveRouteUseCase});

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );

      case '/create-route':
        return MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => RouteCreationCubit(
                  saveRouteUseCase: saveRouteUseCase,
                ),
              ),
              BlocProvider(create: (_) => LocationCubit()),
            ],
            child: const CreateRoutePage(),
          ),
        );

      case '/route-details':
        final routeId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => RouteDetailsPage(routeId: routeId),
        );

      case '/tracking':
        final args = settings.arguments as Map<String, dynamic>;
        final route = args['route'] as RouteEntity;
        final appSettings = args['settings'] as AppSettingsEntity;
        return MaterialPageRoute(
          builder: (_) => TrackingPage(route: route, settings: appSettings),
        );

      case '/tracking-summary':
        final args = settings.arguments as Map<String, dynamic>;
        final session = args['session'] as TrackingSessionEntity;
        final route = args['route'] as RouteEntity;
        return MaterialPageRoute(
          builder: (_) =>
              TrackingSummaryPage(session: session, route: route),
        );

      case '/json-viewer':
        final args = settings.arguments as Map<String, dynamic>;
        final json = args['json'] as String;
        final title = args['title'] as String;
        return MaterialPageRoute(
          builder: (_) => JsonViewerPage(json: json, title: title),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
