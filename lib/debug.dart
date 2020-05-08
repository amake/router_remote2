import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

const bool isDebug = !kReleaseMode;

class DebugBlocDelegate extends BlocDelegate {
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
  void onError(Bloc bloc, Object error, StackTrace stackTrace) {
    if (isDebug) {
      print('${bloc.runtimeType}: $error');
      print(stackTrace);
    }
    super.onError(bloc, error, stackTrace);
  }
}
