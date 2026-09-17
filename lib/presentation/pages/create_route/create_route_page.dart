import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/coordinate_entity.dart';
import '../../../domain/entities/route_entity.dart';
import '../../bloc/route/route_bloc.dart';
import 'package:uuid/uuid.dart';

class CreateRoutePage extends StatefulWidget {
  const CreateRoutePage({super.key});

  @override
  State<CreateRoutePage> createState() => _CreateRoutePageState();
}

class _CreateRoutePageState extends State<CreateRoutePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Route name cannot be empty.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final route = RouteEntity(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now().toUtc(),
      coordinates: const <CoordinateEntity>[],
    );

    if (!mounted) return;
    context.read<RouteBloc>().add(SaveRoute(route));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<RouteBloc, RouteState>(
      listener: (context, state) {
        if (state is RouteSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Route "${state.route.name}" created!')),
          );
          Navigator.of(context).pop();
        }
        if (state is RouteError) {
          setState(() {
            _isSaving = false;
            _error = state.message;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Route')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route Name',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  hintText: 'e.g. Colombo City Route',
                  prefixIcon: const Icon(Icons.drive_file_rename_outline),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_road),
                  label: Text(_isSaving ? 'Creating...' : 'Create Route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
