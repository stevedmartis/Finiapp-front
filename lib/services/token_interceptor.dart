import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:finiapp/services/auth_service.dart';

class CustomHttpClient {
  final AuthService authService;
  final http.Client _client;

  CustomHttpClient(this.authService) : _client = http.Client();

  // Cierra el cliente HTTP cuando ya no se necesite
  void close() {
    _client.close();
  }

  // GET request con interceptor
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    headers = await _addAuthHeader(headers ?? {});
    http.Response response = await _client.get(url, headers: headers);
    return await _handleResponse(response, () => get(url, headers: headers));
  }

  // POST request con interceptor
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    headers = await _addAuthHeader(headers ?? {});
    http.Response response = await _client.post(url,
        headers: headers, body: body, encoding: encoding);
    return await _handleResponse(response,
        () => post(url, headers: headers, body: body, encoding: encoding));
  }

  // PUT request con interceptor
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    headers = await _addAuthHeader(headers ?? {});
    http.Response response = await _client.put(url,
        headers: headers, body: body, encoding: encoding);
    return await _handleResponse(response,
        () => put(url, headers: headers, body: body, encoding: encoding));
  }

  // DELETE request con interceptor
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    headers = await _addAuthHeader(headers ?? {});
    http.Response response = await _client.delete(url,
        headers: headers, body: body, encoding: encoding);
    return await _handleResponse(response,
        () => delete(url, headers: headers, body: body, encoding: encoding));
  }

  // Añade el encabezado de autorización a las solicitudes
  Future<Map<String, String>> _addAuthHeader(
      Map<String, String> headers) async {
    String? token = await authService.tokenStorage.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Maneja la respuesta y reintenta si es necesario
  Future<http.Response> _handleResponse(http.Response response,
      Future<http.Response> Function() retryCallback) async {
    if (response.statusCode == 401) {
      // Token expirado, intentar refrescar
      bool refreshed = await authService.refreshToken();
      if (refreshed) {
        // Reintentar la solicitud original con el nuevo token
        return await retryCallback();
      }
    }
    return response;
  }
}
