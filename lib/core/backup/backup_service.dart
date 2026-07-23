import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';

class BackupResult {
  const BackupResult({required this.recordCount, required this.createdAt});

  final int recordCount;
  final DateTime createdAt;
}

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  Future<BackupResult> exportBackup() async {
    final records = await _database.readAllRecords();
    final createdAt = DateTime.now();
    final payload = <String, Object?>{
      'format': 'movemate-backup',
      'version': 1,
      'createdAt': createdAt.toIso8601String(),
      'records': records.values
          .map((record) => <String, Object?>{
                'key': record.key,
                'value': record.value,
                'updatedAt': record.updatedAt.toIso8601String(),
              })
          .toList(),
    };
    final directory = await getTemporaryDirectory();
    final safeDate = createdAt.toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/MoveMate_Backup_$safeDate.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'גיבוי MoveMate',
      text: 'קובץ גיבוי של MoveMate',
    );
    return BackupResult(recordCount: records.length, createdAt: createdAt);
  }

  Future<BackupResult?> importBackup() async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (selection == null || selection.files.isEmpty) {
      return null;
    }
    final selected = selection.files.single;
    final bytes = selected.bytes ??
        (selected.path == null ? null : await File(selected.path!).readAsBytes());
    if (bytes == null) {
      throw const FormatException('לא ניתן לקרוא את קובץ הגיבוי.');
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'movemate-backup' ||
        decoded['version'] != 1 ||
        decoded['records'] is! List) {
      throw const FormatException('קובץ הגיבוי אינו בפורמט MoveMate נתמך.');
    }
    final records = <StorageRecord>[];
    for (final raw in decoded['records'] as List) {
      if (raw is! Map) {
        throw const FormatException('רשומת גיבוי אינה תקינה.');
      }
      final map = Map<String, dynamic>.from(raw);
      final key = map['key'];
      final value = map['value'];
      final updatedAt = DateTime.tryParse(map['updatedAt'] as String? ?? '');
      if (key is! String || value is! String || updatedAt == null) {
        throw const FormatException('רשומת גיבוי חסרה נתונים.');
      }
      records.add(StorageRecord(key: key, value: value, updatedAt: updatedAt));
    }
    await _database.replaceAllRecords(records);
    return BackupResult(
      recordCount: records.length,
      createdAt: DateTime.tryParse(decoded['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
