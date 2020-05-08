import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MainMessageText extends StatelessWidget {
  final String text;

  const MainMessageText(this.text) : assert(text != null);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headline6,
    );
  }
}
