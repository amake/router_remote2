import 'package:flutter/material.dart';

import 'ddwrt.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Router Remote 2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Router Remote 2'),
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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              child: Text('Go'),
              onPressed: () async {
                final result = await DdWrt().statusOpenVpn(_host, _user, _pass);
                debugPrint(result.body);
              },
            )
          ],
        ),
      ),
    );
  }
}

// Temporary
const _host = 'host';
const _user = 'user';
const _pass = 'pass';
