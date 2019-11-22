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

  const WifiAccessEvent({this.allowedPattern, this.connectivity});

  @override
  List<Object> get props => [allowedPattern, connectivity];
}

class WifiAccessState extends Equatable {
  final String allowedPattern;
  final ConnectivityState connectivity;

  const WifiAccessState({this.allowedPattern, this.connectivity});

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

  @override
  List<Object> get props => [allowedPattern, connectivity];
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
        .listen((pattern) => add(WifiAccessEvent(allowedPattern: pattern)));
    _connectivitySubscription = connectivityBloc.listen(
        (connectivity) => add(WifiAccessEvent(connectivity: connectivity)));
  }

  @override
  Future<void> close() {
    _patternSubscription.cancel();
    _connectivitySubscription.cancel();
    return super.close();
  }

  @override
  WifiAccessState get initialState => const WifiAccessState();

  @override
  Stream<WifiAccessState> mapEventToState(WifiAccessEvent event) async* {
    yield state.copyWith(
      allowedPattern: event.allowedPattern,
      connectivity: event.connectivity,
    );
  }
}
