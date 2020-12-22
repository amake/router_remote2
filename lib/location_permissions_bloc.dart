import 'package:bloc/bloc.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';

enum _LocationPermissionsEvent { init, query, checkPending }

enum LocationPermissionsState { unknown, granted, denied, querying, pending }

class LocationPermissionsBloc
    extends Bloc<_LocationPermissionsEvent, LocationPermissionsState> {
  LocationPermissionsBloc() {
    add(_LocationPermissionsEvent.init);
  }

  @override
  LocationPermissionsState get initialState => LocationPermissionsState.unknown;

  @override
  Stream<LocationPermissionsState> mapEventToState(
    _LocationPermissionsEvent event,
  ) async* {
    switch (event) {
      case _LocationPermissionsEvent.init:
        yield LocationPermissionsState.querying;
        final status = await WifiInfo().getLocationServiceAuthorization();
        final nextState = _nextState(status);
        // Result is `denied` on first run on Android
        // so for init return `unknown`
        if (nextState == LocationPermissionsState.granted) {
          yield nextState;
        } else {
          yield LocationPermissionsState.unknown;
        }
        break;
      case _LocationPermissionsEvent.query:
        yield LocationPermissionsState.querying;
        final status = await WifiInfo().requestLocationServiceAuthorization();
        yield _nextState(status);
        break;
      case _LocationPermissionsEvent.checkPending:
        if (state == LocationPermissionsState.pending) {
          final status = await WifiInfo().getLocationServiceAuthorization();
          yield _nextState(status);
        }
        break;
    }
  }

  LocationPermissionsState _nextState(LocationAuthorizationStatus status) {
    switch (status) {
      case LocationAuthorizationStatus.notDetermined: // fallthrough
      case LocationAuthorizationStatus.unknown:
        return LocationPermissionsState.unknown;
      case LocationAuthorizationStatus.restricted: // fallthrough
      case LocationAuthorizationStatus.denied:
        return LocationPermissionsState.denied;
      case LocationAuthorizationStatus.authorizedAlways: // fallthrough
      case LocationAuthorizationStatus.authorizedWhenInUse:
        WifiInfo().getWifiName().then((v) => print('Wi-Fi: $v'));
        return LocationPermissionsState.granted;
    }
    throw Exception('Unknown status: $status');
  }

  void query() => add(_LocationPermissionsEvent.query);

  void checkPending() => add(_LocationPermissionsEvent.checkPending);
}
