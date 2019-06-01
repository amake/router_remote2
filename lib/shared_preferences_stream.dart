import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStream {
  static SharedPreferencesStream _instance;

  SharedPreferencesStream._();

  factory SharedPreferencesStream() {
    if (_instance == null) {
      _instance = SharedPreferencesStream._();
    }
    return _instance;
  }

  final _controllers = <String, Set<StreamController>>{};

  Future<T> _get<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key) as T;
  }

  Future<bool> _put(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      return prefs.setString(key, value);
    } else if (value is bool) {
      return prefs.setBool(key, value);
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

    void onListen() async {
      final value = await _get<T>(key);
      controller.add(value);
    }

    void onCancel() {
      _controllers[key].remove(controller);
      controller.close();
    }

    controller = StreamController(onListen: onListen, onCancel: onCancel);

    return controller;
  }

  void add(String key, value) async {
    if (_controllers.containsKey(key)) {
      for (final controller in _controllers[key]) {
        controller.add(value);
      }
    }
    _put(key, value);
  }
}
