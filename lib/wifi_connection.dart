import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/common_widgets.dart';
import 'package:router_remote2/connectivity_bloc.dart';
import 'package:router_remote2/location_permissions_page.dart';
import 'package:router_remote2/wifi_access_bloc.dart';

class WifiConnection extends StatefulWidget {
  final Widget child;

  WifiConnection({@required this.child}) : assert(child != null);

  @override
  _WifiConnectionState createState() => _WifiConnectionState();
}

class _WifiConnectionState extends State<WifiConnection> {
  ConnectivityBloc _connectivityBloc;
  WifiAccessBloc _wifiAccessBloc;

  @override
  void initState() {
    _connectivityBloc = ConnectivityBloc();
    _wifiAccessBloc = WifiAccessBloc(_connectivityBloc);
    super.initState();
  }

  @override
  void dispose() {
    _connectivityBloc.dispose();
    _wifiAccessBloc.dispose();
    super.dispose();
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
          case WifiAccessStatus.disconnected:
            return const NoConnectionPage();
          default:
            return BlocProvider(
              bloc: _connectivityBloc,
              child: BlocProvider(
                bloc: _wifiAccessBloc,
                child: widget.child,
              ),
            );
        }
      },
    );
  }
}

class NoConnectionPage extends StatelessWidget {
  const NoConnectionPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: MainMessageText('Please connect to Wi-Fi'),
      ),
    );
  }
}
