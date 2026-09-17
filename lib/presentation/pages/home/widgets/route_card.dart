import 'package:flutter/material.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../domain/entities/route_entity.dart';
import '../../../../domain/entities/tracking_session_entity.dart';

class RouteCard extends StatelessWidget {
  final RouteEntity route;
  final TrackingSessionEntity? latestSession;
  final VoidCallback onOpen;
  final VoidCallback onStartTracking;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const RouteCard({
    super.key,
    required this.route,
    this.latestSession,
    required this.onOpen,
    required this.onStartTracking,
    required this.onExport,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context, TrackingStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case TrackingStatus.tracking:
        return Colors.green;
      case TrackingStatus.paused:
        return Colors.orange;
      case TrackingStatus.completed:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _statusLabel(TrackingStatus? status) {
    if (status == null) return 'Created';
    switch (status) {
      case TrackingStatus.tracking:
        return 'In Progress';
      case TrackingStatus.paused:
        return 'Paused';
      case TrackingStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance =
        DistanceCalculator.totalDistance(route.coordinates);
    final status = latestSession?.status;

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      route.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(context, status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _statusColor(context, status).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _statusColor(context, status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDate(route.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.route_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    DistanceCalculator.formatDistance(distance),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.place_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    '${route.coordinates.length} pts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.map_outlined,
                    label: 'Open',
                    onTap: onOpen,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'Track',
                    onTap: onStartTracking,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Export',
                    onTap: onExport,
                    color: Colors.teal,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error),
                    onPressed: onDelete,
                    tooltip: 'Delete route',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.error.withValues(alpha: 0.1),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
