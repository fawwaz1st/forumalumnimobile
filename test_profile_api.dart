import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test profile API endpoints
  const baseUrl = 'http://10.126.9.142:8000/api/v1';
  
  // You'll need to replace this with a valid token from your app
  const token = 'your_auth_token_here';
  
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
  
  print('🧪 Testing Profile API Endpoints...\n');
  
  // Test 1: /alumni_profiles/me
  try {
    print('📡 Testing /alumni_profiles/me...');
    final response1 = await http.get(
      Uri.parse('$baseUrl/alumni_profiles/me'),
      headers: headers,
    );
    
    print('Status: ${response1.statusCode}');
    print('Response: ${response1.body}');
    print('---');
    
    if (response1.statusCode == 200) {
      final data = jsonDecode(response1.body);
      print('Parsed Data: $data');
    }
  } catch (e) {
    print('Error: $e');
  }
  
  print('\n');
  
  // Test 2: /profile (fallback)
  try {
    print('📡 Testing /profile (fallback)...');
    final response2 = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: headers,
    );
    
    print('Status: ${response2.statusCode}');
    print('Response: ${response2.body}');
    print('---');
    
    if (response2.statusCode == 200) {
      final data = jsonDecode(response2.body);
      print('Parsed Data: $data');
    }
  } catch (e) {
    print('Error: $e');
  }
  
  print('\n');
  
  // Test 3: Direct alumni_profiles endpoint
  try {
    print('📡 Testing /alumni_profiles...');
    final response3 = await http.get(
      Uri.parse('$baseUrl/alumni_profiles'),
      headers: headers,
    );
    
    print('Status: ${response3.statusCode}');
    print('Response: ${response3.body}');
    
    if (response3.statusCode == 200) {
      final data = jsonDecode(response3.body);
      print('Parsed Data: $data');
    }
  } catch (e) {
    print('Error: $e');
  }
}
