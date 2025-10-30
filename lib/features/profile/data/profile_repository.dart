import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:forum_alumni/core/services/api_client.dart';
import 'models/profile_model.dart';

class ProfileRepository {
  ProfileRepository({Dio? client}) : _client = client ?? ApiClient().client;

  final Dio _client;

  Future<ProfileModel> fetchProfile() async {
    try {
      // First, try to get cached user profile from login data
      final apiClient = ApiClient();
      final cachedProfile = await apiClient.storage.read(key: 'user_profile');

      if (cachedProfile != null) {
        try {
          print('📱 Using cached profile data from login');
          final profileData = jsonDecode(cachedProfile) as Map<String, dynamic>;
          return ProfileModel.fromJson(profileData);
        } catch (e) {
          print('❌ Error parsing cached profile: $e');
        }
      }

      print('🌐 No cached data, trying API endpoints...');

      // Try different potential profile endpoints as fallback
      final endpoints = ['/user/profile', '/me', '/auth/profile', '/user'];

      for (final endpoint in endpoints) {
        try {
          print('🔍 Trying endpoint: $endpoint');
          final response = await _client.get(endpoint);

          // Check if response is HTML (authentication failure)
          if (response.data is String &&
              response.data.toString().contains('<!DOCTYPE html>')) {
            print('🚨 Got HTML response from $endpoint - skipping');
            continue;
          }

          if (response.statusCode == 200 &&
              response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            print('📄 Response Data from $endpoint: $data');

            // If it has success field and data
            if (data.containsKey('success') &&
                data['success'] == true &&
                data.containsKey('data')) {
              return ProfileModel.fromJson(
                data['data'] as Map<String, dynamic>,
              );
            }

            // If the data is directly in the response
            if (data.containsKey('id') ||
                data.containsKey('nama') ||
                data.containsKey('name')) {
              return ProfileModel.fromJson(data);
            }
          }
        } catch (e) {
          print('❌ Error with $endpoint: $e');
          continue;
        }
      }

      throw DioException(
        requestOptions: RequestOptions(path: '/profile'),
        type: DioExceptionType.badResponse,
        error: 'Tidak dapat memuat profil - silakan login ulang',
      );
    } catch (e) {
      print('❌ Profile fetch completely failed: $e');
      rethrow;
    }
  }

