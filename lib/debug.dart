import 'package:bloc/bloc.dart';

bool _isDebug = false;

bool get isDebug {
  assert((() => _isDebug = true)());
  return _isDebug;
}

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
  void onError(Bloc bloc, Object error, StackTrace stacktrace) {
    if (isDebug) {
      print('${bloc.runtimeType}: $error');
      print(stacktrace);
    }
    super.onError(bloc, error, stacktrace);
  }
}
