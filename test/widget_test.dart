// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:auth_http/auth_http.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<http.Response> refreshToken(
    String url, Map<String, String> headers, Object body) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return await http.post(Uri.parse("http://localhost:8080/auth/refreshToken"),
      headers: {
        "Access-Control-Allow-Origin": "*",
        'Content-Type': "application/json; charset=UTF-8"
      },
      body: json.encode({"refreshToken": prefs.getString('refreshToken')}));
}

void main() {
  testWidgets('AuthHttp Test', (WidgetTester tester) async {
    const tokenName = "X-AUTH-TOKEN";
    const baseUrl = "http://localhost:8080";

    AuthHttp.setup(baseUrl, refreshToken, tokenName, tokenName.toLowerCase());

    expect(baseUrl, AuthHttp.baseUrl);
    expect(refreshToken, AuthHttp.refreshTokenFunction);
    expect(tokenName, AuthHttp.requestAuthHeader);
    expect(tokenName.toLowerCase(), AuthHttp.responseAuthHeader);
  });
}
