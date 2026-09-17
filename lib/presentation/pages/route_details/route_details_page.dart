import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../bloc/route/route_bloc.dart';
import '../../bloc/tracking/tracking_bloc.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../core/utils/geojson_serializer.dart';
import '../../cubit/settings/settings_cubit.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../domain/entities/tracking_session_entity.dart';
import '../../../domain/usecases/tracking/get_sessions_for_route_usecase.dart';
import '../../widgets/app_error_display.dart';
import '../../widgets/app_loading.dart';
import '../json_viewer/json_viewer_page.dart';
import '../tracking/tracking_page.dart';
import '../tracking_summary/tracking_summary_page.dart';

class RouteDetailsPage extends StatefulWidget {
  final String routeId;

  const RouteDetailsPage({super.key, required this.routeId});

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  List<TrackingSessionEntity> _sessions = [];

  @override
  void initState() {
    super.initState();
    context.read<RouteBloc>().add(LoadRoute(widget.routeId));
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await context
        .read<GetSessionsForRouteUseCase>()
        .call(widget.routeId);
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (mounted) setState(() => _sessions = sessions);
  }

  String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

  Future<void> _exportGeoJson(RouteEntity route) async {
    final content = GeoJsonSerializer.routeToGeoJsonString(route);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(route.name)}.geojson');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/geo+json')],
      subject: route.name,
    );
  }

  Map<String, dynamic> _buildRouteJson(RouteEntity route) {
    return {
      'id': route.id,
      'name': route.name,
      'createdAt': route.createdAt.toUtc().toIso8601String(),
      'coordinates': route.coordinates
          .map((c) => {'latitude': c.latitude, 'longitude': c.longitude})
          .toList(),
      'sessions': _sessions.map((s) {
        return {
          'id': s.id,
          'startedAt': s.startedAt.toUtc().toIso8601String(),
          'endedAt': s.endedAt?.toUtc().toIso8601String(),
          'status': s.status.name,
          'totalDistanceMeters': s.totalDistanceMeters,
          'pointCount': s.points.length,
          'points': s.points
              .map((p) => {
                    'latitude': p.latitude,
                    'longitude': p.longitude,
                    'timestamp': p.timestamp.toUtc().toIso8601String(),
                    'accuracy': p.accuracy,
                    'speed': p.speed,
                    if (p.altitude != null) 'altitude': p.altitude,
                  })
              .toList(),
          'stops': s.stops
              .map((stop) => {
                    'id': stop.id,
                    'name': stop.name,
                    'latitude': stop.latitude,
                    'longitude': stop.longitude,
                    'recordedAt': stop.recordedAt.toUtc().toIso8601String(),
                  })
              .toList(),
        };
      }).toList(),
    };
  }

  Future<void> _exportJson(RouteEntity route) async {
    final content =
        const JsonEncoder.withIndent('  ').convert(_buildRouteJson(route));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(route.name)}.json');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: route.name,
    );
  }

  void _viewJson(RouteEntity route) {
    final json = const JsonEncoder.withIndent('  ').convert(_buildRouteJson(route));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            JsonViewerPage(json: json, title: 'Route: ${route.name}'),
      ),
    );
  }

  void _startTracking(RouteEntity route) {
    final settings = context.read<SettingsCubit>().state.settings;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => TrackingPage(route: route, settings: settings),
        ))
        .then((_) { if (mounted) _loadSessions(); });
  }

  void _deleteRoute(RouteEntity route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text(
            'Delete this route and all its tracking sessions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<RouteBloc>().add(DeleteRoute(route.id));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RouteBloc, RouteState>(
      builder: (context, state) {
        if (state is RouteLoading || state is RouteInitial) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route Details')),
            body: const LoadingWidget(),
          );
        }
        if (state is RouteError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Route Details')),
            body: ErrorDisplayWidget(
              message: state.message,
              onRetry: () =>
                  context.read<RouteBloc>().add(LoadRoute(widget.routeId)),
            ),
          );
        }
        if (state is RouteLoaded) {
          final route = state.route;

          return Scaffold(
            appBar: AppBar(title: Text(route.name)),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Start / Resume tracking ───────────────────────────────
                BlocBuilder<TrackingBloc, TrackingState>(
                  builder: (context, trackingState) {
                    final isResumable =
                        (trackingState is TrackingActive &&
                                trackingState.session.routeId == route.id) ||
                            (trackingState is TrackingPaused &&
                                trackingState.session.routeId == route.id);
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startTracking(route),
                        icon: Icon(isResumable
                            ? Icons.play_circle_outline
                            : Icons.play_arrow_rounded),
                        label: Text(isResumable
                            ? 'Resume Tracking'
                            : 'Start Tracking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isResumable ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Route info ────────────────────────────────────────────
                Text('Route Information',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.drive_file_rename_outline,
                          label: 'Name',
                          value: route.name,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Created',
                          value: DateFormatter.formatDateTime(route.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Past Sessions ─────────────────────────────────────────
                Text('Past Sessions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                if (_sessions.isEmpty)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.history,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4)),
                          const SizedBox(width: 12),
                          Text(
                            'No sessions recorded yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: _sessions.map((session) {
                      return _SessionCard(
                        session: session,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackingSummaryPage(
                              session: session,
                              route: route,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),

                // ── Export ────────────────────────────────────────────────
                Text('Export',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _exportButtonStyle(
                  context,
                  items: [
                    _ExportItem(
                      icon: Icons.code,
                      label: 'View JSON',
                      onTap: () => _viewJson(route),
                    ),
                    _ExportItem(
                      icon: Icons.map_outlined,
                      label: 'GeoJSON',
                      onTap: () => _exportGeoJson(route),
                    ),
                    _ExportItem(
                      icon: Icons.share_outlined,
                      label: 'JSON',
                      onTap: () => _exportJson(route),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Danger zone ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteRoute(route),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Route'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ExportItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ExportItem(
      {required this.icon, required this.label, required this.onTap});
}

Widget _exportButtonStyle(BuildContext context,
    {required List<_ExportItem> items}) {
  final color = Theme.of(context).colorScheme.primary;
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items.asMap().entries.expand((entry) {
        final i = entry.key;
        final item = entry.value;
        return [
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: item.onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                side: BorderSide(color: color),
                foregroundColor: color,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 16),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ];
      }).toList(),
    ),
  );
}

class _SessionCard extends StatelessWidget {
  final TrackingSessionEntity session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = session.status == TrackingStatus.completed;
    final hasStops = session.stops.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_outline
                        : Icons.radio_button_on,
                    color: isCompleted ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormatter.formatDateTime(session.startedAt),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            _StatChip(
                              icon: Icons.route_outlined,
                              label: DistanceCalculator.formatDistance(
                                  session.totalDistanceMeters),
                            ),
                            _StatChip(
                              icon: Icons.timer_outlined,
                              label: DateFormatter.formatDuration(
                                  session.duration),
                            ),
                            _StatChip(
                              icon: Icons.place_outlined,
                              label: '${session.points.length} pts',
                            ),
                            if (hasStops)
                              _StatChip(
                                icon: Icons.flag_outlined,
                                label:
                                    '${session.stops.length} stop${session.stops.length > 1 ? 's' : ''}',
                                color: Colors.deepOrange,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
              if (hasStops) ...[
                const SizedBox(height: 10),
                const Divider(height: 0),
                const SizedBox(height: 8),
                ...session.stops.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stop = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor:
                              Colors.deepOrange.withValues(alpha: 0.15),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            stop.name,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          DateFormatter.formatTime(stop.recordedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ??
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
