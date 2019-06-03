import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:router_remote2/app_routes.dart';
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/ddwrt.dart';
import 'package:router_remote2/debug.dart';
import 'package:router_remote2/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  BlocSupervisor.delegate = DebugBlocDelegate();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Router Remote 2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        AppRoutes.home: (context) => MyHomePage(title: 'Router Remote 2'),
        AppRoutes.settings: (context) => SettingsScreen(),
      },
      initialRoute: AppRoutes.home,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              child: Text('Go'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final host = prefs.get(AppSettings.host);
                final user = prefs.get(AppSettings.username);
                final pass = prefs.get(AppSettings.password);
                final result = await DdWrt().statusOpenVpn(host, user, pass);
                debugPrint(result.body);
              },
            )
          ],
        ),
      ),
    );
  }
}
