import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:equatable/equatable.dart';
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/connectivity_bloc.dart';
import 'package:router_remote2/shared_preferences_stream.dart';

class WifiAccessEvent extends Equatable {
  final String allowedPattern;
  final ConnectivityState connectivity;

  WifiAccessEvent({this.allowedPattern, this.connectivity})
      : super([allowedPattern, connectivity]);
}

class WifiAccessState extends Equatable {
  final String allowedPattern;
  final ConnectivityState connectivity;

  WifiAccessState({this.allowedPattern, this.connectivity})
      : super([allowedPattern, connectivity]);

  WifiAccessState copyWith({
    String allowedPattern,
    ConnectivityState connectivity,
  }) =>
      WifiAccessState(
        allowedPattern: allowedPattern ?? this.allowedPattern,
        connectivity: connectivity ?? this.connectivity,
      );

  WifiAccessStatus get status {
    if (connectivity == null) {
      return WifiAccessStatus.unknown;
    }
    if (connectivity.missingLocationPermissions && allowedPattern != null) {
      return WifiAccessStatus.insufficientPermissions;
    }
    if (connectivity.connection != ConnectivityResult.wifi) {
      return WifiAccessStatus.disconnected;
    }
    if (allowedPattern == null ||
        RegExp(allowedPattern).hasMatch(connectivity.wifiName)) {
      return WifiAccessStatus.connected;
    } else {
      return WifiAccessStatus.disallowed;
    }
  }
}

enum WifiAccessStatus {
  unknown,
  connected,
  disconnected,
  disallowed,
  insufficientPermissions
}

class WifiAccessBloc extends Bloc<WifiAccessEvent, WifiAccessState> {
  final ConnectivityBloc connectivityBloc;
  StreamSubscription<String> _patternSubscription;
  StreamSubscription<ConnectivityState> _connectivitySubscription;

  WifiAccessBloc(this.connectivityBloc) {
    _patternSubscription = SharedPreferencesStream()
        .streamForKey<String>(AppSettings.allowedWifiPattern)
        .listen(
            (pattern) => dispatch(WifiAccessEvent(allowedPattern: pattern)));
    _connectivitySubscription = connectivityBloc.state.listen((connectivity) =>
        dispatch(WifiAccessEvent(connectivity: connectivity)));
  }

  @override
  void dispose() {
    _patternSubscription.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  WifiAccessState get initialState => WifiAccessState();

  @override
  Stream<WifiAccessState> mapEventToState(WifiAccessEvent event) async* {
    yield currentState.copyWith(
      allowedPattern: event.allowedPattern,
      connectivity: event.connectivity,
    );
  }
}
