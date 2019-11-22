import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/common_widgets.dart';
import 'package:router_remote2/location_permissions_bloc.dart';

class LocationPermissionsPage extends StatefulWidget {
  final Function onGranted;

  const LocationPermissionsPage({this.onGranted});

  @override
  _LocationPermissionsPageState createState() =>
      _LocationPermissionsPageState();
}

class _LocationPermissionsPageState extends State<LocationPermissionsPage>
    with
        // ignore: prefer_mixin
        WidgetsBindingObserver {
  LocationPermissionsBloc _bloc;

  @override
  void initState() {
    _bloc = LocationPermissionsBloc(widget.onGranted);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _bloc.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bloc.dispatch(LocationPermissionsEvent.checkPending);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationPermissionsBloc, LocationPermissionsState>(
      bloc: _bloc,
      builder: (context, state) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const MainMessageText(
                    'This app requires location permissions in order to restrict the Wi-Fi SSID'),
                const SizedBox(height: 16),
                RaisedButton(
                  child: Text(_buttonTitle(state).toUpperCase()),
                  onPressed: _buttonAction(state),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  String _buttonTitle(LocationPermissionsState currentState) {
    switch (currentState) {
      case LocationPermissionsState.granted:
        return 'Already Granted';
      case LocationPermissionsState.querying: // fallthrough
      case LocationPermissionsState.unknown:
        return 'Grant Permission';
      case LocationPermissionsState.denied: // fallthrough
      case LocationPermissionsState.pending:
        return 'Go to Settings app';
    }
    throw Exception('Unknown state: $currentState');
  }

  VoidCallback _buttonAction(LocationPermissionsState currentState) {
    switch (currentState) {
      case LocationPermissionsState.granted: // fallthrough
      case LocationPermissionsState.denied:
        return null;
      case LocationPermissionsState.pending: // fallthrough
      case LocationPermissionsState.querying: // fallthrough
      case LocationPermissionsState.unknown:
        return () => _bloc.dispatch(LocationPermissionsEvent.query);
    }
    throw Exception('Unknown state: $currentState');
  }
}
