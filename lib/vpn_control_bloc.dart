import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/ddwrt.dart';
import 'package:router_remote2/shared_preferences_bloc.dart';
import 'package:router_remote2/stream_utils.dart';
import 'package:router_remote2/wifi_access_bloc.dart';

abstract class _VpnControlEvent extends Equatable {
  const _VpnControlEvent();
}

class _VpnToggle extends _VpnControlEvent {
  final bool enabled;

  // ignore: avoid_positional_boolean_parameters
  const _VpnToggle(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class _VpnRefresh extends _VpnControlEvent {
  const _VpnRefresh();

  @override
  List<Object> get props => const [];
}

class _WifiChanged extends _VpnControlEvent {
  final WifiAccessStatus wifiStatus;

  const _WifiChanged(this.wifiStatus);

  @override
  List<Object> get props => [wifiStatus];
}

enum VpnControlState { on, off, querying, error, disallowed, unknown }

class VpnControlBloc extends Bloc<_VpnControlEvent, VpnControlState> {
  final WifiAccessBloc wifiBloc;
  final SharedPreferencesBloc sharedPreferencesBloc;
  StreamSubscription<WifiAccessState> _wifiSubscription;
  StreamSubscription<SharedPreferencesState> _prefsSubscription;

  VpnControlBloc(this.wifiBloc, this.sharedPreferencesBloc)
      : super(VpnControlState.unknown) {
    _wifiSubscription = wifiBloc
        .listen((currentState) => add(_WifiChanged(currentState.status)));
    _prefsSubscription = sharedPreferencesBloc
        .transform(Debounce())
        .listen((currentState) => refresh());
  }

  FutureOr<T> _withConnectionSettings<T>(
    FutureOr<T> Function(String host, String username, String password) func,
  ) async {
    final prefsState = sharedPreferencesBloc.state;
    final hst = prefsState.get<String>(AppSettings.host);
    final user = prefsState.get<String>(AppSettings.username);
    final pass = prefsState.get<String>(AppSettings.password);
    return func(hst, user, pass);
  }

  static final _successPattern = RegExp(r'CONNECTED\s+SUCCESS');

  Future<VpnControlState> _queryHost() async {
    if (!canQuery) {
      return VpnControlState.unknown;
    }
    http.Response response;
    try {
      response = await _withConnectionSettings(DdWrt().statusOpenVpn);
    } on Exception {
      return VpnControlState.error;
    }
    if (response?.statusCode != 200) {
      return VpnControlState.error;
    }
    if (response.body.contains(_successPattern)) {
      return VpnControlState.on;
    } else {
      return VpnControlState.off;
    }
  }

  Future<VpnControlState> _toggle(bool enabled) async {
    if (!canQuery || dryRun) {
      return VpnControlState.unknown;
    }
    http.Response response;
    try {
      response = await _withConnectionSettings(
          (host, user, pass) => DdWrt().toggleVpn(host, user, pass, enabled));
    } on Exception {
      return VpnControlState.error;
    }
    if (response?.statusCode != 200) {
      return VpnControlState.error;
    } else {
      return VpnControlState.unknown;
    }
  }

  Stream<VpnControlState> _pollForState(
    VpnControlState expected,
    Duration delay, [
    int retries = 5,
  ]) async* {
    yield VpnControlState.querying;
    VpnControlState status;
    for (var i = 0; i < retries; i++) {
      sleep(delay);
      status = await _queryHost();
      if (status == expected) {
        break;
      }
    }
    yield status;
  }

  @override
  Future<void> close() {
    _wifiSubscription.cancel();
    _prefsSubscription.cancel();
    return super.close();
  }

  bool get canRefresh {
    switch (state) {
      case VpnControlState.on:
      case VpnControlState.off:
      case VpnControlState.unknown:
      case VpnControlState.error:
        return canQuery;
      case VpnControlState.disallowed:
      case VpnControlState.querying:
        return false;
    }
    throw Exception('Unknown state: $state');
  }

  bool get canQuery {
    switch (wifiBloc.state.status) {
      case WifiAccessStatus.connected:
        return true;
      default:
        return false;
    }
  }

  bool get dryRun => sharedPreferencesBloc.state
      .get<bool>(AppSettings.dryRun, defaultValue: false);

  @override
  Stream<VpnControlState> mapEventToState(_VpnControlEvent event) async* {
    if (event is _WifiChanged) {
      switch (event.wifiStatus) {
        case WifiAccessStatus.unknown: // fallthrough
        case WifiAccessStatus.disconnected: // fallthrough
        case WifiAccessStatus.insufficientPermissions:
          yield VpnControlState.unknown;
          break;
        case WifiAccessStatus.connected:
          yield VpnControlState.querying;
          yield await _queryHost();
          break;
        case WifiAccessStatus.disallowed:
          yield VpnControlState.disallowed;
          break;
      }
    } else if (event is _VpnToggle) {
      yield VpnControlState.querying;
      final toggledResult = await _toggle(event.enabled);
      if (toggledResult == VpnControlState.unknown) {
        final expected =
            event.enabled ? VpnControlState.on : VpnControlState.off;
        final delay = event.enabled
            ? const Duration(milliseconds: 1500)
            : const Duration(milliseconds: 500);
        await for (final state in _pollForState(expected, delay)) {
          yield state;
        }
      } else {
        yield toggledResult;
      }
    } else if (event is _VpnRefresh) {
      if (canRefresh) {
        yield VpnControlState.querying;
        yield await _queryHost();
      }
    }
  }

  // ignore: avoid_positional_boolean_parameters
  void setEnabled(bool enabled) => add(_VpnToggle(enabled));

  void refresh() => add(const _VpnRefresh());
}
