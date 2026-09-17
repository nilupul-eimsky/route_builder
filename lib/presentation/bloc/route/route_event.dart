part of 'route_bloc.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class LoadRoutes extends RouteEvent {
  const LoadRoutes();
}

class LoadRoute extends RouteEvent {
  final String id;

  const LoadRoute(this.id);

  @override
  List<Object?> get props => [id];
}

class SaveRoute extends RouteEvent {
  final RouteEntity route;

  const SaveRoute(this.route);

  @override
  List<Object?> get props => [route];
}

class DeleteRoute extends RouteEvent {
  final String routeId;

  const DeleteRoute(this.routeId);

  @override
  List<Object?> get props => [routeId];
}
