import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/ddwrt.dart';
import 'package:router_remote2/shared_preferences_bloc.dart';
import 'package:router_remote2/wifi_access_bloc.dart';

abstract class VpnControlEvent extends Equatable {
  VpnControlEvent([List props = const []]) : super([props]);
}

class VpnTurnOff extends VpnControlEvent {}

class VpnTurnOn extends VpnControlEvent {}

class VpnRefresh extends VpnControlEvent {}

class WifiChanged extends VpnControlEvent {
  final WifiAccessStatus wifiStatus;

  WifiChanged(this.wifiStatus) : super([wifiStatus]);
}

enum VpnControlState { on, off, querying, error, disallowed, unknown }

class VpnControlBloc extends Bloc<VpnControlEvent, VpnControlState> {
  final WifiAccessBloc wifiBloc;
  final SharedPreferencesBloc sharedPreferencesBloc;
  StreamSubscription<WifiAccessState> _subscription;

  VpnControlBloc(this.wifiBloc, this.sharedPreferencesBloc) {
    _subscription = wifiBloc.state
        .listen((currentState) => dispatch(WifiChanged(currentState.status)));
  }

  FutureOr<T> _withConnectionSettings<T>(
    FutureOr<T> Function(String host, String username, String password) func,
  ) async {
    final prefsState = sharedPreferencesBloc.currentState;
    final hst = prefsState.get<String>(AppSettings.host);
    final user = prefsState.get<String>(AppSettings.username);
    final pass = prefsState.get<String>(AppSettings.password);
    return func(hst, user, pass);
  }

  Future<VpnControlState> _queryHost() async {
    final response = await _withConnectionSettings(DdWrt().statusOpenVpn);
    if (response?.statusCode != 200) {
      return VpnControlState.error;
    }
    if (response.body.contains(RegExp(r'CONNECTED\s+SUCCESS'))) {
      return VpnControlState.on;
    } else {
      return VpnControlState.off;
    }
  }

  Future<VpnControlState> _toggle(bool enabled) async {
    final dryRun = sharedPreferencesBloc.currentState
        .getOrDefault<bool>(AppSettings.dryRun, false);
    if (dryRun) {
      return VpnControlState.unknown;
    }
    final response = await _withConnectionSettings(
        (host, user, pass) => DdWrt().toggleVpn(host, user, pass, enabled));
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
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  VpnControlState get initialState => VpnControlState.unknown;

  bool get canRefresh {
    switch (currentState) {
      case VpnControlState.on:
      case VpnControlState.off:
      case VpnControlState.unknown:
      case VpnControlState.error:
        return true;
      case VpnControlState.disallowed:
      case VpnControlState.querying:
        return false;
    }
    throw Exception('Unknown state: $currentState');
  }

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
