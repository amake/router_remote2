import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:router_remote2/app_settings.dart';
import 'package:router_remote2/shared_preferences_stream.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: const BackButton(),
      ),
      body: ListView(
        children: <Widget>[
          const SectionHeader('Server'),
          const StringPrefItem(
            AppSettings.username,
            title: Text('Username'),
          ),
          const StringPrefItem(
            AppSettings.password,
            title: Text('Password'),
            obscureText: true,
          ),
          const StringPrefItem(
            AppSettings.host,
            title: Text('Host'),
          ),
          const SectionHeader('Advanced'),
          const StringPrefItem(
            AppSettings.allowedWifiPattern,
            title: Text('Allowed network SSIDs (regex)'),
          ),
          const SectionHeader('Debug'),
          const BoolPrefItem(
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

  const SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .title
            .copyWith(color: Theme.of(context).accentColor),
      ),
    );
  }
}

class StringPrefItem extends StatefulWidget {
  final Widget title;
  final String prefsKey;
  final bool obscureText;

  const StringPrefItem(this.prefsKey, {this.title, this.obscureText = false});

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
        onChanged: (newValue) =>
            SharedPreferencesStream().add(widget.prefsKey, newValue),
        obscureText: widget.obscureText,
      ),
    );
  }
}

class BoolPrefItem extends StatelessWidget {
  final Widget title;
  final String prefsKey;
  final bool defaultValue;

  const BoolPrefItem(this.prefsKey, {this.title, this.defaultValue = false});

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