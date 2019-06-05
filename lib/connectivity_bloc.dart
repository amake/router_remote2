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
  final bool initEvent;

  ConnectivityUpdated(
      {this.connectivity, this.wifiName, this.initEvent = false})
      : assert(initEvent != null),
        super([connectivity, wifiName, initEvent]);
}

class ConnectivityState extends Equatable {
  final ConnectivityResult connection;
  final String wifiName;
  final bool initialized;

  ConnectivityState({this.connection, this.wifiName, this.initialized = false})
      : assert(initialized != null),
        super([connection, wifiName, initialized]);

  ConnectivityState updatedWith(ConnectivityUpdated event) {
    return ConnectivityState(
        connection: event.connectivity ?? connection,
        wifiName: event.wifiName ?? wifiName,
        initialized: initialized || event.initEvent);
  }

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
    dispatch(ConnectivityUpdated(
      connectivity: await Connectivity().checkConnectivity(),
      wifiName: await Connectivity().getWifiName(),
      initEvent: true,
    ));
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    dispatch(ConnectivityUpdated(
      connectivity: result,
      // Fetch Wi-Fi name here as well in case the network changed
      wifiName: await Connectivity().getWifiName(),
    ));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  ConnectivityState get initialState => ConnectivityState();

  @override
  Stream<ConnectivityState> mapEventToState(ConnectivityEvent event) async* {
    if (event is ConnectivityPermissionsChanged) {
      yield currentState.updatedWith(
          ConnectivityUpdated(wifiName: await Connectivity().getWifiName()));
    } else if (event is ConnectivityUpdated) {
      yield currentState.updatedWith(event);
    }
  }
}
