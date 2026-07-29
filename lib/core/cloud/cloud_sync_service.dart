import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/app_database.dart';

class CloudSyncService {
  CloudSyncService({
    required AppDatabase database,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _database = database,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AppDatabase _database;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  StreamSubscription<Map<String, StorageRecord>>? _localSubscription;
  bool _applyingCloudRecords = false;

  Future<void> start() async {
    var user = _auth.currentUser;
    user ??= (await _auth.signInAnonymously()).user;
    if (user == null) {
      return;
    }

    await _mergeCloudAndLocal(user.uid);
    _localSubscription = _database.watchAllRecords().listen((records) {
      if (_applyingCloudRecords) {
        return;
      }
      unawaited(_uploadSnapshot(user!.uid, records));
    });
  }

  Future<void> dispose() async {
    await _localSubscription?.cancel();
  }

  CollectionReference<Map<String, dynamic>> _entries(String uid) {
    return _firestore.collection('users').doc(uid).collection('appStorage');
  }

  Future<void> _mergeCloudAndLocal(String uid) async {
    final local = await _database.readAllRecords();
    final cloudSnapshot = await _entries(uid).get();
    final merged = Map<String, StorageRecord>.from(local);

    for (final document in cloudSnapshot.docs) {
      final data = document.data();
      final key = data['key'];
      final value = data['value'];
      final updatedAt = data['updatedAt'];
      if (key is! String || value is! String || updatedAt is! Timestamp) {
        continue;
      }

      final cloudRecord = StorageRecord(
        key: key,
        value: value,
        updatedAt: updatedAt.toDate(),
      );
      final localRecord = merged[key];
      if (localRecord == null || cloudRecord.updatedAt.isAfter(localRecord.updatedAt)) {
        merged[key] = cloudRecord;
      }
    }

    _applyingCloudRecords = true;
    try {
      await _database.replaceAllRecords(merged.values);
    } finally {
      _applyingCloudRecords = false;
    }

    await _uploadSnapshot(uid, merged);
  }

  Future<void> _uploadSnapshot(
    String uid,
    Map<String, StorageRecord> records,
  ) async {
    final entries = _entries(uid);
    final existing = await entries.get();
    final batch = _firestore.batch();
    final expectedIds = <String>{};

    for (final record in records.values) {
      final documentId = _documentId(record.key);
      expectedIds.add(documentId);
      batch.set(entries.doc(documentId), <String, Object>{
        'key': record.key,
        'value': record.value,
        'updatedAt': Timestamp.fromDate(record.updatedAt),
      });
    }

    for (final document in existing.docs) {
      if (!expectedIds.contains(document.id)) {
        batch.delete(document.reference);
      }
    }

    await batch.commit();
  }

  String _documentId(String key) {
    return base64Url.encode(utf8.encode(key)).replaceAll('=', '');
  }
}
