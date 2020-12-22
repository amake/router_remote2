import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:equatable/equatable.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';

abstract class _ConnectivityEvent extends Equatable {
  const _ConnectivityEvent();
}

class _RefreshConnectivity extends _ConnectivityEvent {
  const _RefreshConnectivity();

  @override
  List<Object> get props => const [];
}

class ConnectivityState extends Equatable {
  final ConnectivityResult connection;
  final String wifiName;
  final bool initialized;

  const ConnectivityState(
      {this.connection, this.wifiName, this.initialized = false})
      : assert(initialized != null);

  ConnectivityState copyWith({
    ConnectivityResult connection,
    String wifiName,
    bool initialized,
  }) =>
      ConnectivityState(
        connection: connection ?? this.connection,
        wifiName: wifiName ?? this.wifiName,
        initialized: initialized ?? this.initialized,
      );

  bool get missingLocationPermissions =>
      initialized && connection == ConnectivityResult.wifi && wifiName == null;

  @override
  List<Object> get props => [connection, wifiName, initialized];
}

class ConnectivityBloc extends Bloc<_ConnectivityEvent, ConnectivityState> {
  StreamSubscription<ConnectivityResult> _subscription;

  ConnectivityBloc() {
    _subscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    refresh();
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async =>
      refresh();

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }

  @override
  ConnectivityState get initialState => const ConnectivityState();

  @override
  Stream<ConnectivityState> mapEventToState(_ConnectivityEvent event) async* {
    if (event is _RefreshConnectivity) {
      yield state.copyWith(
        wifiName: await WifiInfo().getWifiName(),
        connection: await Connectivity().checkConnectivity(),
        initialized: true,
      );
    }
  }

  void refresh() => add(const _RefreshConnectivity());
}
