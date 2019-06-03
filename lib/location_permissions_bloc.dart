import 'package:bloc/bloc.dart';
import 'package:location_permissions/location_permissions.dart';

enum LocationPermissionsEvent { init, query, goToSettings, checkPending }

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
        final status = await LocationPermissions().checkPermissionStatus();
        final nextState = _nextState(status);
        // Result is `denied` on first run on Android, so for init return `unknown`
        if (nextState == LocationPermissionsState.granted) {
          yield nextState;
          onGranted();
        } else {
          yield LocationPermissionsState.unknown;
        }
        break;
      case LocationPermissionsEvent.query:
        yield LocationPermissionsState.querying;
        final status = await LocationPermissions().requestPermissions();
        final nextState = _nextState(status);
        yield nextState;
        if (nextState == LocationPermissionsState.granted) {
          onGranted();
        }
        break;
      case LocationPermissionsEvent.checkPending:
        if (currentState == LocationPermissionsState.pending) {
          final status = await LocationPermissions().checkPermissionStatus();
          final nextState = _nextState(status);
          yield nextState;
          if (nextState == LocationPermissionsState.granted) {
            onGranted();
          }
        }
        break;
      case LocationPermissionsEvent.goToSettings:
        yield LocationPermissionsState.pending;
        LocationPermissions().openAppSettings();
        break;
    }
  }

  LocationPermissionsState _nextState(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted: // fallthrough
      case PermissionStatus.restricted:
        return LocationPermissionsState.granted;
      case PermissionStatus.denied:
        return LocationPermissionsState.denied;
      case PermissionStatus.unknown:
        return LocationPermissionsState.unknown;
    }
    throw Exception('Unknown status: $status');
  }
}
