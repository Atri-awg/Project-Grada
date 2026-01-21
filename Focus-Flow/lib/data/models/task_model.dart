import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String?
  id; // ID dokumen dari Firestore (nullable karena saat buat baru ID belum ada)
  final String userId; // ID user pemilik tugas
  final String title; // Judul tugas
  final String category; // Kategori (misal: Kuliah, UKMI, Personal)
  final bool isDone; // Status pengerjaan
  final DateTime dueDate; // Tenggat waktu

  TaskModel({
    this.id,
    required this.userId,
    required this.title,
    required this.category,
    this.isDone = false,
    required this.dueDate,
  });

  // 1. Mengubah data dari Map Firestore menjadi Objek TaskModel
  factory TaskModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TaskModel(
      id: documentId,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? 'Umum',
      isDone: data['isDone'] ?? false,
      // Konversi Timestamp Firestore ke DateTime Dart
      dueDate: (data['dueDate'] as Timestamp).toDate(),
    );
  }

  // 2. Mengubah Objek TaskModel menjadi Map untuk dikirim ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'isDone': isDone,
      // Konversi DateTime Dart ke Timestamp Firestore
      'dueDate': Timestamp.fromDate(dueDate),
    };
  }

  // 3. Fungsi CopyWith (Opsional: Berguna jika ingin mengubah satu field saja tanpa merusak data lain)
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    bool? isDone,
    DateTime? dueDate,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
