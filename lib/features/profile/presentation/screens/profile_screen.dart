import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../domain/entities/user_profile.dart';

final class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  String _country = 'Nigeria';
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _populateFromProfile(UserProfile profile) {
    _nameController.text = profile.displayName;
    _usernameController.text = profile.username;
    _bioController.text = profile.bio ?? '';
    _country = profile.country;
    _language = profile.language;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (!mounted) return;
    if (image == null) return;
    final state = context.read<ProfileBloc>().state;
    final uid = state.profile?.uid;
    if (uid == null) return;
    context.read<ProfileBloc>().add(UploadAvatarRequested(uid: uid, filePath: image.path));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(UpdateProfileRequested(
          displayName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          country: _country,
          language: _language,
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.loaded && state.profile != null) {
          _populateFromProfile(state.profile!);
        }
        if (state.status == ProfileStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ProfileStatus.loading && state.profile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state.profile != null && _nameController.text.isEmpty) {
          _populateFromProfile(state.profile!);
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Profile'), centerTitle: false),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          backgroundImage: state.profile?.photoUrl != null
                              ? NetworkImage(state.profile!.photoUrl!)
                              : null,
                          child: state.profile?.photoUrl == null
                              ? Icon(Icons.person, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                    decoration: _inputDecoration('Display Name', Icons.person_outline),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _usernameController,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Username is required';
                      if (v.trim().length < 3) return 'Username must be at least 3 characters';
                      return null;
                    },
                    decoration: _inputDecoration('Username', Icons.alternate_email),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: _inputDecoration('Bio', Icons.info_outline),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _country,
                    decoration: _inputDecoration('Country', Icons.public),
                    items: ['Nigeria', 'Ghana', 'Kenya', 'South Africa', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _country = v ?? 'Nigeria'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _language,
                    decoration: _inputDecoration('Language', Icons.language),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'ha', child: Text('Hausa')),
                      DropdownMenuItem(value: 'yo', child: Text('Yoruba')),
                      DropdownMenuItem(value: 'ig', child: Text('Igbo')),
                    ],
                    onChanged: (v) => setState(() => _language = v ?? 'en'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: state.status == ProfileStatus.loading ? null : _save,
                      child: state.status == ProfileStatus.loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
    );
  }
}
