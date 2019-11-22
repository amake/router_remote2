import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:equatable/equatable.dart';

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
}

class ConnectivityPermissionsChanged extends ConnectivityEvent {
  const ConnectivityPermissionsChanged();

  @override
  List<Object> get props => const [];
}

class ConnectivityUpdated extends ConnectivityEvent {
  final ConnectivityResult connectivity;
  final String wifiName;

  const ConnectivityUpdated({this.connectivity, this.wifiName});

  @override
  List<Object> get props => [connectivity, wifiName];
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

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  StreamSubscription<ConnectivityResult> _subscription;

  ConnectivityBloc() {
    _subscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    _init();
  }

  Future<void> _init() async {
    add(ConnectivityUpdated(
      connectivity: await Connectivity().checkConnectivity(),
      wifiName: await Connectivity().getWifiName(),
    ));
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    add(ConnectivityUpdated(
      connectivity: result,
      // Fetch Wi-Fi name here as well in case the network changed
      wifiName: await Connectivity().getWifiName(),
    ));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }

  @override
  ConnectivityState get initialState => const ConnectivityState();

  @override
  Stream<ConnectivityState> mapEventToState(ConnectivityEvent event) async* {
    if (event is ConnectivityPermissionsChanged) {
      yield state.copyWith(wifiName: await Connectivity().getWifiName());
    } else if (event is ConnectivityUpdated) {
      yield state.copyWith(
        connection: event.connectivity,
        wifiName: event.wifiName,
        initialized: true,
      );
    }
  }
}
