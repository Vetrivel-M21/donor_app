import 'package:dio/dio.dart';
import '../../models/models.dart';
import '../constants/api_constants.dart';

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  final Dio _dio;

  Future<PublicDashboard> getDashboard() async {
    try {
      final res = await _dio.get('/public/dashboard');
      final data = res.data;
      if (data['success'] == true) {
        return PublicDashboard.fromJson(data['data']);
      }
      throw Exception(data['error']?['message'] ?? 'Failed to load dashboard');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error']?['message'] ?? e.message);
      }
      rethrow;
    }
  }

  Future<List<PublicScheme>> getActiveSchemes() async {
    try {
      final res = await _dio.get('/public/schemes/active');
      final data = res.data;
      if (data['success'] == true) {
        final list = data['data'] as List? ?? [];
        return list.map((e) => PublicScheme.fromJson(e)).toList();
      }
      throw Exception(data['error']?['message'] ?? 'Failed to load schemes');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error']?['message'] ?? e.message);
      }
      rethrow;
    }
  }

  Future<AppDonationConfig> getAppDonationConfig() async {
    try {
      final res = await _dio.get('/public/app-donation-config');
      final data = res.data;
      if (data['success'] == true) {
        return AppDonationConfig.fromJson(data['data']);
      }
      throw Exception(data['error']?['message'] ?? 'Failed to load bank configuration');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error']?['message'] ?? e.message);
      }
      rethrow;
    }
  }

  Future<DonorHistoryResponse> getDonorHistory(String phone) async {
    try {
      final res = await _dio.get('/public/donations/history', queryParameters: {'phone': phone});
      final data = res.data;
      if (data['success'] == true) {
        return DonorHistoryResponse.fromJson(data['data']);
      }
      throw Exception(data['error']?['message'] ?? 'Failed to fetch donor history');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error']?['message'] ?? e.message);
      }
      rethrow;
    }
  }

  Future<DonationReceipt> createDonation(CreateDonationRequest request) async {
    try {
      final res = await _dio.post('/public/donations', data: request.toJson());
      final data = res.data;
      if (data['success'] == true) {
        return DonationReceipt.fromJson(data['data']);
      }
      throw Exception(data['error']?['message'] ?? 'Failed to create donation');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error']?['message'] ?? e.message);
      }
      rethrow;
    }
  }

  /// Creates a Razorpay order on the backend and returns the order details.
  /// Backend endpoint: POST /public/donations/create-order
  /// Expected body: { "amount": "500.00", "donor_name": "...", "phone": "..." }
  Future<RazorpayOrderResponse> createRazorpayOrder({
    required String amount,
    required String donorName,
    required String phone,
  }) async {
    try {
      final res = await _dio.post(
        '/public/donations/create-order',
        data: {
          'amount': amount,
          'donor_name': donorName,
          'phone': phone,
        },
      );
      final data = res.data;
      if (data['success'] == true) {
        return RazorpayOrderResponse.fromJson(data['data']);
      }
      throw Exception(data['error']?['message'] ?? 'Failed to create payment order');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error']?['message'] ?? e.message);
      }
      rethrow;
    }
  }

  Future<String> uploadPaymentScreenshot(String filePath) async {
    try {
      final fileName = filePath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final res = await _dio.post('/public/upload-screenshot', data: formData);
      final data = res.data;
      if (data['success'] == true && data['data']?['path'] != null) {
        return data['data']['path'] as String;
      }
      throw Exception(data['error']?['message'] ?? 'Failed to upload screenshot');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error']?['message'] ?? e.message);
      }
      rethrow;
    }
  }
}
