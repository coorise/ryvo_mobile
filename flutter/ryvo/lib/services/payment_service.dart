import 'package:ryvo/lib/base_service.dart';

class PaymentService extends BaseService {
  PaymentService() : super('payment-gateway');

  Future<Map<String, dynamic>> createIntent(
    String? token, {
    required String requestId,
    String? idempotencyKey,
    double? amount,
    String? currency,
  }) {
    return post<Map<String, dynamic>>(
      '/v1/intent',
      {
        'request_id': requestId,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
      },
      token: token,
    );
  }
}

final paymentService = PaymentService();
