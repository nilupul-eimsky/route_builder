import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/settings/settings_cubit.dart';
import '../../cubit/settings/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const List<_IntervalOption> _intervalOptions = [
    _IntervalOption(seconds: 1, label: '1 second'),
    _IntervalOption(seconds: 5, label: '5 seconds'),
    _IntervalOption(seconds: 10, label: '10 seconds'),
    _IntervalOption(seconds: 15, label: '15 seconds'),
    _IntervalOption(seconds: 30, label: '30 seconds'),
    _IntervalOption(seconds: 60, label: '1 minute'),
    _IntervalOption(seconds: 300, label: '5 minutes'),
  ];

  static const List<_MovementOption> _movementOptions = [
    _MovementOption(meters: 10, label: '10 meters'),
    _MovementOption(meters: 50, label: '50 meters'),
    _MovementOption(meters: 100, label: '100 meters'),
    _MovementOption(meters: 200, label: '200 meters'),
    _MovementOption(meters: 500, label: '500 meters'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          // Clamp stored value to nearest valid option
          final currentMovement =
              _movementOptions.any(
                (o) => o.meters == state.settings.minMovementMeters,
              )
              ? state.settings.minMovementMeters
              : 100.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Location settings section
              Text(
                'Location',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.timer_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Recording Interval'),
                      subtitle: const Text(
                        'How often GPS position is recorded',
                      ),
                      trailing: state.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButton<int>(
                              value: state.settings.locationIntervalSeconds,
                              underline: const SizedBox.shrink(),
                              items: _intervalOptions
                                  .map(
                                    (opt) => DropdownMenuItem(
                                      value: opt.seconds,
                                      child: Text(opt.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<SettingsCubit>().updateInterval(
                                    value,
                                  );
                                }
                              },
                            ),
                    ),
                    const Divider(height: 0, indent: 56),
                    ListTile(
                      leading: Icon(
                        Icons.straighten,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Minimum Movement'),
                      subtitle: const Text(
                        'Points closer than this to the last recorded point are ignored',
                      ),
                      trailing: state.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : DropdownButton<double>(
                              value: currentMovement,
                              underline: const SizedBox.shrink(),
                              items: _movementOptions
                                  .map(
                                    (opt) => DropdownMenuItem(
                                      value: opt.meters,
                                      child: Text(opt.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<SettingsCubit>()
                                      .updateMinMovement(value);
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // // GPS filtering info section
              // Text(
              //   'GPS Filtering',
              //   style: theme.textTheme.titleSmall?.copyWith(
              //     color: theme.colorScheme.primary,
              //     fontWeight: FontWeight.w700,
              //     letterSpacing: 0.5,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Card(
              //   margin: EdgeInsets.zero,
              //   child: Column(
              //     children: [
              //       _InfoTile(
              //         icon: Icons.gps_fixed,
              //         title: 'Minimum Movement',
              //         subtitle: '${currentMovement.toStringAsFixed(0)} meters',
              //         description:
              //             'Points closer than ${currentMovement.toStringAsFixed(0)} m to the last recorded point are ignored. Configurable above.',
              //       ),
              //       const Divider(height: 0, indent: 56),
              //       _InfoTile(
              //         icon: Icons.radar,
              //         title: 'Maximum GPS Accuracy',
              //         subtitle: '50 meters',
              //         description:
              //             'Points with accuracy worse than 50 m are discarded.',
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),
              // About section
              Text(
                'About',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text('Route Builder'),
                      subtitle: const Text('Version 1.0.0'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntervalOption {
  final int seconds;
  final String label;

  const _IntervalOption({required this.seconds, required this.label});
}

class _MovementOption {
  final double meters;
  final String label;

  const _MovementOption({required this.meters, required this.label});
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
