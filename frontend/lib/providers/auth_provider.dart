import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && ApiService.token != null;

  void _clearError() {
    _error = null;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final response = await ApiService.postForm('/auth/login', {
        'username': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ApiService.token = data['access_token'] as String;

        // Fetch user profile info
        return await fetchProfile();
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] is String
            ? data['detail'] as String
            : 'Login failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check if backend is running.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/register', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] is String
            ? data['detail'] as String
            : 'Registration failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check if backend is running.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchProfile() async {
    try {
      final response = await ApiService.get('/auth/me');
      if (response.statusCode == 200) {
        _user = User.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        logout();
        return false;
      }
    } catch (e) {
      logout();
      return false;
    }
  }

  void logout() {
    _user = null;
    ApiService.token = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
