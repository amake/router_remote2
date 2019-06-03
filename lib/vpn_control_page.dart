import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/connectivity_bloc.dart';
import 'package:router_remote2/location_permissions_page.dart';
import 'package:router_remote2/shared_preferences_bloc.dart';
import 'package:router_remote2/vpn_control_bloc.dart';
import 'package:router_remote2/wifi_access_bloc.dart';

class VpnControlPage extends StatefulWidget {
  @override
  _VpnControlPageState createState() => _VpnControlPageState();
}

class _VpnControlPageState extends State<VpnControlPage>
    with WidgetsBindingObserver {
  ConnectivityBloc _connectivityBloc;
  WifiAccessBloc _wifiAccessBloc;
  VpnControlBloc _vpnControlBloc;

  @override
  void initState() {
    _connectivityBloc = ConnectivityBloc();
    _wifiAccessBloc = WifiAccessBloc(_connectivityBloc);
    _vpnControlBloc = VpnControlBloc(
        _wifiAccessBloc, BlocProvider.of<SharedPreferencesBloc>(context));
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _connectivityBloc.dispose();
    _wifiAccessBloc.dispose();
    _vpnControlBloc.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _vpnControlBloc.dispatch(VpnRefresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: _wifiAccessBloc,
      builder: (context, WifiAccessState currentState) {
        switch (currentState.status) {
          case WifiAccessStatus.insufficientPermissions:
            return LocationPermissionsPage(
                onGranted: () => _connectivityBloc
                    .dispatch(ConnectivityPermissionsChanged()));
          default:
            return BlocBuilder(
              bloc: _vpnControlBloc,
              builder: (context, VpnControlState vpnState) {
                return Center(
                  child: SingleChildRefreshIndicator(
                    onRefresh: () async =>
                        _vpnControlBloc.dispatch(VpnRefresh()),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            _message(vpnState),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          RaisedButton(
                            child: _onOffLabel(vpnState),
                            onPressed: _onOffAction(vpnState),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
        }
      },
    );
  }

  String _message(VpnControlState currentState) {
    switch (currentState) {
      case VpnControlState.on:
        return 'VPN is on';
      case VpnControlState.off:
        return 'VPN is off';
      case VpnControlState.querying:
        return 'Checking...';
      case VpnControlState.disallowed:
        return 'Wi-Fi network "${_wifiAccessBloc.currentState.connectivity.wifiName}" is not allowed';
      case VpnControlState.error:
        return 'An error has occurred';
      default:
        return '?';
    }
  }

  Widget _onOffLabel(VpnControlState currentState) {
    switch (currentState) {
      case VpnControlState.on:
        return const Text('VPN OFF');
      case VpnControlState.off:
        return const Text('VPN ON');
      case VpnControlState.querying:
        return const Text('Please Wait');
      case VpnControlState.disallowed:
        return const Text('Disallowed');
      case VpnControlState.error:
        return const Text('Error');
      default:
        return const Text('?');
    }
  }

  Function _onOffAction(VpnControlState currentState) {
    switch (currentState) {
      case VpnControlState.on:
        return () => _vpnControlBloc.dispatch(VpnTurnOff());
      case VpnControlState.off:
        return () => _vpnControlBloc.dispatch(VpnTurnOn());
      default:
        return null;
    }
  }
}

class SingleChildRefreshIndicator extends StatelessWidget {
  final Widget child;
  final RefreshCallback onRefresh;

  SingleChildRefreshIndicator({@required this.child, @required this.onRefresh})
      : assert(child != null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
