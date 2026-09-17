import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../bloc/route/route_bloc.dart';
import '../../bloc/tracking/tracking_bloc.dart';
import '../../cubit/location/location_cubit.dart';
import '../../cubit/location/location_state.dart';
import '../../cubit/settings/settings_cubit.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../domain/entities/route_entity.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_display.dart';
import '../../widgets/app_loading.dart';
import '../route_details/route_details_page.dart';
import '../settings/settings_page.dart';
import '../tracking/tracking_page.dart';
import 'widgets/route_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<RouteBloc>().add(const LoadRoutes());
    context.read<SettingsCubit>().loadSettings();
    context.read<LocationCubit>().checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check permission when app comes back to foreground (user may have
  // just granted it in the system Settings app).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<LocationCubit>().checkPermission();
    }
  }

  void _navigateToRouteDetails(String routeId) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => RouteDetailsPage(routeId: routeId)))
        .then((_) {
      if (mounted) {
        context.read<RouteBloc>().add(const LoadRoutes());
      }
    });
  }

  void _openActiveTracking(BuildContext context, String routeId) {
    final routeState = context.read<RouteBloc>().state;
    final settings = context.read<SettingsCubit>().state.settings;
    RouteEntity? route;
    if (routeState is RoutesLoaded) {
      try {
        route = routeState.routes.firstWhere((r) => r.id == routeId);
      } catch (_) {}
    }
    if (route != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackingPage(route: route!, settings: settings),
        ),
      );
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (_) => RouteDetailsPage(routeId: routeId)))
          .then((_) {
        if (context.mounted) {
          context.read<RouteBloc>().add(const LoadRoutes());
        }
      });
    }
  }

  void _onDeleteRoute(BuildContext context, String routeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text(
            'Are you sure you want to delete this route? All associated tracking sessions will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<RouteBloc>().add(DeleteRoute(routeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Permission banner ──────────────────────────────────────────
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, locationState) {
              if (locationState is LocationServicesDisabled) {
                return _PermissionBanner(
                  icon: Icons.location_off_outlined,
                  color: Colors.red,
                  message: 'Location services are disabled.',
                  actionLabel: 'Enable Location',
                  onAction: () async {
                    await Geolocator.openLocationSettings();
                  },
                );
              }
              if (locationState is LocationPermissionPermanentlyDenied) {
                return _PermissionBanner(
                  icon: Icons.location_disabled_outlined,
                  color: Colors.red,
                  message: 'Location permission is permanently denied.',
                  actionLabel: 'Open Settings',
                  onAction: () async {
                    await Geolocator.openAppSettings();
                  },
                );
              }
              if (locationState is LocationPermissionDenied) {
                return _PermissionBanner(
                  icon: Icons.location_searching_outlined,
                  color: Colors.orange,
                  message: 'Location permission is needed for tracking.',
                  actionLabel: 'Grant Permission',
                  onAction: () {
                    context.read<LocationCubit>().requestPermission();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ── Active tracking banner ─────────────────────────────────────
          BlocBuilder<TrackingBloc, TrackingState>(
            builder: (context, trackingState) {
              if (trackingState is! TrackingActive &&
                  trackingState is! TrackingPaused) {
                return const SizedBox.shrink();
              }
              final session = trackingState is TrackingActive
                  ? trackingState.session
                  : (trackingState as TrackingPaused).session;
              final isActive = trackingState is TrackingActive;
              final routeState = context.read<RouteBloc>().state;
              String routeName = 'Active Route';
              if (routeState is RoutesLoaded) {
                try {
                  routeName = routeState.routes
                      .firstWhere((r) => r.id == session.routeId)
                      .name;
                } catch (_) {}
              }
              return _ActiveTrackingBanner(
                routeName: routeName,
                distance: session.totalDistanceMeters,
                duration: session.duration,
                isActive: isActive,
                onTap: () =>
                    _openActiveTracking(context, session.routeId),
                onPause: () => context
                    .read<TrackingBloc>()
                    .add(const PauseTracking()),
                onResume: () => context
                    .read<TrackingBloc>()
                    .add(const ResumeTracking()),
              );
            },
          ),

          // ── Route list ────────────────────────────────────────────────
          Expanded(
            child: BlocConsumer<RouteBloc, RouteState>(
              listener: (context, state) {
                if (state is RouteSaved || state is RouteDeleted) {
                  context.read<RouteBloc>().add(const LoadRoutes());
                  if (state is RouteDeleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Route deleted.')),
                    );
                  }
                }
                if (state is RouteError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is RouteLoading ||
                    state is RouteInitial ||
                    state is RouteLoaded) {
                  return const LoadingWidget();
                }
                if (state is RouteError) {
                  return ErrorDisplayWidget(
                    message: state.message,
                    onRetry: () =>
                        context.read<RouteBloc>().add(const LoadRoutes()),
                  );
                }
                if (state is RoutesLoaded) {
                  if (state.routes.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.route_outlined,
                      title: 'No Routes Yet',
                      subtitle:
                          'Create your first route by tapping the button below.',
                      action: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Route'),
                        onPressed: () => _navigateToCreateRoute(context),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<RouteBloc>().add(const LoadRoutes());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: state.routes.length,
                      itemBuilder: (context, index) {
                        final route = state.routes[index];
                        return RouteCard(
                          route: route,
                          latestSession: null,
                          onOpen: () => _navigateToRouteDetails(route.id),
                          onStartTracking: () =>
                              _navigateToRouteDetails(route.id),
                          onExport: () =>
                              _navigateToRouteDetails(route.id),
                          onDelete: () =>
                              _onDeleteRoute(context, route.id),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateRoute(context),
        icon: const Icon(Icons.add),
        label: const Text('Create Route'),
      ),
    );
  }

  void _navigateToCreateRoute(BuildContext context) {
    Navigator.of(context).pushNamed('/create-route');
  }
}

// ── Permission banner ────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _PermissionBanner({
    required this.icon,
    required this.color,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: color.withValues(alpha: 0.25)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active tracking banner ───────────────────────────────────────────────────

class _ActiveTrackingBanner extends StatelessWidget {
  final String routeName;
  final double distance;
  final Duration duration;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _ActiveTrackingBanner({
    required this.routeName,
    required this.distance,
    required this.duration,
    required this.isActive,
    required this.onTap,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = isActive ? Colors.green : Colors.orange;

    return Material(
      color: statusColor.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: statusColor.withValues(alpha: 0.25)),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                isActive
                    ? Icons.radio_button_on
                    : Icons.pause_circle_outline,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${DistanceCalculator.formatDistance(distance)} · ${DateFormatter.formatDuration(duration)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isActive
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: statusColor,
                ),
                onPressed: isActive ? onPause : onResume,
                tooltip: isActive ? 'Pause tracking' : 'Resume tracking',
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
