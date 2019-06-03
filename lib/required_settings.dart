import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/app_routes.dart';
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/shared_preferences_bloc.dart';

class RequiredSettings extends StatefulWidget {
  final Widget child;

  RequiredSettings({@required this.child}) : assert(child != null);

  @override
  _RequiredSettingsState createState() => _RequiredSettingsState();
}

class _RequiredSettingsState extends State<RequiredSettings> {
  SharedPreferencesBloc _sharedPreferencesBloc;

  @override
  void initState() {
    _sharedPreferencesBloc = SharedPreferencesBloc();
    _sharedPreferencesBloc
      ..require<String>(AppSettings.host)
      ..require<String>(AppSettings.username)
      ..require<String>(AppSettings.password)
      ..add<bool>(AppSettings.dryRun);
    super.initState();
  }

  @override
  void dispose() {
    _sharedPreferencesBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: _sharedPreferencesBloc,
      builder: (context, SharedPreferencesState currentState) {
        if (!currentState.isComplete) {
          return SettingsRequiredPage();
        } else {
          return BlocProvider(
            bloc: _sharedPreferencesBloc,
            child: widget.child,
          );
        }
      },
    );
  }
}

class SettingsRequiredPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Some required setings have not been input yet'),
            SizedBox(height: 16),
            RaisedButton(
              child: Text('Open Settings'),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            )
          ],
        ),
      ),
    );
  }
}
