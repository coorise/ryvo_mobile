import 'package:ryvo/lib/base_service.dart';

class KycService extends BaseService {
  KycService() : super('kyc-service');

  Future<Map<String, dynamic>> getChecklist(String? token) {
    return get<Map<String, dynamic>>('/v1/checklist', token: token);
  }

  Future<Map<String, dynamic>> getDocumentViewUrl(String? token, String docType) {
    return get<Map<String, dynamic>>('/v1/documents/$docType/view-url', token: token);
  }

  Future<Map<String, dynamic>> submitDocument(String? token, String docType, String s3Key) {
    return post<Map<String, dynamic>>('/v1/submit', {
      'doc_type': docType,
      's3_key': s3Key,
    }, token: token);
  }
}

final kycService = KycService();
