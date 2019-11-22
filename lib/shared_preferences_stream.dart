import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

T cast<T>(Object value) {
  if (value == null) {
    return null;
  } else if (value is T) {
    return value;
  }
  throw Exception('Value $value is not a $T');
}

class SharedPreferencesStream {
  static SharedPreferencesStream _instance;

  SharedPreferencesStream._();

  factory SharedPreferencesStream() =>
      _instance ??= SharedPreferencesStream._();

  final _controllers = <String, Set<StreamController>>{};

  Future<T> _get<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return cast<T>(prefs.get(key));
  }

  Future<bool> _put(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      return prefs.setString(key, value);
    } else if (value is bool) {
      return prefs.setBool(key, value);
    } else if (value == null) {
      return prefs.remove(key);
    }
    throw Exception('Unsupported value type: ${value.runtimeType}');
  }

  Stream<T> streamForKey<T>(String key) {
    // ignore: close_sinks
    final controller = _newController<T>(key);
    _controllers.putIfAbsent(key, () => Set.identity()).add(controller);
    return controller.stream;
  }

  StreamController<T> _newController<T>(String key) {
    StreamController<T> controller;

    Future<void> onListen() async {
      final value = await _get<T>(key);
      controller.add(value);
    }

    void onCancel() {
      _controllers[key].remove(controller);
      controller.close();
    }

    return controller =
        StreamController(onListen: onListen, onCancel: onCancel);
  }

  Future<void> add(String key, Object value) async {
    if (_controllers.containsKey(key)) {
      for (final controller in _controllers[key]) {
        controller.add(value);
      }
    }
    await _put(key, value);
  }
}
