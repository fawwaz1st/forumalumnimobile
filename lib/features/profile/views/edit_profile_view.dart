import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/providers/auth_controller.dart';
import '../../posts/data/posts_repository.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  String? _avatarUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authControllerProvider).valueOrNull;
    if (u != null) {
      _name.text = u.name;
      _bio.text = u.bio ?? '';
      _avatarUrl = u.avatar;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    await _upload(bytes);
  }

  Future<void> _upload(Uint8List bytes) async {
    setState(() => _saving = true);
    try {
      final url = await ref.read(postsRepositoryProvider).uploadImageBytes(bytes, fileName: 'avatar.jpg');
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      ref.read(authControllerProvider.notifier).updateProfile(
            name: _name.text.trim(),
            avatar: _avatarUrl,
            bio: _bio.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty ? NetworkImage(_avatarUrl!) : null,
                  child: (_avatarUrl == null || _avatarUrl!.isEmpty) ? const Icon(Icons.person, size: 48) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton.filledTonal(onPressed: _pickAvatar, icon: const Icon(Icons.camera_alt_outlined)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
