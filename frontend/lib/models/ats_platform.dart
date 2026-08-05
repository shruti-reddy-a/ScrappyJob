import 'package:cloud_firestore/cloud_firestore.dart';

class AtsPlatform {
  String id;
  String userId;
  String name;
  String domain;
  bool isEnabled;
  DateTime? createdAt;

  AtsPlatform({
    required this.id,
    required this.userId,
    required this.name,
    required this.domain,
    this.isEnabled = true,
    this.createdAt,
  });

  factory AtsPlatform.fromMap(Map<String, dynamic> data, String documentId) {
    return AtsPlatform(
      id: documentId,
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      domain: data['domain'] ?? '',
      isEnabled: data['is_enabled'] ?? true,
      createdAt: data['created_at'] != null ? (data['created_at'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'domain': domain,
      'is_enabled': isEnabled,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
