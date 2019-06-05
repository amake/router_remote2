import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStream {
  static SharedPreferencesStream _instance;

  SharedPreferencesStream._();

  factory SharedPreferencesStream() =>
      _instance ??= SharedPreferencesStream._();

  final _controllers = <String, Set<StreamController>>{};

  Future<T> _get<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }

  Future<bool> _put<T>(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (T == String) {
      return prefs.setString(key, value);
    } else if (T == bool) {
      return prefs.setBool(key, value);
    }
    throw Exception('Unsupported value type: $T');
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

  Future<void> add<T>(String key, T value) async {
    if (_controllers.containsKey(key)) {
      for (final controller in _controllers[key]) {
        controller.add(value);
      }
    }
    await _put<T>(key, value);
  }
}
