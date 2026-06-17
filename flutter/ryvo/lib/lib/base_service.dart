import 'package:ryvo/lib/api_client.dart';

abstract class BaseService {
  BaseService(this.serviceName);

  final String serviceName;

  Future<T> get<T>(String path, {String? token}) =>
      apiRequest<T>(serviceName, path, options: RequestOptions(token: token));

  Future<T> post<T>(String path, Object body, {String? token}) => apiRequest<T>(
        serviceName,
        path,
        options: RequestOptions(method: 'POST', body: body, token: token),
      );

  Future<T> patch<T>(String path, Object body, {String? token}) => apiRequest<T>(
        serviceName,
        path,
        options: RequestOptions(method: 'PATCH', body: body, token: token),
      );

  Future<T> put<T>(String path, Object body, {String? token}) => apiRequest<T>(
        serviceName,
        path,
        options: RequestOptions(method: 'PUT', body: body, token: token),
      );

  Future<T> delete<T>(String path, {String? token, Object? body}) => apiRequest<T>(
        serviceName,
        path,
        options: RequestOptions(method: 'DELETE', body: body, token: token),
      );
}
