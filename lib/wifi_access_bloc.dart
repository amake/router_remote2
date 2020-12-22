import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:equatable/equatable.dart';
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/connectivity_bloc.dart';
import 'package:router_remote2/shared_preferences_stream.dart';

abstract class _WifiAccessEvent extends Equatable {
  const _WifiAccessEvent();
}

class _PatternUpdated extends _WifiAccessEvent {
  final String allowedPattern;

  const _PatternUpdated(this.allowedPattern);

  @override
  List<Object> get props => [allowedPattern];
}

class _ConnectivityUpdated extends _WifiAccessEvent {
  final ConnectivityState connectivity;

  const _ConnectivityUpdated(this.connectivity);

  @override
  List<Object> get props => [connectivity];
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

class WifiAccessBloc extends Bloc<_WifiAccessEvent, WifiAccessState> {
  final ConnectivityBloc connectivityBloc;
  StreamSubscription<String> _patternSubscription;
  StreamSubscription<ConnectivityState> _connectivitySubscription;

  WifiAccessBloc(this.connectivityBloc) : super(const WifiAccessState()) {
    _patternSubscription = SharedPreferencesStream()
        .streamForKey<String>(AppSettings.allowedWifiPattern)
        .listen((pattern) => add(_PatternUpdated(pattern)));
    _connectivitySubscription = connectivityBloc
        .listen((connectivity) => add(_ConnectivityUpdated(connectivity)));
  }

  @override
  Future<void> close() {
    _patternSubscription.cancel();
    _connectivitySubscription.cancel();
    return super.close();
  }

  @override
  Stream<WifiAccessState> mapEventToState(_WifiAccessEvent event) async* {
    if (event is _PatternUpdated) {
      yield state.copyWith(allowedPattern: event.allowedPattern);
    } else if (event is _ConnectivityUpdated) {
      yield state.copyWith(connectivity: event.connectivity);
    }
  }
}
