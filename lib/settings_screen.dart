import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/shared_preferences_stream.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: const BackButton(),
      ),
      body: ListView(
        children: const <Widget>[
          SectionHeader('Server'),
          StringPrefItem(
            AppSettings.username,
            title: Text('Username'),
          ),
          StringPrefItem(
            AppSettings.password,
            title: Text('Password'),
            obscureText: true,
          ),
          StringPrefItem(
            AppSettings.host,
            title: Text('Host'),
          ),
          SectionHeader('Advanced'),
          StringPrefItem(
            AppSettings.allowedWifiPattern,
            title: Text('Allowed network SSIDs (regex)'),
          ),
          SectionHeader('Debug'),
          BoolPrefItem(
            AppSettings.dryRun,
            title: Text('Dry Run'),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String text;

  const SectionHeader(this.text, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .headline6
            .copyWith(color: Theme.of(context).accentColor),
      ),
    );
  }
}

class StringPrefItem extends StatefulWidget {
  final Widget title;
  final String prefsKey;
  final bool obscureText;
  final bool allowEmpty;

  const StringPrefItem(
    this.prefsKey, {
    this.title,
    this.obscureText = false,
    this.allowEmpty = false,
    Key key,
  }) : super(key: key);

  @override
  _StringPrefItemState createState() => _StringPrefItemState();
}

class _StringPrefItemState extends State<StringPrefItem> {
  TextEditingController _controller;
  StreamSubscription<String> _subscription;

  @override
  void initState() {
    _controller = TextEditingController();
    _subscription = SharedPreferencesStream()
        .streamForKey<String>(widget.prefsKey)
        .listen(_updateText);
    super.initState();
  }

  void _updateText(String newValue) {
    if (_controller.text != newValue) {
      _controller.text = newValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: widget.title,
      subtitle: TextField(
        controller: _controller,
        onChanged: (newValue) => SharedPreferencesStream().add(widget.prefsKey,
            newValue.isEmpty && !widget.allowEmpty ? null : newValue),
        obscureText: widget.obscureText,
      ),
    );
  }
}

class BoolPrefItem extends StatelessWidget {
  final Widget title;
  final String prefsKey;
  final bool defaultValue;

  const BoolPrefItem(
    this.prefsKey, {
    this.title,
    this.defaultValue = false,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: SharedPreferencesStream().streamForKey<bool>(prefsKey),
      initialData: defaultValue,
      builder: (context, snapshot) {
        return CheckboxListTile(
          title: title,
          value: snapshot.data ?? false,
          onChanged: (newValue) =>
              SharedPreferencesStream().add(prefsKey, newValue),
        );
      },
    );
  }
}
