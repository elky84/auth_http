import 'package:http/http.dart' as http;

class AuthHttp {
  static final Map<String, String> _commonHeaders = {
    "Access-Control-Allow-Origin": "*"
  };

  static final Map<String, String> _headersJson = {
    "Content-Type": "application/json; charset=UTF-8"
  };

  static final Map<String, String> _headersGraphql = {
    "Content-Type": "application/graphql; charset=UTF-8"
  };

  static Future<http.Response> Function(
          String url, Map<String, String> headers, Object body)?
      _refreshTokenFunction;

  static String _baseUrl = "http://localhost:8080";

  static String _requestAuthHeader = "X-AUTH-TOKEN";

  static String _responseAuthHeader = "X-AUTH-TOKEN".toLowerCase();

  static String get baseUrl => _baseUrl;

  static Future<http.Response> Function(
          String url, Map<String, String> headers, Object body)?
      get refreshTokenFunction => _refreshTokenFunction;

  static String get requestAuthHeader => _requestAuthHeader;

  static String get responseAuthHeader => _responseAuthHeader;

  static void setup(
      String baseUrl,
      Future<http.Response> Function(
              String url, Map<String, String> headers, Object body)
          refreshTokenFunction,
      String requestAuthHeader,
      String responseAuthHeader) {
    _baseUrl = baseUrl;
    _refreshTokenFunction = refreshTokenFunction;
    _requestAuthHeader = requestAuthHeader;
    _responseAuthHeader = responseAuthHeader;
  }

  Future<http.Response> postJson(String url, Object body) async {
    return await _httpPost(url, {..._commonHeaders, ..._headersJson}, body);
  }

  Future<http.Response> graphql(Object body) async {
    return await _httpPost(
        "/graphql", {..._commonHeaders, ..._headersGraphql}, body);
  }

  Future<http.Response> get(String url) async {
    return await _httpGet(url, {..._commonHeaders, ..._headersJson}, {});
  }

  static Future<http.Response> _httpGet(
      String url, Map<String, String> headers, Object body) async {
    var response = await http.get(Uri.parse("$_baseUrl$url"), headers: headers);

    var postResponse = await _postCall(response, url, headers, body);
    if (postResponse.statusCode == 401) {
      return await _postCall(
          await http.get(Uri.parse("$_baseUrl$url"), headers: headers),
          url,
          headers,
          body);
    }
    return postResponse;
  }

  static Future<http.Response> _httpPost(
      String url, Map<String, String> headers, Object body) async {
    var response = await http.post(Uri.parse("$_baseUrl$url"),
        headers: headers, body: body);

    var postResponse = await _postCall(response, url, headers, body);
    if (postResponse.statusCode == 401) {
      return await _postCall(
          await http.post(Uri.parse("$_baseUrl$url"),
              headers: headers, body: body),
          url,
          headers,
          body);
    }
    return postResponse;
  }

  static Future<http.Response> _postCall(http.Response response, String url,
      Map<String, String> headers, Object body) async {
    if (response.statusCode == 200) {
      _commonHeaders[_requestAuthHeader] =
          response.headers[_responseAuthHeader] as String;
      return response;
    } else if (response.statusCode == 401) {
      if (_refreshTokenFunction == null) return response;
      var authResponse = await _refreshTokenFunction!.call(url, headers, body);

      if (authResponse.headers[_responseAuthHeader] != null) {
        _commonHeaders[_requestAuthHeader] =
            authResponse.headers[_responseAuthHeader] as String;
      }
      return response;
    } else {
      return response;
    }
  }

  String queryString(Map<String, dynamic> map) {
    map.removeWhere((key, value) => value == null || value == '');
    String queryString = Uri(
        queryParameters:
            map.map((key, value) => MapEntry(key, value?.toString()))).query;

    if (queryString.isNotEmpty) {
      queryString = '?$queryString';
    }

    return queryString;
  }
}
