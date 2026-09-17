import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../bloc/tracking/tracking_bloc.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../domain/entities/app_settings_entity.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../domain/entities/route_stop_entity.dart';
import '../../../domain/entities/tracking_session_entity.dart';
import '../../widgets/app_loading.dart';
import '../tracking_summary/tracking_summary_page.dart';

class TrackingPage extends StatefulWidget {
  final RouteEntity route;
  final AppSettingsEntity settings;

  const TrackingPage({
    super.key,
    required this.route,
    required this.settings,
  });

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  GoogleMapController? _mapController;
  bool _followLocation = true;
  bool _sessionStarted = false; // true once TrackingActive is first received
  int _lastKnownStopCount = 0;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<TrackingBloc>().state;
    final alreadyActive =
        (currentState is TrackingActive &&
            currentState.session.routeId == widget.route.id) ||
        (currentState is TrackingPaused &&
            currentState.session.routeId == widget.route.id);

    if (alreadyActive) _sessionStarted = true;

    final trackingDifferentRoute =
        (currentState is TrackingActive || currentState is TrackingPaused) &&
        !alreadyActive;

    if (trackingDifferentRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Another route is already being tracked. Stop it first.'),
            ),
          );
          Navigator.of(context).pop();
        }
      });
      return;
    }

    if (!alreadyActive) {
      context.read<TrackingBloc>().add(
            StartTracking(
              routeId: widget.route.id,
              settings: widget.settings,
            ),
          );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Polyline> _buildPolylines(TrackingState state) {
    TrackingSessionEntity? session;
    if (state is TrackingActive) session = state.session;
    if (state is TrackingPaused) session = state.session;

    if (session == null || session.points.length < 2) return {};

    return {
      Polyline(
        polylineId: const PolylineId('gps_track'),
        color: Theme.of(context).colorScheme.primary,
        width: 4,
        points: session.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
      ),
    };
  }

  Set<Marker> _buildMarkers(TrackingState state) {
    final markers = <Marker>{};

    // Current location marker
    double? currentLat, currentLng;
    if (state is TrackingActive) {
      currentLat = state.currentLatitude;
      currentLng = state.currentLongitude;
    } else if (state is TrackingPaused) {
      currentLat = state.currentLatitude;
      currentLng = state.currentLongitude;
    }

    if (currentLat != null && currentLng != null &&
        (currentLat != 0.0 || currentLng != 0.0)) {
      markers.add(Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(currentLat, currentLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    }

    // Stop markers
    TrackingSessionEntity? session;
    if (state is TrackingActive) session = state.session;
    if (state is TrackingPaused) session = state.session;

    if (session != null) {
      for (final stop in session.stops) {
        markers.add(_buildStopMarker(stop));
      }
    }

    return markers;
  }

  Marker _buildStopMarker(RouteStopEntity stop) {
    return Marker(
      markerId: MarkerId('stop_${stop.id}'),
      position: LatLng(stop.latitude, stop.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(
        title: stop.name,
        snippet: 'Stop · ${DateFormatter.formatTime(stop.recordedAt)}',
      ),
    );
  }

  void _moveCameraToLocation(double lat, double lng) {
    if (_followLocation && _mapController != null &&
        (lat != 0.0 || lng != 0.0)) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
  }

  Future<void> _confirmStop(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Tracking'),
        content: const Text('Are you sure you want to stop tracking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TrackingBloc>().add(const StopTracking());
    }
  }

  Future<void> _showAddStopDialog(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Stop'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Stop name',
            hintText: 'e.g. Rest area, Water point',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    // Read text before dispose; defer both to the next frame so the focus
    // system finishes clearing composing text before the controller is gone.
    final name = controller.text.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
      if (confirmed == true && name.isNotEmpty && context.mounted) {
        context.read<TrackingBloc>().add(AddStop(name));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingBloc, TrackingState>(
      listener: (context, state) {
        if (state is TrackingActive) {
          _sessionStarted = true;
          _lastKnownStopCount = state.session.stops.length;
          if (_followLocation) {
            _moveCameraToLocation(
                state.currentLatitude, state.currentLongitude);
          }
        }
        if (state is TrackingCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) =>
                  TrackingSummaryPage(session: state.session, route: widget.route),
            ),
          );
        }
        if (state is TrackingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          // Only pop if error happened before a session was ever established
          if (!_sessionStarted) {
            Navigator.of(context).pop();
          }
        }
        if (state is TrackingPaused) {
          // Only show snackbar when a new stop was added (stop count increased)
          final currentStopCount = state.session.stops.length;
          if (currentStopCount > _lastKnownStopCount) {
            _lastKnownStopCount = currentStopCount;
            final lastStop = state.session.stops.last;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Stop "${lastStop.name}" added. Tracking paused.'),
                  action: SnackBarAction(
                    label: 'Resume',
                    onPressed: () {
                      context.read<TrackingBloc>().add(const ResumeTracking());
                    },
                  ),
                ),
              );
          }
        }
      },
      builder: (context, state) {
        if (state is TrackingInitial) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.route.name)),
            body: const LoadingWidget(message: 'Starting tracking...'),
          );
        }

        TrackingSessionEntity? session;
        double accuracy = 0.0;
        bool isPaused = false;

        if (state is TrackingActive) {
          session = state.session;
          accuracy = state.accuracy;
        } else if (state is TrackingPaused) {
          session = state.session;
          accuracy = state.accuracy;
          isPaused = true;
        }

        final distance = session?.totalDistanceMeters ?? 0.0;
        final duration = session?.duration ?? Duration.zero;
        final stopCount = session?.stops.length ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.route.name),
            actions: [
              IconButton(
                icon: Icon(
                  _followLocation ? Icons.my_location : Icons.location_disabled,
                  color: _followLocation ? Colors.white : Colors.white54,
                ),
                onPressed: () {
                  setState(() => _followLocation = !_followLocation);
                },
                tooltip: _followLocation ? 'Following location' : 'Not following',
              ),
            ],
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: () {
                    if (state is TrackingActive &&
                        (state.currentLatitude != 0.0 ||
                            state.currentLongitude != 0.0)) {
                      return LatLng(state.currentLatitude,
                          state.currentLongitude);
                    }
                    if (state is TrackingPaused &&
                        (state.currentLatitude != 0.0 ||
                            state.currentLongitude != 0.0)) {
                      return LatLng(state.currentLatitude,
                          state.currentLongitude);
                    }
                    return const LatLng(0, 0);
                  }(),
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  final s = context.read<TrackingBloc>().state;
                  double? lat, lng;
                  if (s is TrackingActive &&
                      (s.currentLatitude != 0.0 ||
                          s.currentLongitude != 0.0)) {
                    lat = s.currentLatitude;
                    lng = s.currentLongitude;
                  } else if (s is TrackingPaused &&
                      (s.currentLatitude != 0.0 ||
                          s.currentLongitude != 0.0)) {
                    lat = s.currentLatitude;
                    lng = s.currentLongitude;
                  }
                  if (lat != null && lng != null) {
                    Future.microtask(
                        () => _moveCameraToLocation(lat!, lng!));
                  }
                },
                markers: _buildMarkers(state),
                polylines: _buildPolylines(state),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),
              // Stats bar at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _TrackingControlPanel(
                  distance: distance,
                  duration: duration,
                  accuracy: accuracy,
                  isPaused: isPaused,
                  stopCount: stopCount,
                  onPause: () =>
                      context.read<TrackingBloc>().add(const PauseTracking()),
                  onResume: () =>
                      context.read<TrackingBloc>().add(const ResumeTracking()),
                  onStop: () => _confirmStop(context),
                  onAddStop: () => _showAddStopDialog(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackingControlPanel extends StatefulWidget {
  final double distance;
  final Duration duration;
  final double accuracy;
  final bool isPaused;
  final int stopCount;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onAddStop;

  const _TrackingControlPanel({
    required this.distance,
    required this.duration,
    required this.accuracy,
    required this.isPaused,
    required this.stopCount,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onAddStop,
  });

  @override
  State<_TrackingControlPanel> createState() => _TrackingControlPanelState();
}

class _TrackingControlPanelState extends State<_TrackingControlPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isPaused
                          ? Colors.orange.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isPaused
                              ? Icons.pause_circle_outline
                              : Icons.radio_button_on,
                          size: 14,
                          color: widget.isPaused ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isPaused ? 'Paused' : 'Tracking',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.isPaused ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.stopCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_outlined,
                              size: 14, color: Colors.deepOrange),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.stopCount} stop${widget.stopCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                    label: 'Distance',
                    value: DistanceCalculator.formatDistance(widget.distance),
                    icon: Icons.route_outlined,
                  ),
                  _StatBox(
                    label: 'Duration',
                    value: DateFormatter.formatDuration(widget.duration),
                    icon: Icons.timer_outlined,
                  ),
                  _StatBox(
                    label: 'Accuracy',
                    value: '${widget.accuracy.toStringAsFixed(0)} m',
                    icon: Icons.gps_fixed,
                    color: widget.accuracy > 20 ? Colors.orange : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Control buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          widget.isPaused ? widget.onResume : widget.onPause,
                      icon: Icon(widget.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause),
                      label: Text(widget.isPaused ? 'Resume' : 'Pause'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            widget.isPaused ? Colors.green : Colors.orange,
                        side: BorderSide(
                            color: widget.isPaused
                                ? Colors.green
                                : Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onAddStop,
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Add Stop'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepOrange,
                        side: const BorderSide(color: Colors.deepOrange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onStop,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.primary;
    return Column(
      children: [
        Icon(icon, size: 18, color: displayColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: displayColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
