import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _phoneController;
  Uint8ListWrapper? _pickedPhoto;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final student = ref.read(authControllerProvider).valueOrNull?.student;
    _phoneController = TextEditingController(text: student?.phone ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Only stages the picked photo locally — it is not uploaded until the
  /// user explicitly taps "Save Changes", same as the phone number field.
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();

    setState(() {
      _pickedPhoto = Uint8ListWrapper(bytes, file.name);
      _error = null;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final photo = _pickedPhoto;
      String? photoUrl;

      if (photo != null) {
        photoUrl = await ref.read(profileRepositoryProvider).uploadPhoto(bytes: photo.bytes, filename: photo.name);
      }

      final phoneResult = await ref.read(profileRepositoryProvider).updatePhone(
            _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );

      final current = ref.read(authControllerProvider).valueOrNull?.student;
      if (current != null) {
        ref.read(authControllerProvider.notifier).updateStudent(
              current.copyWith(phone: phoneResult['phone'] as String?, photoUrl: photoUrl),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
        context.pop();
      }
    } on AppFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ImageProvider? _avatarImage(String? photoUrl) {
    if (_pickedPhoto != null) return MemoryImage(_pickedPhoto!.bytes);
    if (photoUrl != null) return NetworkImage(photoUrl);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = ref.watch(authControllerProvider).valueOrNull?.student;
    final photoUrl = student?.photoUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: _avatarImage(photoUrl),
                  child: (_pickedPhoto == null && photoUrl == null)
                      ? Icon(Icons.person, size: 44, color: theme.colorScheme.onPrimaryContainer)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _saving ? null : _pickPhoto,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_pickedPhoto != null) ...[
            const SizedBox(height: 8),
            Text(
              'New photo selected — tap "Save Changes" to upload it.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 8),
          Text(
            'Your name, email, program, level and intake are managed by IST administration and cannot be changed here.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _saveChanges,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

class Uint8ListWrapper {
  const Uint8ListWrapper(this.bytes, this.name);

  final Uint8List bytes;
  final String name;
}
