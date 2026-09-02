import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_avatar.dart';
import '../../../../core/errors/app_result.dart';

final class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;
  final UploadAvatar uploadAvatar;

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.uploadAvatar,
  }) : super(const ProfileState.initial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<UploadAvatarRequested>(_onUploadAvatar);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final result = await getProfile(event.uid);
    if (result is Success<UserProfile>) {
      emit(state.copyWith(status: ProfileStatus.loaded, profile: result.data));
    } else {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: (result as Failure).error.message,
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state.profile;
    if (current == null) return;

    emit(state.copyWith(status: ProfileStatus.loading));

    final updated = current.copyWith(
      displayName: event.displayName,
      username: event.username,
      country: event.country,
      language: event.language,
      bio: event.bio,
    );

    final result = await updateProfile(updated);
    if (result is Success<UserProfile>) {
      emit(state.copyWith(status: ProfileStatus.loaded, profile: result.data));
    } else {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: (result as Failure).error.message,
      ));
    }
  }

  Future<void> _onUploadAvatar(
    UploadAvatarRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final result = await uploadAvatar(uid: event.uid, filePath: event.filePath);
    if (result is Success<String>) {
      final updated = state.profile?.copyWith(photoUrl: result.data);
      if (updated != null) {
        await updateProfile(updated);
        emit(state.copyWith(status: ProfileStatus.loaded, profile: updated));
      }
    } else {
      emit(state.copyWith(
        status: ProfileStatus.error,
        errorMessage: (result as Failure).error.message,
      ));
    }
  }
}
