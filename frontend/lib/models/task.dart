import 'category.dart';
import 'tag.dart';

class Task {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final String? description;
  final String status; // Pending, In Progress, Completed
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? category;
  final List<Tag> tags;

  Task({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    required this.tags,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    var tagsJson = json['tags'] as List? ?? [];
    List<Tag> tagsList = tagsJson.map((t) => Tag.fromJson(t as Map<String, dynamic>)).toList();

    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['category'] != null ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
      tags: tagsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category?.toJson(),
      'tags': tags.map((t) => t.toJson()).toList(),
    };
  }
}
