import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/errors/app_result.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/constants/firestore_constants.dart';

final class ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<AppResult<UserProfile>> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection(FirestoreConstants.users).doc(uid).get();
      if (!doc.exists) {
        return Failure(const NotFoundError('Profile not found'));
      }
      final data = doc.data()!;
      data['uid'] = doc.id;
      return Success(UserProfile.fromJson(data));
    } catch (e) {
      return Failure(ServerError(details: 'Failed to load profile: $e'));
    }
  }

  Future<AppResult<UserProfile>> createProfile(UserProfile profile) async {
    try {
      final docRef = _firestore.collection(FirestoreConstants.users).doc(profile.uid);
      final existing = await docRef.get();

      if (existing.exists) {
        return Success(profile);
      }

      await docRef.set(profile.toJson());
      return Success(profile);
    } catch (e) {
      return Failure(ServerError(details: 'Failed to create profile: $e'));
    }
  }

  Future<AppResult<UserProfile>> updateProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(FirestoreConstants.users)
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));
      return Success(profile);
    } catch (e) {
      return Failure(ServerError(details: 'Failed to update profile: $e'));
    }
  }

  Future<AppResult<String>> uploadAvatar({
    required String uid,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref().child('avatars/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return Success(url);
    } catch (e) {
      return Failure(ServerError(details: 'Failed to upload avatar: $e'));
    }
  }
}
