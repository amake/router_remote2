import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/common_widgets.dart';
import 'package:router_remote2/connectivity_bloc.dart';
import 'package:router_remote2/location_permissions_page.dart';
import 'package:router_remote2/wifi_access_bloc.dart';

class WifiConnection extends StatelessWidget {
  final Widget child;

  const WifiConnection({@required this.child}) : assert(child != null);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WifiAccessBloc, WifiAccessState>(
      builder: (context, currentState) {
        switch (currentState.status) {
          case WifiAccessStatus.insufficientPermissions:
            return LocationPermissionsPage(
                onGranted: () =>
                    BlocProvider.of<ConnectivityBloc>(context).refresh());
          case WifiAccessStatus.disconnected:
            return const NoConnectionPage();
          default:
            return child;
        }
      },
    );
  }
}

class NoConnectionPage extends StatelessWidget {
  const NoConnectionPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: MainMessageText('Please connect to Wi-Fi'),
      ),
    );
  }
}
