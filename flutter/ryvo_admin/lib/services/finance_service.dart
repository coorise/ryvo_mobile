import 'package:ryvo_admin/lib/api_client.dart';
import 'package:ryvo_admin/lib/base_service.dart';

class FinanceService extends BaseService {
  FinanceService() : super('payout-service');

  Future<Map<String, dynamic>> getReferralSettings(String? token) {
    return get<Map<String, dynamic>>('/v1/admin/finance/referrals/settings', token: token);
  }

  Future<Map<String, dynamic>> updateReferralSettings(
    String? token,
    Map<String, dynamic> body,
  ) {
    return patch<Map<String, dynamic>>('/v1/admin/finance/referrals/settings', body, token: token);
  }

  Future<Map<String, dynamic>> getReferrals(String? token) {
    return get<Map<String, dynamic>>('/v1/admin/finance/referrals', token: token);
  }

  Future<Map<String, dynamic>> getCoupons(String? token) {
    return apiRequest<Map<String, dynamic>>(
      'coupon-service',
      '/v1/admin/finance/coupons',
      options: RequestOptions(token: token),
    );
  }

  Future<Map<String, dynamic>> createCoupon(String? token, Map<String, dynamic> body) {
    return apiRequest<Map<String, dynamic>>(
      'coupon-service',
      '/v1/admin/finance/coupons',
      options: RequestOptions(method: 'POST', body: body, token: token),
    );
  }

  Future<Map<String, dynamic>> updateCoupon(
    String? token,
    String id,
    Map<String, dynamic> body,
  ) {
    return apiRequest<Map<String, dynamic>>(
      'coupon-service',
      '/v1/admin/finance/coupons/$id',
      options: RequestOptions(method: 'PATCH', body: body, token: token),
    );
  }

  Future<Map<String, dynamic>> deleteCoupon(String? token, String id) {
    return apiRequest<Map<String, dynamic>>(
      'coupon-service',
      '/v1/admin/finance/coupons/$id',
      options: RequestOptions(method: 'DELETE', token: token),
    );
  }

  Future<Map<String, dynamic>> validateCoupon(String? token, String code, num fare) {
    return apiRequest<Map<String, dynamic>>(
      'coupon-service',
      '/v1/finance/coupons/validate',
      options: RequestOptions(
        method: 'POST',
        body: {'code': code, 'fare': fare},
        token: token,
      ),
    );
  }

  Future<Map<String, dynamic>> redeemCoupon(String? token, String code, {String? tripId}) {
    return apiRequest<Map<String, dynamic>>(
      'coupon-service',
      '/v1/finance/coupons/redeem',
      options: RequestOptions(
        method: 'POST',
        body: {'code': code, 'trip_id': tripId},
        token: token,
      ),
    );
  }

  Future<Map<String, dynamic>> createBonus(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/admin/finance/referrals/bonuses', body, token: token);
  }

  Future<Map<String, dynamic>> updateBonus(
    String? token,
    String id,
    Map<String, dynamic> body,
  ) {
    return patch<Map<String, dynamic>>('/v1/admin/finance/referrals/bonuses/$id', body, token: token);
  }

  Future<Map<String, dynamic>> deleteBonus(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/admin/finance/referrals/bonuses/$id', token: token);
  }

  Future<Map<String, dynamic>> createLoyalty(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/admin/finance/referrals/loyalty', body, token: token);
  }

  Future<Map<String, dynamic>> createCampaign(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/admin/finance/referrals/campaigns', body, token: token);
  }

  Future<Map<String, dynamic>> updateCampaign(
    String? token,
    String id,
    Map<String, dynamic> body,
  ) {
    return patch<Map<String, dynamic>>('/v1/admin/finance/referrals/campaigns/$id', body, token: token);
  }

  Future<Map<String, dynamic>> deleteCampaign(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/admin/finance/referrals/campaigns/$id', token: token);
  }

  Future<Map<String, dynamic>> getTariffs(String? token) {
    return get<Map<String, dynamic>>('/v1/admin/finance/tariffs', token: token);
  }

