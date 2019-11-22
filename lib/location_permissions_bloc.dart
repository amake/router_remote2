import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';

enum LocationPermissionsEvent { init, query, checkPending }

enum LocationPermissionsState { unknown, granted, denied, querying, pending }

class LocationPermissionsBloc
    extends Bloc<LocationPermissionsEvent, LocationPermissionsState> {
  final Function onGranted;

  LocationPermissionsBloc([Function onGranted])
      : onGranted = onGranted ?? (() {}) {
    dispatch(LocationPermissionsEvent.init);
  }

  @override
  LocationPermissionsState get initialState => LocationPermissionsState.unknown;

  @override
  Stream<LocationPermissionsState> mapEventToState(
    LocationPermissionsEvent event,
  ) async* {
    switch (event) {
      case LocationPermissionsEvent.init:
        yield LocationPermissionsState.querying;
        final status = await Connectivity().getLocationServiceAuthorization();
        final nextState = _nextState(status);
        // Result is `denied` on first run on Android
        // so for init return `unknown`
        if (nextState == LocationPermissionsState.granted) {
          yield nextState;
          onGranted();
        } else {
          yield LocationPermissionsState.unknown;
        }
        break;
      case LocationPermissionsEvent.query:
        yield LocationPermissionsState.querying;
        final status =
            await Connectivity().requestLocationServiceAuthorization();
        final nextState = _nextState(status);
        yield nextState;
        if (nextState == LocationPermissionsState.granted) {
          onGranted();
        }
        break;
      case LocationPermissionsEvent.checkPending:
        if (currentState == LocationPermissionsState.pending) {
          final status = await Connectivity().getLocationServiceAuthorization();
          final nextState = _nextState(status);
          yield nextState;
          if (nextState == LocationPermissionsState.granted) {
            onGranted();
          }
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
        Connectivity().getWifiName().then((v) => print('Wi-Fi: $v'));
        return LocationPermissionsState.granted;
    }
    throw Exception('Unknown status: $status');
  }
}
