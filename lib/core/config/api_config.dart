class ApiConfig {
  static const String baseUrl = 'http://172.24.207.142:8000/api/v1';
  static const String storageUrl = 'http://172.24.207.142:8000/storage/';

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> headersWithAuth(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };

  // Timeout configurations (increased for mobile networks)
  static const Duration connectTimeout = Duration(seconds: 120);
  static const Duration receiveTimeout = Duration(seconds: 120);
  
  // Alternative URLs for different network conditions
  static const String localUrl = 'http://172.24.207.142:8000/api/v1';
  static const String externalUrl = 'http://172.24.207.142:8000/api/v1'; // Update if you have external IP
}
