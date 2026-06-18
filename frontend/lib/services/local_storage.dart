import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed local persistence layer for interview history.
///
/// Each user gets their own Hive [Box] named `interviews_<userId>`.
/// This survives sign-out, app restarts, and Supabase outages.
///
/// Initialization: call [HiveStorage.init()] once in main() before runApp().
class HiveStorage {
  static const String _boxPrefix = 'interviews_';

  /// Initialize Hive. Must be called once before any other method.
  static Future<void> init() async {
    await Hive.initFlutter();
    debugPrint('[HiveStorage] Hive initialized.');
  }

  /// Returns (opening if needed) the Hive Box scoped to [userId].
  static Future<Box<Map>> _box(String userId) async {
    final boxName = '$_boxPrefix$userId';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Map>(boxName);
    }
    return await Hive.openBox<Map>(boxName);
  }

  /// Persist a completed interview record for [userId].
  ///
  /// The interview [id] field is used as the Hive key for O(1) dedup.
  static Future<void> saveInterview(
    String userId,
    Map<String, dynamic> interview,
  ) async {
    try {
      final box = await _box(userId);
      final id = interview['id']?.toString();
      if (id == null || id.isEmpty) {
        debugPrint('[HiveStorage] Skipping save: interview has no id.');
        return;
      }
      // putIfAbsent: don't overwrite if already present
      if (!box.containsKey(id)) {
        await box.put(id, interview);
        debugPrint('[HiveStorage] Saved interview $id for user $userId. '
            'Total stored: ${box.length}');
      }
    } catch (e) {
      debugPrint('[HiveStorage] Error saving interview: $e');
    }
  }

  /// Load all persisted interviews for [userId], newest first.
  static Future<List<Map<String, dynamic>>> loadInterviews(
    String userId,
  ) async {
    try {
      final box = await _box(userId);
      final records = box.values
          .map((v) => Map<String, dynamic>.from(v))
          .toList();

      // Sort newest-first by created_at
      records.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      debugPrint('[HiveStorage] Loaded ${records.length} interviews for '
          'user $userId.');
      return records;
    } catch (e) {
      debugPrint('[HiveStorage] Error loading interviews: $e');
      return [];
    }
  }

  /// Delete a single interview by [interviewId] for [userId].
  static Future<void> deleteInterview(
    String userId,
    String interviewId,
  ) async {
    try {
      final box = await _box(userId);
      await box.delete(interviewId);
      debugPrint('[HiveStorage] Deleted interview $interviewId.');
    } catch (e) {
      debugPrint('[HiveStorage] Error deleting interview: $e');
    }
  }

  /// Wipe all local interviews for [userId].
  static Future<void> clearInterviews(String userId) async {
    try {
      final box = await _box(userId);
      await box.clear();
      debugPrint('[HiveStorage] Cleared all interviews for user $userId.');
    } catch (e) {
      debugPrint('[HiveStorage] Error clearing interviews: $e');
    }
  }

  /// Close all open Hive boxes (optional, on app dispose).
  static Future<void> closeAll() async {
    await Hive.close();
  }
}
