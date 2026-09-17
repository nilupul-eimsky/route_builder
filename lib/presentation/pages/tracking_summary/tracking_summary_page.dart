import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../core/utils/geojson_serializer.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../domain/entities/route_stop_entity.dart';
import '../../../domain/entities/tracking_session_entity.dart';
import '../json_viewer/json_viewer_page.dart';

class TrackingSummaryPage extends StatefulWidget {
  final TrackingSessionEntity session;
  final RouteEntity route;

  const TrackingSummaryPage({
    super.key,
    required this.session,
    required this.route,
  });

  @override
  State<TrackingSummaryPage> createState() => _TrackingSummaryPageState();
}

class _TrackingSummaryPageState extends State<TrackingSummaryPage> {
  GoogleMapController? _mapController;

  CameraPosition get _initialCamera {
    if (widget.route.coordinates.isNotEmpty) {
      return CameraPosition(
        target: LatLng(
          widget.route.coordinates.first.latitude,
          widget.route.coordinates.first.longitude,
        ),
        zoom: 14,
      );
    }
    return const CameraPosition(target: LatLng(0, 0), zoom: 2);
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};

    if (widget.route.coordinates.length >= 2) {
      polylines.add(Polyline(
        polylineId: const PolylineId('planned_route'),
        color: Colors.blue.withValues(alpha: 0.6),
        width: 4,
        points: widget.route.coordinates
            .map((c) => LatLng(c.latitude, c.longitude))
            .toList(),
      ));
    }

    if (widget.session.points.length >= 2) {
      polylines.add(Polyline(
        polylineId: const PolylineId('gps_track'),
        color: Colors.orange,
        width: 4,
        points: widget.session.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
      ));
    }

    return polylines;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (widget.session.points.isNotEmpty) {
      final start = widget.session.points.first;
      markers.add(Marker(
        markerId: const MarkerId('track_start'),
        position: LatLng(start.latitude, start.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Track Start'),
      ));
      if (widget.session.points.length > 1) {
        final end = widget.session.points.last;
        markers.add(Marker(
          markerId: const MarkerId('track_end'),
          position: LatLng(end.latitude, end.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Track End'),
        ));
      }
    }

    // Stop markers
    for (final stop in widget.session.stops) {
      markers.add(_buildStopMarker(stop));
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

  void _fitBounds() {
    if (_mapController == null) return;
    final allPoints = [
      ...widget.route.coordinates
          .map((c) => LatLng(c.latitude, c.longitude)),
      ...widget.session.points
          .map((p) => LatLng(p.latitude, p.longitude)),
      ...widget.session.stops
          .map((s) => LatLng(s.latitude, s.longitude)),
    ];
    if (allPoints.length < 2) return;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

  Future<void> _exportGeoJson() async {
    final content =
        GeoJsonSerializer.toFeatureCollectionString(widget.route, widget.session);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(widget.route.name)}_tracking.geojson');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/geo+json')],
      subject: widget.route.name,
    );
  }

