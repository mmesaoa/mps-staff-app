import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  // ✅ 1. ADD A PROPERTY TO HOLD THE BASE URL FOR FILES
  final String storageBaseUrl;

  // This is the base URL for your API endpoints
  // ✅ Switched to local backend for testing Student Analytics Dashboard
  //static const String _apiBaseUrl = 'http://10.0.2.2:8000/api/v1/'; 
   static const String _apiBaseUrl = 'https://multischoolv2.projectworlds.com/api/v1/';

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: _apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Accept': 'application/json',
            },
          ),
        ),
        // ✅ 2. CALCULATE THE STORAGE URL FROM THE API URL
        // The .origin property of Uri gives us exactly what we need (e.g., http://10.0.2.2:8000)
        storageBaseUrl = Uri.parse(_apiBaseUrl).origin
  {
    dio.interceptors.add(AuthInterceptor());
  }
}