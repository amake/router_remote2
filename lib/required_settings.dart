import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/app_routes.dart';
import 'package:router_remote2/common_widgets.dart';
import 'package:router_remote2/shared_preferences_bloc.dart';

class RequiredSettings extends StatelessWidget {
  final Widget child;

  const RequiredSettings({@required this.child, Key key})
      : assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedPreferencesBloc, SharedPreferencesState>(
      builder: (context, currentState) {
        if (!currentState.isComplete) {
          return const SettingsRequiredPage();
        } else {
          return child;
        }
      },
    );
  }
}

class SettingsRequiredPage extends StatelessWidget {
  const SettingsRequiredPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const MainMessageText(
                'Some required setings have not been input yet'),
            const SizedBox(height: 16),
            RaisedButton(
              child: Text('Open Settings'.toUpperCase()),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            )
          ],
        ),
      ),
    );
  }
}