  Future<void> _exportJson() async {
    final data = {
      'session': {
        'id': widget.session.id,
        'routeId': widget.session.routeId,
        'startedAt': widget.session.startedAt.toUtc().toIso8601String(),
        'endedAt': widget.session.endedAt?.toUtc().toIso8601String(),
        'status': widget.session.status.name,
        'totalDistanceMeters': widget.session.totalDistanceMeters,
        'points': widget.session.points
            .map((p) => {
                  'latitude': p.latitude,
                  'longitude': p.longitude,
                  'timestamp': p.timestamp.toUtc().toIso8601String(),
                  'accuracy': p.accuracy,
                  'speed': p.speed,
                  if (p.altitude != null) 'altitude': p.altitude,
                })
            .toList(),
        'stops': widget.session.stops
            .map((s) => {
                  'id': s.id,
                  'name': s.name,
                  'latitude': s.latitude,
                  'longitude': s.longitude,
                  'recordedAt': s.recordedAt.toUtc().toIso8601String(),
                })
            .toList(),
      },
    };
    final content = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(widget.route.name)}_tracking.json');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: widget.route.name,
    );
  }

  Widget _exportButtons(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (icon: Icons.code, label: 'View JSON', onTap: _viewJson),
      (icon: Icons.map_outlined, label: 'GeoJSON', onTap: () => _exportGeoJson()),
      (icon: Icons.share_outlined, label: 'JSON', onTap: () => _exportJson()),
    ];
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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

  void _viewJson() {
    final data = {
      'sessionId': widget.session.id,
      'routeId': widget.session.routeId,
      'routeName': widget.route.name,
      'startedAt': widget.session.startedAt.toUtc().toIso8601String(),
      'endedAt': widget.session.endedAt?.toUtc().toIso8601String(),
      'totalDistanceMeters': widget.session.totalDistanceMeters,
      'status': widget.session.status.name,
      'points': widget.session.points
          .map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
                'timestamp': p.timestamp.toUtc().toIso8601String(),
                'accuracy': p.accuracy,
                'speed': p.speed,
                if (p.altitude != null) 'altitude': p.altitude,
              })
          .toList(),
      'stops': widget.session.stops
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'latitude': s.latitude,
                'longitude': s.longitude,
                'recordedAt': s.recordedAt.toUtc().toIso8601String(),
              })
          .toList(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(data);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JsonViewerPage(
          json: json,
          title: 'Session JSON',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final distance = session.totalDistanceMeters;
    final duration = session.duration;
    final avgSpeed = session.averageSpeedMs;
    final stops = session.stops;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Summary'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: _initialCamera,
                onMapCreated: (controller) {
                  _mapController = controller;
                  Future.delayed(const Duration(milliseconds: 300), _fitBounds);
                },
                polylines: _buildPolylines(),
                markers: _buildMarkers(),
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Completion banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tracking Completed',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                widget.route.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.green.shade700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats grid
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryStatTile(
                                  icon: Icons.route_outlined,
                                  label: 'Distance',
                                  value: DistanceCalculator.formatDistance(
                                      distance),
                                ),
                              ),
                              Expanded(
                                child: _SummaryStatTile(
                                  icon: Icons.timer_outlined,
                                  label: 'Duration',
                                  value: DateFormatter.formatDuration(duration),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryStatTile(
                                  icon: Icons.place_outlined,
                                  label: 'GPS Points',
                                  value: '${session.points.length}',
                                ),
                              ),
                              Expanded(
                                child: _SummaryStatTile(
                                  icon: Icons.speed,
                                  label: 'Avg Speed',
                                  value: DateFormatter.formatSpeed(avgSpeed),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryStatTile(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'Start',
                                  value: DateFormatter.formatDateTime(
                                      session.startedAt),
                                ),
                              ),
                              if (session.endedAt != null)
                                Expanded(
                                  child: _SummaryStatTile(
                                    icon: Icons.stop_rounded,
                                    label: 'End',
                                    value: DateFormatter.formatDateTime(
                                        session.endedAt!),
                                  ),
                                ),
                            ],
                          ),
                          if (stops.isNotEmpty) ...[
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _SummaryStatTile(
                                    icon: Icons.flag_outlined,
                                    label: 'Stops',
                                    value: '${stops.length}',
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Map legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _LegendItem(
                          color: Colors.blue.withValues(alpha: 0.7),
                          label: 'Planned Route'),
                      const _LegendItem(
                          color: Colors.orange, label: 'GPS Track'),
                      if (stops.isNotEmpty)
                        const _LegendItem(
                            color: Colors.deepOrange, label: 'Stops',
                            isMarker: true),
                    ],
                  ),
                  // Stops list
                  if (stops.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Stops',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: stops.asMap().entries.map((entry) {
                          final index = entry.key;
                          final stop = entry.value;
                          return Column(
                            children: [
                              if (index > 0)
                                const Divider(height: 0, indent: 56),
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      Colors.deepOrange.withValues(alpha: 0.15),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ),
                                title: Text(stop.name),
                                subtitle: Text(
                                    DateFormatter.formatDateTime(stop.recordedAt)),
                                dense: true,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Export buttons
                  Text('Export',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _exportButtons(context),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isMarker;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isMarker = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMarker)
          Icon(Icons.location_on, size: 16, color: color)
        else
          Container(
            width: 20,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
