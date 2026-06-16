import 'package:ryvo_admin/lib/base_service.dart';

class TasksService extends BaseService {
  TasksService() : super('cron-jobs');

  Future<Map<String, dynamic>> list(String? token) {
    return get<Map<String, dynamic>>('/v1/admin/settings/tasks', token: token);
  }

  Future<Map<String, dynamic>> create(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/admin/settings/tasks', body, token: token);
  }

  Future<Map<String, dynamic>> run(String? token, String id) {
    return post<Map<String, dynamic>>('/v1/admin/settings/tasks/$id/run', {}, token: token);
  }

  Future<Map<String, dynamic>> pause(String? token, String id) {
    return post<Map<String, dynamic>>('/v1/admin/settings/tasks/$id/pause', {}, token: token);
  }

  Future<Map<String, dynamic>> resume(String? token, String id) {
    return post<Map<String, dynamic>>('/v1/admin/settings/tasks/$id/resume', {}, token: token);
  }

  Future<Map<String, dynamic>> removeTask(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/admin/settings/tasks/$id', token: token);
  }
}

final tasksService = TasksService();
