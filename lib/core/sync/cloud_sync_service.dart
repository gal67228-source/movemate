import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/app_user.dart';
import '../database/app_database.dart';

class SyncStatus {
  const SyncStatus({
    required this.available,
    required this.syncing,
    required this.pendingWrites,
    this.lastSyncedAt,
    this.error,
  });

  const SyncStatus.disabled()
      : available = false,
        syncing = false,
        pendingWrites = 0,
        lastSyncedAt = null,
        error = null;

  final bool available;
  final bool syncing;
  final int pendingWrites;
  final DateTime? lastSyncedAt;
  final String? error;

  SyncStatus copyWith({
    bool? available,
    bool? syncing,
    int? pendingWrites,
    DateTime? lastSyncedAt,
    String? error,
    bool clearError = false,
  }) {
    return SyncStatus(
      available: available ?? this.available,
      syncing: syncing ?? this.syncing,
      pendingWrites: pendingWrites ?? this.pendingWrites,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ShareInvite {
  const ShareInvite({
    required this.code,
    required this.moveId,
    required this.expiresAt,
  });

  final String code;
  final String moveId;
  final DateTime expiresAt;
}

class SharedMember {
  const SharedMember({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.joinedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final DateTime joinedAt;
}

class CloudSyncService {
  CloudSyncService({
    required FirebaseFirestore firestore,
    required AppDatabase database,
    required AppUser user,
    required void Function() onRemoteApplied,
    required Future<void> Function(String key, String value, DateTime updatedAt) onRemoteValue,
    required Future<void> Function(Iterable<StorageRecord> records) onReplaceAll,
  })  : _firestore = firestore,
        _database = database,
        _user = user,
        _onRemoteApplied = onRemoteApplied,
        _onRemoteValue = onRemoteValue,
        _onReplaceAll = onReplaceAll;

  final FirebaseFirestore _firestore;
  final AppDatabase _database;
  final AppUser _user;
  final void Function() _onRemoteApplied;
  final Future<void> Function(String key, String value, DateTime updatedAt) _onRemoteValue;
  final Future<void> Function(Iterable<StorageRecord> records) _onReplaceAll;
  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = const SyncStatus(
    available: true,
    syncing: false,
    pendingWrites: 0,
  );
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  String? _moveId;
  bool _applyingRemote = false;

  Stream<SyncStatus> get statusChanges => _statusController.stream;

  SyncStatus get status => _status;

  String? get moveId => _moveId;

  Future<void> initialize(Map<String, StorageRecord> localRecords) async {
    try {
      await _saveUserProfile();
      final currentMove = localRecords['current_move'];
      if (currentMove == null) {
        return;
      }
      final moveJson = jsonDecode(currentMove.value) as Map<String, dynamic>;
      final ownerUid = moveJson['ownerUid'] as String?;
      final moveId = moveJson['id'] as String?;
      if (moveId == null || ownerUid == null) {
        return;
      }
      _moveId = moveId;
      await _ensureMoveDocument(moveJson);
      await synchronize(localRecords);
      _listenForRemoteChanges();
    } catch (error) {
      _setStatus(_status.copyWith(error: '$error'));
    }
  }

  Future<void> _saveUserProfile() {
    return _firestore.collection('users').doc(_user.uid).set({
      'displayName': _user.displayName,
      'email': _user.email,
      'photoUrl': _user.photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _ensureMoveDocument(Map<String, dynamic> moveJson) async {
    final moveId = moveJson['id'] as String;
    final ownerUid = moveJson['ownerUid'] as String?;
    if (ownerUid != _user.uid) {
      return;
    }
    await _firestore.collection('moves').doc(moveId).set({
      'ownerUid': ownerUid,
      'name': moveJson['name'],
      'plan': moveJson['plan'] ?? 'FREE',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> synchronize(Map<String, StorageRecord> localRecords) async {
    final moveId = _moveId;
    if (moveId == null) {
      return;
    }
    _setStatus(_status.copyWith(syncing: true, clearError: true));
    try {
      final remoteSnapshot = await _firestore
          .collection('moves')
          .doc(moveId)
          .collection('state')
          .get();
      final batch = _firestore.batch();
      var hasWrites = false;
      for (final document in remoteSnapshot.docs) {
        final data = document.data();
        final remoteValue = data['value'] as String?;
        final timestamp = data['updatedAt'] as Timestamp?;
        if (remoteValue == null || timestamp == null) {
          continue;
        }
        final remoteUpdatedAt = timestamp.toDate();
        final local = localRecords[document.id];
        if (local == null || remoteUpdatedAt.isAfter(local.updatedAt)) {
          _applyingRemote = true;
          await _onRemoteValue(document.id, remoteValue, remoteUpdatedAt);
          _applyingRemote = false;
        }
      }
      final refreshedRemote = {
        for (final document in remoteSnapshot.docs) document.id: document.data(),
      };
      for (final local in localRecords.values) {
        final remote = refreshedRemote[local.key];
        final remoteTime = (remote?['updatedAt'] as Timestamp?)?.toDate();
        if (remoteTime == null || local.updatedAt.isAfter(remoteTime)) {
          batch.set(
            _stateDocument(local.key),
            {
              'value': local.value,
              'updatedAt': Timestamp.fromDate(local.updatedAt),
              'updatedBy': _user.uid,
            },
            SetOptions(merge: true),
          );
          hasWrites = true;
        }
      }
      if (hasWrites) {
        await batch.commit();
      }
      _setStatus(_status.copyWith(
        syncing: false,
        pendingWrites: 0,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      ));
    } catch (error) {
      _setStatus(_status.copyWith(syncing: false, error: '$error'));
    }
  }

  Future<void> push(String key, String value, DateTime updatedAt) async {
    if (_applyingRemote) {
      return;
    }
    if (key == 'current_move') {
      await _configureMoveFromValue(value);
    }
    final moveId = _moveId;
    if (moveId == null) {
      return;
    }
    _setStatus(_status.copyWith(pendingWrites: _status.pendingWrites + 1));
    try {
      await _stateDocument(key).set({
        'value': value,
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedBy': _user.uid,
      }, SetOptions(merge: true));
      _setStatus(_status.copyWith(
        pendingWrites: max(0, _status.pendingWrites - 1),
        lastSyncedAt: DateTime.now(),
        clearError: true,
      ));
    } catch (error) {
      _setStatus(_status.copyWith(error: '$error'));
    }
  }

  Future<void> _configureMoveFromValue(String value) async {
    final moveJson = jsonDecode(value) as Map<String, dynamic>;
    final ownerUid = moveJson['ownerUid'] as String?;
    final moveId = moveJson['id'] as String?;
    if (moveId == null || ownerUid == null) {
      return;
    }
    final changedMove = _moveId != moveId;
    _moveId = moveId;
    await _ensureMoveDocument(moveJson);
    if (changedMove) {
      await synchronize(await _database.readAllRecords());
      _listenForRemoteChanges();
    }
  }

  void _listenForRemoteChanges() {
    final moveId = _moveId;
    if (moveId == null) {
      return;
    }
    _subscription?.cancel();
    _subscription = _firestore
        .collection('moves')
        .doc(moveId)
        .collection('state')
        .snapshots()
        .listen((snapshot) async {
      var appliedChange = false;
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          continue;
        }
        final data = change.doc.data();
        final value = data?['value'] as String?;
        final timestamp = data?['updatedAt'] as Timestamp?;
        final updatedBy = data?['updatedBy'] as String?;
        if (value == null || timestamp == null || updatedBy == _user.uid) {
          continue;
        }
        _applyingRemote = true;
        await _onRemoteValue(change.doc.id, value, timestamp.toDate());
        _applyingRemote = false;
        appliedChange = true;
      }
      if (appliedChange) {
        _onRemoteApplied();
      }
      _setStatus(_status.copyWith(lastSyncedAt: DateTime.now()));
    }, onError: (Object error) {
      _setStatus(_status.copyWith(error: '$error'));
    });
  }

  DocumentReference<Map<String, dynamic>> _stateDocument(String key) {
    return _firestore
        .collection('moves')
        .doc(_moveId)
        .collection('state')
        .doc(key);
  }

  Future<ShareInvite> createInvite() async {
    final moveId = _moveId;
    if (moveId == null) {
      throw StateError('לא נמצא מעבר מסונכרן.');
    }
    final code = _generateCode();
    final expiresAt = DateTime.now().add(const Duration(days: 7));
    await _firestore.collection('invites').doc(code).set({
      'moveId': moveId,
      'ownerUid': _user.uid,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
    return ShareInvite(code: code, moveId: moveId, expiresAt: expiresAt);
  }

  Future<void> acceptInvite(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    final inviteRef = _firestore.collection('invites').doc(code);
    final invite = await inviteRef.get();
    if (!invite.exists) {
      throw StateError('קוד ההזמנה אינו תקין.');
    }
    final data = invite.data()!;
    final active = data['active'] as bool? ?? false;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (!active || expiresAt == null || expiresAt.isBefore(DateTime.now())) {
      throw StateError('קוד ההזמנה אינו פעיל או שפג תוקפו.');
    }
    final moveId = data['moveId'] as String;
    await _firestore
        .collection('moves')
        .doc(moveId)
        .collection('members')
        .doc(_user.uid)
        .set({
      'uid': _user.uid,
      'displayName': _user.displayName,
      'email': _user.email,
      'joinedAt': FieldValue.serverTimestamp(),
      'inviteCode': code,
      'role': 'editor',
    });
    _moveId = moveId;
    final state = await _firestore
        .collection('moves')
        .doc(moveId)
        .collection('state')
        .get();
    final records = <StorageRecord>[];
    for (final document in state.docs) {
      final value = document.data()['value'] as String?;
      final timestamp = document.data()['updatedAt'] as Timestamp?;
      if (value != null && timestamp != null) {
        records.add(StorageRecord(
          key: document.id,
          value: value,
          updatedAt: timestamp.toDate(),
        ));
      }
    }
    await _onReplaceAll(records);
    _listenForRemoteChanges();
  }

  Stream<List<SharedMember>> watchMembers() {
    final moveId = _moveId;
    if (moveId == null) {
      return Stream.value(const []);
    }
    return _firestore
        .collection('moves')
        .doc(moveId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((document) {
              final data = document.data();
              return SharedMember(
                uid: document.id,
                displayName: data['displayName'] as String? ?? 'משתמש',
                email: data['email'] as String? ?? '',
                joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList());
  }

  Future<void> removeMember(String uid) async {
    final moveId = _moveId;
    if (moveId == null) {
      return;
    }
    await _firestore
        .collection('moves')
        .doc(moveId)
        .collection('members')
        .doc(uid)
        .delete();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
  }

  void _setStatus(SyncStatus value) {
    _status = value;
    if (!_statusController.isClosed) {
      _statusController.add(value);
    }
  }

  static String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }
}
