import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:equatable/equatable.dart';

class ConnectivityEvent extends Equatable {
  ConnectivityEvent([List props = const []]) : super(props);
}

class ConnectivityPermissionsChanged extends ConnectivityEvent {}

class ConnectivityUpdated extends ConnectivityEvent {
  final ConnectivityResult connectivity;
  final String wifiName;

  ConnectivityUpdated({this.connectivity, this.wifiName})
      : super([connectivity, wifiName]);
}

class ConnectivityState extends Equatable {
  final ConnectivityResult connection;
  final String wifiName;
  final bool initialized;

  ConnectivityState({this.connection, this.wifiName, this.initialized = false})
      : assert(initialized != null),
        super([connection, wifiName, initialized]);

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
  ConnectivityState get initialState => ConnectivityState();

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
