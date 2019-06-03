import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:router_remote2/app_routes.dart';
import 'package:router_remote2/debug.dart';
import 'package:router_remote2/required_settings.dart';
import 'package:router_remote2/settings_screen.dart';
import 'package:router_remote2/vpn_control_page.dart';

void main() {
  BlocSupervisor.delegate = DebugBlocDelegate();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Router Remote',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        AppRoutes.home: (context) => AppScaffold(body: VpnControlPage()),
        AppRoutes.settings: (context) => SettingsScreen(),
      },
      initialRoute: AppRoutes.home,
    );
  }
}

class AppScaffold extends StatelessWidget {
  final Widget body;

  AppScaffold({@required this.body}) : assert(body != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Router Remote'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          )
        ],
      ),
      body: RequiredSettings(child: body),
    );
  }
}
