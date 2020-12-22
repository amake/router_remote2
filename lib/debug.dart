import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

const bool isDebug = !kReleaseMode;

class DebugBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object event) {
    if (isDebug) {
      print('${bloc.runtimeType}: $event');
    }
    super.onEvent(bloc, event);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    if (isDebug) {
      print('${bloc.runtimeType}: $transition');
    }
    super.onTransition(bloc, transition);
  }

  @override
  void onError(Cubit cubit, Object error, StackTrace stackTrace) {
    if (isDebug) {
      print('${cubit.runtimeType}: $error');
      print(stackTrace);
    }
    super.onError(cubit, error, stackTrace);
  }
}

Future<T> time<T>(String tag, FutureOr<T> Function() func) async {
  final start = DateTime.now();
  final ret = await func();
  final end = DateTime.now();
  debugPrint('$tag: ${end.difference(start).inMilliseconds} ms');
  return ret;
}
