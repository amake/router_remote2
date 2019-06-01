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
    final authUtf8 = utf8.encode('$user:$pass');
    final authBase64 = base64Url.encode(authUtf8);
    return http.get(uri, headers: {'Authorization': 'Basic $authBase64'});
  }
}
