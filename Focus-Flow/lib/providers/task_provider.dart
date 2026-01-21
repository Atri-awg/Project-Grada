import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fungsi untuk menambah tugas baru
  Future<void> addTask(String userId, String title, String category) async {
    await _db.collection('tasks').add({
      'userId': userId,
      'title': title,
      'category': category,
      'isDone': false,
      'dueDate': FieldValue.serverTimestamp(),
    });
  }

  // Fungsi untuk mengubah status tugas
  Future<void> toggleTaskStatus(String docId, bool currentStatus) async {
    await _db.collection('tasks').doc(docId).update({'isDone': !currentStatus});
  }

  // Fungsi untuk menghapus tugas
  Future<void> deleteTask(String docId) async {
    await _db.collection('tasks').doc(docId).delete();
  }
}
