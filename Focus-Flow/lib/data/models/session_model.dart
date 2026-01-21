import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String userId;
  final int duration;
  final DateTime startTime;

  SessionModel({
    required this.userId,
    required this.duration,
    required this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'duration': duration,
      'startTime': Timestamp.fromDate(startTime),
    };
  }
}