  Future<ProfileModel> updateProfile({
    required String name,
    required String email,
    String? angkatan,
    String? status,
    String? phone,
    String? job,
  }) async {
    final updateData = {
      'name': name,
      'email': email,
      if (angkatan != null) 'angkatan': angkatan,
      if (status != null) 'status': status,
      if (phone != null) 'no_hp': phone,
      if (job != null) 'pekerjaan': job,
    };

    print('🔄 Mencoba update profile ke database...');
    print('📦 Update data: $updateData');

    // Check if we have authentication token
    final apiClient = ApiClient();
    final token = await apiClient.storage.read(key: 'auth_token');
    print(
      '🔐 Auth token available: ${token != null ? "YES (${token.substring(0, 20)}...)" : "NO"}',
    );

    // Test Laravel endpoints one by one with detailed logging
    print('🧪 Testing Laravel endpoints individually...');
    
    // First, test if we can reach the server at all
    try {
      final testResponse = await _client.get('/');
      print('✅ Server reachable: ${testResponse.statusCode}');
    } catch (e) {
      print('❌ Server unreachable: $e');
    }
    
    // Try the main profile update endpoints that should now exist
    final updateEndpoints = [
      '/alumni_profiles/me', // Primary endpoint (should exist now)
      '/users/me', // User-specific endpoint (only PUT works)
      '/alumni_profiles', // Alternative collection endpoint
      '/profile', // Generic profile endpoint
    ];

    for (final endpoint in updateEndpoints) {
      try {
        print('🔄 ============================================');
        print('🔄 TESTING ENDPOINT: $endpoint');
        print('🔄 ============================================');

        // First test if endpoint exists with OPTIONS or GET
        try {
          print('🧪 Testing if endpoint exists...');
          final testResponse = await _client.get(endpoint);
          print('✅ Endpoint exists! Status: ${testResponse.statusCode}');
          print('📄 Test response: ${testResponse.data}');
        } catch (testError) {
          print('❌ Endpoint test failed: $testError');
          if (testError.toString().contains('404')) {
            print('🚨 ENDPOINT DOES NOT EXIST: $endpoint');
          } else if (testError.toString().contains('302')) {
            print('🚨 AUTHENTICATION REQUIRED for $endpoint');
          } else if (testError.toString().contains('405')) {
            print('✅ Endpoint exists but GET not allowed (normal for update endpoints)');
          }
        }

        Response? response;

        try {
          // For /users/me, only use PUT (Laravel shows it only supports GET, HEAD, PUT)
          if (endpoint == '/users/me') {
            print('🚀 Sending PUT request to: $endpoint (only method supported)');
            print('🔑 Using token: ${token?.substring(0, 30)}...');
            response = await _client.put(endpoint, data: updateData);
            print('✅ PUT success for $endpoint: ${response.statusCode}');
          } else {
            // For other endpoints, try PUT first
            print('🚀 Sending PUT request to: $endpoint');
            print('🔑 Using token: ${token?.substring(0, 30)}...');
            response = await _client.put(endpoint, data: updateData);
            print('✅ PUT success for $endpoint: ${response.statusCode}');
          }
        } catch (e) {
          print('❌ PUT failed for $endpoint: $e');
          print('📍 Full PUT Error: ${e.toString()}');
          
          // Check specific error types
          if (e.toString().contains('404')) {
            print('🚨 404 ERROR: Endpoint $endpoint NOT FOUND in Laravel routes');
          } else if (e.toString().contains('302')) {
            print('🚨 302 REDIRECT: Laravel not recognizing token for $endpoint');
          } else if (e.toString().contains('401')) {
            print('🚨 401 UNAUTHORIZED: Token invalid or expired for $endpoint');
          } else if (e.toString().contains('422')) {
            print('🚨 422 VALIDATION: Data validation failed for $endpoint');
          }

          // Skip PATCH/POST for /users/me since Laravel says they're not supported
          if (endpoint == '/users/me') {
            print(
              '⚠️ Skipping PATCH/POST for /users/me - Laravel only supports PUT',
            );
            throw e;
          }

          try {
            // Try PATCH as backup for other endpoints
            print('🚀 Sending PATCH request to: $endpoint');
            response = await _client.patch(endpoint, data: updateData);
            print('✅ PATCH success for $endpoint: ${response.statusCode}');
          } catch (e2) {
            print('❌ PATCH failed for $endpoint: $e2');
            if (e2.toString().contains('DioException')) {
              print('📍 PATCH Error details: ${e2.toString()}');
            }

            // Skip POST for /profile since Laravel shows it only supports GET, HEAD, PUT, PATCH
            if (endpoint == '/profile') {
              print('⚠️ Skipping POST for /profile - Laravel only supports PUT/PATCH');
              throw e2;
            }

            try {
              // Try POST as last resort for other endpoints
              print('🚀 Sending POST request to: $endpoint');
              response = await _client.post(endpoint, data: updateData);
              print('✅ POST success for $endpoint: ${response.statusCode}');
            } catch (e3) {
              print('❌ POST failed for $endpoint: $e3');
              if (e3.toString().contains('DioException')) {
                print('📍 POST Error details: ${e3.toString()}');
              }
              throw e3;
            }
          }
        }

        print(
          '📤 Database update response ($endpoint): ${response.statusCode}',
        );
        print('📄 Response data: ${response.data}');

        // Check if response is HTML (authentication failure)
        if (response.data is String &&
            response.data.toString().contains('<!DOCTYPE html>')) {
          print('🚨 Got HTML response from $endpoint - authentication issue');
          continue;
        }

        // Check for successful status codes
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            print('✅ Database update successful: $data');

            ProfileModel updatedProfile;

            // Handle Laravel response format
            if (data.containsKey('success') &&
                data['success'] == true &&
                data.containsKey('data')) {
              updatedProfile = ProfileModel.fromJson(
                data['data'] as Map<String, dynamic>,
              );
            } else if (data.containsKey('id') ||
                data.containsKey('nama') ||
                data.containsKey('nama')) {
              updatedProfile = ProfileModel.fromJson(data);
            } else {
              throw Exception('Invalid response format from database');
            }

            // Update cached profile data
            final apiClient = ApiClient();
            await apiClient.storage.write(
              key: 'user_profile',
              value: jsonEncode(updatedProfile.toJson()),
            );

            print('✅ Profil berhasil diperbarui di database dan cache');
            print('🎯 Database updated via: $endpoint');
            return updatedProfile;
          }
        }
      } catch (e) {
        print('❌ Error updating via $endpoint: $e');
        continue;
      }
    }

    // If all database endpoints fail, save locally as fallback
    print(
      '⚠️ Semua endpoint database gagal - menyimpan perubahan secara lokal sebagai fallback',
    );
    try {
      // Get current cached profile
      final apiClient = ApiClient();
      final cachedProfile = await apiClient.storage.read(key: 'user_profile');

      ProfileModel currentProfile;
      if (cachedProfile != null) {
        final profileData = jsonDecode(cachedProfile) as Map<String, dynamic>;
        currentProfile = ProfileModel.fromJson(profileData);
      } else {
        throw Exception('Tidak ada data profil tersimpan');
      }

      // Create updated profile with new data
      final updatedProfile = ProfileModel(
        id: currentProfile.id,
        userId: currentProfile.userId,
        name: name,
        email: email,
        angkatan: angkatan ?? currentProfile.angkatan,
        status: status ?? currentProfile.status,
        phone: phone ?? currentProfile.phone,
        job: job ?? currentProfile.job,
        avatarUrl: currentProfile.avatarUrl,
      );

      // Save updated profile to cache
      await apiClient.storage.write(
        key: 'user_profile',
        value: jsonEncode(updatedProfile.toJson()),
      );

      print('✅ Profil berhasil diperbarui (tersimpan lokal)');
      print(
        '📄 Data yang diperbarui: name=$name, email=$email, angkatan=$angkatan',
      );
      print(
        '⚠️ Catatan: Backend belum memiliki endpoint update - data tersimpan lokal',
      );

      return updatedProfile;
    } catch (e) {
      print('❌ Error updating profile: $e');
      throw DioException(
        requestOptions: RequestOptions(path: '/profile'),
        type: DioExceptionType.badResponse,
        error: 'Gagal menyimpan perubahan profil: $e',
      );
    }
  }

  Future<ProfileModel> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await _client.post('/profile/avatar', data: formData);

    if (response.statusCode == 200 && response.data['success'] == true) {
      return ProfileModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Gagal mengunggah avatar',
    );
  }
}
