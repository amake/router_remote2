import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/common_widgets.dart';
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

  Future<void> _refresh() async {
    if (!_vpnControlBloc.canRefresh) {
      return null;
    }
    final completer = Completer<void>();
    var queried = false;
    StreamSubscription subscription;

    void onData(VpnControlState state) {
      switch (state) {
        case VpnControlState.querying:
          queried = true;
          break;
        default:
          if (queried) {
            completer.complete();
            subscription.cancel();
          }
      }
    }

    subscription = _vpnControlBloc.state.listen(onData);
    _vpnControlBloc.dispatch(VpnRefresh());
    return completer.future;
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
                    onRefresh: _refresh,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              _statusIcon(vpnState),
                              const SizedBox(width: 8),
                              MainMessageText(_message(vpnState)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          RaisedButton(
                            child: Text(_onOffLabel(vpnState).toUpperCase()),
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

  Widget _statusIcon(VpnControlState currentState) {
    switch (currentState) {
      case VpnControlState.on:
        return const Icon(Icons.lock_outline);
      case VpnControlState.off:
        return const Icon(Icons.lock_open);
      case VpnControlState.querying:
        return const Icon(Icons.refresh);
      case VpnControlState.disallowed:
        return const Icon(Icons.not_interested);
      case VpnControlState.error:
        return const Icon(Icons.error);
      default:
        return Container();
    }
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

  String _onOffLabel(VpnControlState currentState) {
    switch (currentState) {
      case VpnControlState.on:
        return 'Turn VPN Off';
      case VpnControlState.off:
        return 'Turn VPN ON';
      case VpnControlState.querying:
        return 'Please Wait';
      case VpnControlState.disallowed:
        return 'Disallowed';
      case VpnControlState.error:
        return 'Error';
      default:
        return '?';
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