  Future<Map<String, dynamic>> createTariff(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/admin/finance/tariffs', body, token: token);
  }

  Future<Map<String, dynamic>> updateTariff(
    String? token,
    String id,
    Map<String, dynamic> body,
  ) {
    return put<Map<String, dynamic>>('/v1/admin/finance/tariffs/$id', body, token: token);
  }

  Future<Map<String, dynamic>> deleteTariff(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/admin/finance/tariffs/$id', token: token);
  }

  Future<Map<String, dynamic>> getPaychecks(String? token, {String? status}) {
    final q = status == null || status.isEmpty ? '' : '?status=$status';
    return get<Map<String, dynamic>>('/v1/admin/finance/paychecks$q', token: token);
  }

  Future<Map<String, dynamic>> createPaycheck(String? token, Map<String, dynamic> body) {
    return post<Map<String, dynamic>>('/v1/admin/finance/paychecks', body, token: token);
  }

  Future<Map<String, dynamic>> patchPaycheck(
    String? token,
    String id,
    Map<String, dynamic> body,
  ) {
    return patch<Map<String, dynamic>>('/v1/admin/finance/paychecks/$id', body, token: token);
  }

  Future<Map<String, dynamic>> updatePaycheckStatus(String? token, String id, String status) {
    return patchPaycheck(token, id, {'status': status});
  }

  Future<Map<String, dynamic>> deletePaycheck(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/admin/finance/paychecks/$id', token: token);
  }

  Future<Map<String, dynamic>> getTariffSubscriptions(String? token, {String? status}) {
    final q = status == null || status.isEmpty ? '' : '?status=$status';
    return get<Map<String, dynamic>>('/v1/admin/finance/tariff-subscriptions$q', token: token);
  }

  Future<Map<String, dynamic>> createTariffSubscription(
    String? token,
    Map<String, dynamic> body,
  ) {
    return post<Map<String, dynamic>>('/v1/admin/finance/tariff-subscriptions', body, token: token);
  }

  Future<Map<String, dynamic>> patchTariffSubscription(
    String? token,
    String id,
    Map<String, dynamic> body,
  ) {
    return patch<Map<String, dynamic>>(
      '/v1/admin/finance/tariff-subscriptions/$id',
      body,
      token: token,
    );
  }

  Future<Map<String, dynamic>> deleteTariffSubscription(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/admin/finance/tariff-subscriptions/$id', token: token);
  }

  Future<Map<String, dynamic>> getDriverEarnings(String? token) {
    return get<Map<String, dynamic>>('/v1/admin/finance/driver-earnings', token: token);
  }

  Future<Map<String, dynamic>> adjustDriverEarning(
    String? token,
    String driverId,
    Map<String, dynamic> body,
  ) {
    return patch<Map<String, dynamic>>('/v1/admin/finance/driver-earnings/$driverId', body, token: token);
  }

  Future<Map<String, dynamic>> queuePaycheckFromEarnings(
    String? token,
    String driverId,
    double amount,
  ) {
    return post<Map<String, dynamic>>(
      '/v1/admin/finance/driver-earnings/$driverId/queue-paycheck',
      {'amount': amount},
      token: token,
    );
  }

  Future<Map<String, dynamic>> getCheckouts(String? token, {String? status}) {
    final q = status == null || status.isEmpty ? '' : '?status=$status';
    return get<Map<String, dynamic>>('/v1/admin/finance/checkouts$q', token: token);
  }

  Future<Map<String, dynamic>> deleteCheckout(String? token, String id) {
    return delete<Map<String, dynamic>>('/v1/admin/finance/checkouts/$id', token: token);
  }

  Future<Map<String, dynamic>> scheduleCheckoutRecovery(
    String? token,
    String id,
    Map<String, dynamic> body,
  ) {
    return post<Map<String, dynamic>>(
      '/v1/admin/finance/checkouts/$id/recovery-reminder',
      body,
      token: token,
    );
  }
}

final financeService = FinanceService();
