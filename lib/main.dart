import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/app_routes.dart';
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/connectivity_bloc.dart';
import 'package:router_remote2/debug.dart';
import 'package:router_remote2/required_settings.dart';
import 'package:router_remote2/settings_screen.dart';
import 'package:router_remote2/shared_preferences_bloc.dart';
import 'package:router_remote2/vpn_control_bloc.dart';
import 'package:router_remote2/vpn_control_page.dart';
import 'package:router_remote2/wifi_access_bloc.dart';
import 'package:router_remote2/wifi_connection.dart';

void main() {
  BlocSupervisor.delegate = DebugBlocDelegate();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Router Remote',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.deepOrangeAccent,
        brightness: Brightness.dark,
      ),
      routes: {
        AppRoutes.home: (context) =>
            const AppScaffold(body: WifiConnection(child: VpnControlPage())),
        AppRoutes.settings: (context) => const SettingsScreen(),
      },
      initialRoute: AppRoutes.home,
    );
  }
}

class AppScaffold extends StatelessWidget {
  final Widget body;

  const AppScaffold({@required this.body, Key key})
      : assert(body != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SharedPreferencesBloc>(
          create: (context) => SharedPreferencesBloc()
            ..listenFor<String>(AppSettings.host, required: true)
            ..listenFor<String>(AppSettings.username, required: true)
            ..listenFor<String>(AppSettings.password, required: true)
            ..listenFor<bool>(AppSettings.dryRun),
        ),
        BlocProvider<ConnectivityBloc>(
          create: (context) => ConnectivityBloc(),
        ),
        BlocProvider<WifiAccessBloc>(
          create: (context) =>
              WifiAccessBloc(BlocProvider.of<ConnectivityBloc>(context)),
        ),
        BlocProvider<VpnControlBloc>(
          create: (context) => VpnControlBloc(
            BlocProvider.of<WifiAccessBloc>(context),
            BlocProvider.of<SharedPreferencesBloc>(context),
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Router Remote'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            )
          ],
        ),
        body: SafeArea(
          child: RequiredSettings(child: body),
        ),
      ),
    );
  }
}
