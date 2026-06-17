import 'package:ryvo/lib/base_service.dart';

class ProfileService extends BaseService {
  ProfileService() : super('profile-service');

  Future<Map<String, dynamic>> getDriverPublicProfile(String? token, String userId) {
    return get<Map<String, dynamic>>('/v1/drivers/$userId/public', token: token);
  }
}

final profileService = ProfileService();
