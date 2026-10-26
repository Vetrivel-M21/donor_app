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

  String _extractErrorMessage(dynamic data, [String fallback = 'Operation failed']) {
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['message'] != null) {
        return err['message'].toString();
      }
      if (err is String && err.isNotEmpty) {
        return err;
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    } else if (data is String && data.isNotEmpty) {
      if (data.contains('<html') || data.contains('<HTML')) {
        return fallback;
      }
      return data;
    }
    return fallback;
  }

  Never _throwDioError(DioException e, [String fallback = 'Network request failed']) {
    final res = e.response;
    if (res != null) {
      final statusCode = res.statusCode;
      if (statusCode == 503) {
        throw Exception('Server is temporarily unavailable (503 Service Unavailable). Please ensure the backend service is running.');
      } else if (statusCode == 502) {
        throw Exception('Bad Gateway (502). The backend service is not running or unreachable.');
      } else if (statusCode == 504) {
        throw Exception('Gateway Timeout (504). The backend server took too long to respond.');
      } else if (statusCode == 404) {
        throw Exception('API endpoint not found (404).');
      }

      final msg = _extractErrorMessage(res.data, res.statusMessage ?? fallback);
      throw Exception(msg);
    }
    throw Exception(e.message ?? fallback);
  }

  Future<PublicDashboard> getDashboard() async {
    try {
      final res = await _dio.get('/public/dashboard');
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        return PublicDashboard.fromJson(data['data']);
      }
      throw Exception(_extractErrorMessage(data, 'Failed to load dashboard'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to load dashboard');
      }
      rethrow;
    }
  }

  Future<List<PublicScheme>> getActiveSchemes() async {
    try {
      final res = await _dio.get('/public/schemes/active');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        final list = data['data'] as List? ?? [];
        return list.map((e) => PublicScheme.fromJson(e)).toList();
      }
      throw Exception(_extractErrorMessage(data, 'Failed to load schemes'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to load schemes');
      }
      rethrow;
    }
  }

  Future<AppDonationConfig> getAppDonationConfig() async {
    try {
      final res = await _dio.get('/public/app-donation-config');
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        return AppDonationConfig.fromJson(data['data']);
      }
      throw Exception(_extractErrorMessage(data, 'Failed to load bank configuration'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to load bank configuration');
      }
      rethrow;
    }
  }

  Future<DonorHistoryResponse> getDonorHistory(String phone) async {
    try {
      final res = await _dio.get('/public/donations/history', queryParameters: {'phone': phone});
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        return DonorHistoryResponse.fromJson(data['data']);
      }
      throw Exception(_extractErrorMessage(data, 'Failed to fetch donor history'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to fetch donor history');
      }
      rethrow;
    }
  }

  Future<DonationReceipt> createDonation(CreateDonationRequest request) async {
    try {
      final res = await _dio.post('/public/donations', data: request.toJson());
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        return DonationReceipt.fromJson(data['data']);
      }
      throw Exception(_extractErrorMessage(data, 'Failed to create donation'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to create donation');
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
      if (data is Map && data['success'] == true && data['data'] != null) {
        return RazorpayOrderResponse.fromJson(data['data']);
      }
      throw Exception(_extractErrorMessage(data, 'Failed to create payment order'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to create payment order');
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
      if (data is Map && data['success'] == true && data['data']?['path'] != null) {
        return data['data']['path'] as String;
      }
      throw Exception(_extractErrorMessage(data, 'Failed to upload screenshot'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to upload screenshot');
      }
      rethrow;
    }
  }

  /// Creates an online payment gateway order (Cashfree / Razorpay)
  Future<Map<String, dynamic>> createGatewayOrder({
    required String amount,
    required String fullName,
    required String phone,
    required String email,
    required String trustHome,
  }) async {
    try {
      final res = await _dio.post('/public/donations/create-gateway-order', data: {
        'amount': amount,
        'full_name': fullName,
        'donor_name': fullName,
        'phone': phone,
        'email': email,
        'trust_home': trustHome,
      });
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      throw Exception(_extractErrorMessage(data, 'Failed to create payment gateway order'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to create payment gateway order');
      }
      rethrow;
    }
  }

  /// Automatically verifies gateway payment and issues official Section 80G tax receipt
  /// without requiring manual staff approval
  Future<DonationReceipt> verifyAndIssueDonation(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/public/donations/verify-and-issue', data: payload);
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] != null) {
        return DonationReceipt.fromJson(data['data']);
      }
      throw Exception(_extractErrorMessage(data, 'Failed to verify and issue donation'));
    } catch (e) {
      if (e is DioException) {
        _throwDioError(e, 'Failed to verify and issue donation');
      }
      rethrow;
    }
  }
}
