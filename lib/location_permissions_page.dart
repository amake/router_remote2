import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/common_widgets.dart';
import 'package:router_remote2/location_permissions_bloc.dart';

class LocationPermissionsPage extends StatelessWidget {
  final Function onGranted;

  const LocationPermissionsPage({this.onGranted, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocationPermissionsBloc>(
      create: (context) => LocationPermissionsBloc(),
      child: BlocListener<LocationPermissionsBloc, LocationPermissionsState>(
        listener: (context, state) {
          if (state == LocationPermissionsState.granted) {
            onGranted();
          }
        },
        child: BlocBuilder<LocationPermissionsBloc, LocationPermissionsState>(
          builder: (context, state) {
            return OnResumed(
              listener: () => BlocProvider.of<LocationPermissionsBloc>(context)
                  .checkPending(),
              child: Center(
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
                        onPressed: _buttonAction(context, state),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
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

  VoidCallback _buttonAction(
    BuildContext context,
    LocationPermissionsState currentState,
  ) {
    switch (currentState) {
      case LocationPermissionsState.granted: // fallthrough
      case LocationPermissionsState.denied:
        return null;
      case LocationPermissionsState.pending: // fallthrough
      case LocationPermissionsState.querying: // fallthrough
      case LocationPermissionsState.unknown:
        return () => BlocProvider.of<LocationPermissionsBloc>(context).query();
    }
    throw Exception('Unknown state: $currentState');
  }
}

class OnResumed extends StatefulWidget {
  final VoidCallback listener;
  final Widget child;

  const OnResumed({@required this.listener, @required this.child, Key key})
      : assert(listener != null),
        assert(child != null),
        super(key: key);

  @override
  _OnResumedState createState() => _OnResumedState();
}

class _OnResumedState extends State<OnResumed>
    with
// ignore: prefer_mixin
        WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.listener();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
