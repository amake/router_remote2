import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:router_remote2/app_routes.dart';
import 'package:router_remote2/common_widgets.dart';
import 'package:router_remote2/shared_preferences_bloc.dart';

class RequiredSettings extends StatelessWidget {
  final Widget child;

  RequiredSettings({@required this.child}) : assert(child != null);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: BlocProvider.of<SharedPreferencesBloc>(context),
      builder: (context, SharedPreferencesState currentState) {
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
  const SettingsRequiredPage();

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
