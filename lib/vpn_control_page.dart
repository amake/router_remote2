import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/common_widgets.dart';
import 'package:router_remote2/vpn_control_bloc.dart';
import 'package:router_remote2/wifi_access_bloc.dart';

class VpnControlPage extends StatefulWidget {
  @override
  _VpnControlPageState createState() => _VpnControlPageState();
}

class _VpnControlPageState extends State<VpnControlPage>
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
      BlocProvider.of<VpnControlBloc>(context).dispatch(VpnRefresh());
    }
  }

  Future<void> _refresh() async {
    final bloc = BlocProvider.of<VpnControlBloc>(context);
    if (!bloc.canRefresh) {
      return Future.value(null);
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

    subscription = bloc.state.listen(onData);
    bloc.dispatch(VpnRefresh());
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VpnControlBloc, VpnControlState>(
      builder: (context, vpnState) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _statusIcon(vpnState),
                      const SizedBox(width: 8),
                      Flexible(child: MainMessageText(_message(vpnState))),
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
        final networkName = BlocProvider.of<WifiAccessBloc>(context)
            .currentState
            .connectivity
            .wifiName;
        return 'Wi-Fi network “$networkName” is not allowed';
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

  VoidCallback _onOffAction(VpnControlState currentState) {
    final bloc = BlocProvider.of<VpnControlBloc>(context);
    switch (currentState) {
      case VpnControlState.on:
        return () => bloc.dispatch(VpnTurnOff());
      case VpnControlState.off:
        return () => bloc.dispatch(VpnTurnOn());
      default:
        return null;
    }
  }
}

class SingleChildRefreshIndicator extends StatelessWidget {
  final Widget child;
  final RefreshCallback onRefresh;

  const SingleChildRefreshIndicator(
      {@required this.child, @required this.onRefresh})
      : assert(child != null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
