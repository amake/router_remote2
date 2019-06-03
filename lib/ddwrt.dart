import 'dart:convert';

import 'package:http/http.dart' as http;

class DdWrt {
  static DdWrt _instance;

  DdWrt._();

  factory DdWrt() {
    if (_instance == null) {
      _instance = DdWrt._();
    }
    return _instance;
  }

  Future<http.Response> statusOpenVpn(
    String host,
    String user,
    String pass,
  ) async {
    final uri = Uri.http(host, '/Status_OpenVPN.asp');
    return http.get(uri, headers: _basicAuth(user, pass));
  }

  Future<http.Response> toggleVpn(
    String host,
    String user,
    String pass,
    bool enabled,
  ) {
    final value = enabled ? 1 : 0;
    return applyUser(host, user, pass, {
      'openvpncl_enable': value.toString(),
      'submit_button': 'PPTP',
      'action': 'ApplyTake'
    });
  }

  Future<http.Response> applyUser(
    String host,
    String user,
    String pass,
    Map<String, String> data,
  ) {
    final uri = Uri.http(host, '/applyuser.cgi');
    return http.post(uri, headers: _basicAuth(user, pass), body: data);
  }

  Map<String, String> _basicAuth(String user, String pass) {
    final authUtf8 = utf8.encode('$user:$pass');
    final authBase64 = base64Url.encode(authUtf8);
    return {'Authorization': 'Basic $authBase64'};
  }
}
