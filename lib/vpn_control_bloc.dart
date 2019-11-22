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

abstract class VpnControlEvent extends Equatable {
  const VpnControlEvent();
}

class VpnTurnOff extends VpnControlEvent {
  const VpnTurnOff();
  @override
  List<Object> get props => const [];
}

class VpnTurnOn extends VpnControlEvent {
  const VpnTurnOn();
  @override
  List<Object> get props => const [];
}

class VpnRefresh extends VpnControlEvent {
  const VpnRefresh();
  @override
  List<Object> get props => const [];
}

class WifiChanged extends VpnControlEvent {
  final WifiAccessStatus wifiStatus;

  const WifiChanged(this.wifiStatus);

  @override
  List<Object> get props => [wifiStatus];
}

enum VpnControlState { on, off, querying, error, disallowed, unknown }

class VpnControlBloc extends Bloc<VpnControlEvent, VpnControlState> {
  final WifiAccessBloc wifiBloc;
  final SharedPreferencesBloc sharedPreferencesBloc;
  StreamSubscription<WifiAccessState> _wifiSubscription;
  StreamSubscription<SharedPreferencesState> _prefsSubscription;

  VpnControlBloc(this.wifiBloc, this.sharedPreferencesBloc) {
    _wifiSubscription = wifiBloc
        .listen((currentState) => add(WifiChanged(currentState.status)));
    _prefsSubscription = sharedPreferencesBloc
        .transform(Debounce())
        .listen((currentState) => add(const VpnRefresh()));
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

  @override
  VpnControlState get initialState => VpnControlState.unknown;

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
  Stream<VpnControlState> mapEventToState(VpnControlEvent event) async* {
    if (event is WifiChanged) {
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
    } else if (event is VpnTurnOn || event is VpnTurnOff) {
      yield VpnControlState.querying;
      final enable = event is VpnTurnOn;
      final toggledResult = await _toggle(enable);
      if (toggledResult == VpnControlState.unknown) {
        final expected = enable ? VpnControlState.on : VpnControlState.off;
        final delay = enable
            ? const Duration(milliseconds: 1500)
            : const Duration(milliseconds: 500);
        await for (final state in _pollForState(expected, delay)) {
          yield state;
        }
      } else {
        yield toggledResult;
      }
    } else if (event is VpnRefresh) {
      if (canRefresh) {
        yield VpnControlState.querying;
        yield await _queryHost();
      }
    }
  }
}
