import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:router_remote2/shared_preferences_stream.dart';

abstract class _SharedPreferencesEvent extends Equatable {
  const _SharedPreferencesEvent();
}

class _RequiredKeyAdded extends _SharedPreferencesEvent {
  final String key;

  const _RequiredKeyAdded(this.key);

  @override
  List<Object> get props => [key];
}

class _SharedPreferenceUpdated extends _SharedPreferencesEvent {
  final String key;
  final Object value;

  const _SharedPreferenceUpdated(this.key, this.value);

  @override
  List<Object> get props => [key, value];
}

class SharedPreferencesState extends Equatable {
  final Map<String, Object> data;
  final Set<String> requiredKeys;

  const SharedPreferencesState(this.data, this.requiredKeys);

  T get<T>(String key, {T defaultValue}) {
    return data.containsKey(key) ? cast<T>(data[key]) : defaultValue;
  }

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
      data.isNotEmpty && requiredKeys.every(data.containsKey);

  @override
  List<Object> get props => [data, requiredKeys];
}

class SharedPreferencesBloc
    extends Bloc<_SharedPreferencesEvent, SharedPreferencesState> {
  final _streamSubscriptions = <String, StreamSubscription>{};

  void listenFor<T>(String key, {bool required = false}) {
    assert(required != null);
    _subscribe<T>(key);
    if (required) {
      add(_RequiredKeyAdded(key));
    }
  }

  void _subscribe<T>(String key) {
    _streamSubscriptions[key] = SharedPreferencesStream()
        .streamForKey<T>(key)
        .listen((value) => add(_SharedPreferenceUpdated(key, value)));
  }

  @override
  Future<void> close() {
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    return super.close();
  }

  @override
  SharedPreferencesState get initialState =>
      const SharedPreferencesState({}, <String>{});

  @override
  Stream<SharedPreferencesState> mapEventToState(
      _SharedPreferencesEvent event) async* {
    if (event is _SharedPreferenceUpdated) {
      yield state.put(event.key, event.value);
    } else if (event is _RequiredKeyAdded) {
      yield state.requireKey(event.key);
    }
  }
}
