import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MainMessageText extends StatelessWidget {
  final String text;

  const MainMessageText(this.text, {Key key})
      : assert(text != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headline6,
    );
  }
}
