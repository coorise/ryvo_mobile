import 'package:ryvo/lib/base_service.dart';

class AuthPasswordService extends BaseService {
  AuthPasswordService() : super('auth-hooks');

  Future<Map<String, dynamic>> requestReset(String email) {
    return post<Map<String, dynamic>>(
      '/v1/auth/forgot-password',
      {'email': email},
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String code) {
    return post<Map<String, dynamic>>(
      '/v1/auth/verify-reset-otp',
      {'email': email, 'code': code},
    );
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String resetToken,
    String password,
  ) {
    return post<Map<String, dynamic>>(
      '/v1/auth/reset-password',
      {'email': email, 'reset_token': resetToken, 'password': password},
    );
  }
}

final authPasswordService = AuthPasswordService();
