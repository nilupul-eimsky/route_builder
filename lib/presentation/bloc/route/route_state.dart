part of 'route_bloc.dart';

abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

class RouteInitial extends RouteState {
  const RouteInitial();
}

class RouteLoading extends RouteState {
  const RouteLoading();
}

class RoutesLoaded extends RouteState {
  final List<RouteEntity> routes;

  const RoutesLoaded(this.routes);

  @override
  List<Object?> get props => [routes];
}

class RouteLoaded extends RouteState {
  final RouteEntity route;

  const RouteLoaded(this.route);

  @override
  List<Object?> get props => [route];
}

class RouteSaved extends RouteState {
  final RouteEntity route;

  const RouteSaved(this.route);

  @override
  List<Object?> get props => [route];
}

class RouteDeleted extends RouteState {
  final String routeId;

  const RouteDeleted(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class RouteError extends RouteState {
  final String message;

  const RouteError(this.message);

  @override
  List<Object?> get props => [message];
}
