import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/errors/app_result.dart';
import '../../../../core/errors/app_error.dart';

final class SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;

  SettingsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AppResult<void>> saveSettings(String uid, Map<String, dynamic> settings) async {
    try {
      await _firestore
          .collection(FirestoreConstants.settings)
          .doc(uid)
          .set(settings, SetOptions(merge: true));
      return const Success(null);
    } catch (e) {
      return Failure(ServerError(details: 'Failed to sync settings: $e'));
    }
  }

  Future<AppResult<String>> exportData(String uid) async {
    try {
      final userDoc = await _firestore.collection(FirestoreConstants.users).doc(uid).get();
      final settingsDoc = await _firestore.collection(FirestoreConstants.settings).doc(uid).get();
      final conversationsSnapshot = await _firestore
          .collection(FirestoreConstants.conversations)
          .where(FirestoreConstants.userId, isEqualTo: uid)
          .get();

      final export = {
        'profile': userDoc.data(),
        'settings': settingsDoc.data(),
        'conversations': conversationsSnapshot.docs.map((d) => d.data()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      return Success(jsonEncode(export));
    } catch (e) {
      return Failure(ServerError(details: 'Failed to export data: $e'));
    }
  }

  Future<AppResult<void>> deleteAccountData(String uid) async {
    try {
      final batch = _firestore.batch();

      batch.delete(_firestore.collection(FirestoreConstants.users).doc(uid));
      batch.delete(_firestore.collection(FirestoreConstants.settings).doc(uid));

      final conversationsSnapshot = await _firestore
          .collection(FirestoreConstants.conversations)
          .where(FirestoreConstants.userId, isEqualTo: uid)
          .get();

      for (final doc in conversationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure(ServerError(details: 'Failed to delete account data: $e'));
    }
  }
}
