import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream data tugas secara real-time berdasarkan User ID
  Stream<List<TaskModel>> getTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Tambah Tugas Baru
  Future<void> addTask(TaskModel task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  // Update Status Tugas (Selesai/Belum)
  Future<void> updateTaskStatus(String docId, bool isDone) async {
    await _db.collection('tasks').doc(docId).update({'isDone': isDone});
  }

  // Hapus Tugas
  Future<void> deleteTask(String docId) async {
    await _db.collection('tasks').doc(docId).delete();
  }
}
