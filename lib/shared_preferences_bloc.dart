import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:router_remote2/shared_preferences_stream.dart';

abstract class SharedPreferencesEvent extends Equatable {
  SharedPreferencesEvent([List props = const []]) : super(props);
}

class RequiredKeyAdded extends SharedPreferencesEvent {
  final String key;

  RequiredKeyAdded(this.key) : super([key]);
}

class SharedPreferenceUpdated extends SharedPreferencesEvent {
  final String key;
  final Object value;

  SharedPreferenceUpdated(this.key, this.value) : super([key, value]);
}

class SharedPreferencesState<T> extends Equatable {
  final Map<String, Object> data;
  final Set<String> requiredKeys;

  SharedPreferencesState(this.data, this.requiredKeys)
      : super([data, requiredKeys]);

  T get<T>(String key) => data[key] as T;

  T getOrDefault<T>(String key, T defaultValue) =>
      data.containsKey(key) ? data[key] : defaultValue;

  SharedPreferencesState put(String key, Object value) {
    final newData = Map.of(data);
    if (value == null) {
      newData.remove(key);
    } else {
      newData[key] = value;
    }
    return SharedPreferencesState(newData, requiredKeys);
  }

  SharedPreferencesState requireKey(String key) {
    final newKeys = Set.of(requiredKeys)..add(key);
    return SharedPreferencesState(data, newKeys);
  }

  bool get isComplete =>
      data.isNotEmpty && requiredKeys.every((key) => data.containsKey(key));
}

class SharedPreferencesBloc
    extends Bloc<SharedPreferencesEvent, SharedPreferencesState> {
  final _streamSubscriptions = <String, StreamSubscription>{};

  void require<T>(String key) {
    _subscribe<T>(key);
    dispatch(RequiredKeyAdded(key));
  }

  void add<T>(String key) {
    _subscribe<T>(key);
  }

  void _subscribe<T>(String key) {
    _streamSubscriptions[key] = SharedPreferencesStream()
        .streamForKey<T>(key)
        .listen((value) => dispatch(SharedPreferenceUpdated(key, value)));
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  SharedPreferencesState get initialState => SharedPreferencesState({}, Set());

  @override
  Stream<SharedPreferencesState> mapEventToState(
      SharedPreferencesEvent event) async* {
    if (event is SharedPreferenceUpdated) {
      yield currentState.put(event.key, event.value);
    } else if (event is RequiredKeyAdded) {
      yield currentState.requireKey(event.key);
    }
  }
}
