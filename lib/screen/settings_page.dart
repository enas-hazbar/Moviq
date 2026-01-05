import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/auth_service.dart';
import '../widgets/moviq_scaffold.dart';
import 'splash_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  File? _profileImage;
  bool _isPicking = false;
  bool _isSaving = false;

  String? _email;
  String? _username;
  String? _photoUrl;

  static const Color _pink = Color(0xFFE5A3A3);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return MoviqScaffold(
      currentTopTab: MoviqTopTab.films,
      currentBottomTab: MoviqBottomTab.profile,
      showTopNav: false,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfileImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _UploadPhotoRow(
              isPicking: _isPicking,
              imageFile: _profileImage,
              imageUrl: _photoUrl,
              onPick: _pickImage,
            ),
            const SizedBox(height: 24),
            _InfoPanel(email: _email, username: _username, pink: _pink),
            const Spacer(),
            Center(
              child: IconButton(
                onPressed: () async {
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 36),
                tooltip: 'Logout',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _profileImage = File(picked.path));
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    print('AUTH UID: ${user?.uid}');

    if (user == null) return;

    final email = user.email ?? '';
    final fallbackUsername =
        (email.isNotEmpty && email.contains('@')) ? email.split('@').first : null;

    Map<String, dynamic>? data;
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      data = userDoc.data();
    } catch (_) {
      data = null;
    }

    if (!mounted) return;

    setState(() {
      _email = email;

      final storedUsername = data?['username'] as String?;
      _username = (storedUsername != null && storedUsername.isNotEmpty)
          ? storedUsername
          : fallbackUsername;

      _photoUrl = data?['photoUrl'] as String? ?? user.photoURL;
    });
  }

Future<void> _saveProfileImage() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  if (_profileImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pick a photo first')),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
final storage = FirebaseStorage.instanceFor(
  bucket: 'gs://moviq-1cbf7.firebasestorage.app',
);

final fileName = DateTime.now().millisecondsSinceEpoch;
final ref = storage.ref('profile_photos/${user.uid}/avatar_$fileName.jpg');

print('USING BUCKET: ${storage.app.options.storageBucket}');
print('UPLOAD PATH: ${ref.fullPath}');

final task = ref.putFile(
  _profileImage!,
  SettableMetadata(contentType: 'image/jpeg'),
);

await task;
final url = await ref.getDownloadURL();

    // Update Firebase Auth
    await user.updatePhotoURL(url);
    await user.reload();

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => _photoUrl = url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo saved')),
    );
  } on FirebaseException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Firebase error: ${e.code}')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}
}

class _UploadPhotoRow extends StatelessWidget {
  const _UploadPhotoRow({
    required this.onPick,
    required this.imageFile,
    required this.imageUrl,
    required this.isPicking,
  });

  final Future<void> Function() onPick;
  final File? imageFile;
  final String? imageUrl;
  final bool isPicking;

  @override
  Widget build(BuildContext context) {
    final avatarChild = (imageFile != null || imageUrl != null)
        ? null
        : const Icon(Icons.person, color: Colors.white, size: 28);

    final ImageProvider? imageProvider = imageFile != null
        ? FileImage(imageFile!)
        : (imageUrl != null ? NetworkImage(imageUrl!) : null);

    return InkWell(
      onTap: isPicking ? null : onPick,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 23,
              backgroundColor: Colors.black,
              backgroundImage: imageProvider,
              child: avatarChild,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isPicking ? 'Uploading...' : 'Upload a photo',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.email,
    required this.username,
    required this.pink,
  });

  final String? email;
  final String? username;
  final Color pink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pink.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('E-mail', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 6),
          Text(email ?? '-', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Divider(color: Colors.white, height: 20),
          const Text('Username', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 6),
          Text(username ?? '-', style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}