import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Category> _categories = [];
  List<Tag> _tags = [];

  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  List<Category> get categories => _categories;
  List<Tag> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _clearError() {
    _error = null;
  }

  // --- Fetch Tasks ---
  Future<void> fetchTasks({String? status, String? categoryId, String? search}) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      String path = '/tasks/?';
      if (status != null) path += 'status=$status&';
      if (categoryId != null) path += 'category_id=$categoryId&';
      if (search != null) path += 'search=${Uri.encodeComponent(search)}&';

      final response = await ApiService.get(path);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tasks = data.map((t) => Task.fromJson(t as Map<String, dynamic>)).toList();
      } else {
        _error = 'Failed to load tasks.';
      }
    } catch (e) {
      _error = 'Error connecting to backend.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Tasks CRUD ---
  Future<bool> createTask({
    required String title,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    List<String> tagIds = const [],
  }) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final response = await ApiService.post('/tasks/', {
        'title': title,
        'description': description,
        'category_id': categoryId,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'tag_ids': tagIds,
      });

      if (response.statusCode == 201) {
        final newTask = Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        _tasks.insert(0, newTask); // Insert at beginning of locally cached tasks
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Error creating task.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
      final response = await ApiService.patch('/tasks/$taskId', {
        'status': newStatus,
      });

      if (response.statusCode == 200) {
        final updatedTask = Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      _error = 'Error updating task status.';
    }
    return false;
  }

  Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.patch('/tasks/$taskId', updates);
      if (response.statusCode == 200) {
        final updatedTask = Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Error updating task.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final response = await ApiService.delete('/tasks/$taskId');
      if (response.statusCode == 204) {
        _tasks.removeWhere((t) => t.id == taskId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Error deleting task.';
    }
    return false;
  }

  // --- Fetch & CRUD Categories ---
  Future<void> fetchCategories() async {
    try {
      final response = await ApiService.get('/categories/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _categories = data.map((c) => Category.fromJson(c as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createCategory(String name, String colorHex) async {
    try {
      final response = await ApiService.post('/categories/', {
        'name': name,
        'color_hex': colorHex,
      });

      if (response.statusCode == 201) {
        final newCategory = Category.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        _categories.add(newCategory);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final response = await ApiService.delete('/categories/$id');
      if (response.statusCode == 204) {
        _categories.removeWhere((c) => c.id == id);
        // Cascade effect in locally cached tasks (category_id becomes null)
        for (var i = 0; i < _tasks.length; i++) {
          if (_tasks[i].categoryId == id) {
            _tasks[i] = Task(
              id: _tasks[i].id,
              userId: _tasks[i].userId,
              categoryId: null,
              title: _tasks[i].title,
              description: _tasks[i].description,
              status: _tasks[i].status,
              dueDate: _tasks[i].dueDate,
              createdAt: _tasks[i].createdAt,
              updatedAt: _tasks[i].updatedAt,
              category: null,
              tags: _tasks[i].tags,
            );
          }
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // --- Fetch & CRUD Tags ---
  Future<void> fetchTags() async {
    try {
      final response = await ApiService.get('/tags/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _tags = data.map((t) => Tag.fromJson(t as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createTag(String name) async {
    try {
      final response = await ApiService.post('/tags/', {
        'name': name,
      });

      if (response.statusCode == 201) {
        final newTag = Tag.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        _tags.add(newTag);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteTag(String id) async {
    try {
      final response = await ApiService.delete('/tags/$id');
      if (response.statusCode == 204) {
        _tags.removeWhere((t) => t.id == id);
        // Locally remove tag from tasks
        for (var i = 0; i < _tasks.length; i++) {
          _tasks[i].tags.removeWhere((t) => t.id == id);
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
