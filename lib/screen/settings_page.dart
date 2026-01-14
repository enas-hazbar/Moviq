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
  bool _isSavingUsername = false;

  String? _email;
  String? _username;
  String? _photoUrl;

  final TextEditingController _usernameController = TextEditingController();

  /// 🔒 prevents StreamBuilder / fallback overwrites
  bool _usernameInitialized = false;

  static const Color _pink = Color(0xFFE5A3A3);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
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

            /// PROFILE PHOTO
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snap) {
                final photoUrl = snap.data?.data()?['photoUrl'];

                return _UploadPhotoRow(
                  isPicking: _isPicking,
                  imageFile: _profileImage,
                  imageUrl: photoUrl,
                  onPick: _pickImage,
                );
              },
            ),

            const SizedBox(height: 24),

            /// INFO PANEL (EMAIL + USERNAME)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final username = data?['username'];

                /// ✅ initialize ONCE, never overwrite
                if (!_usernameInitialized && username != null) {
                  _usernameController.text = username;
                  _usernameInitialized = true;
                }

                return _InfoPanel(
                  email: FirebaseAuth.instance.currentUser?.email,
                  usernameController: _usernameController,
                  onSaveUsername: _isSavingUsername ? null : _saveUsername,
                  pink: _pink,
                  isSaving: _isSavingUsername,
                );
              },
            ),

            /// LOGOUT
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

  // =========================
  // IMAGE PICKING
  // =========================

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

  // =========================
  // LOAD USER
  // =========================

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email ?? '';
    final fallbackUsername =
        (email.isNotEmpty && email.contains('@')) ? email.split('@').first : null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (!mounted) return;

    setState(() {
      _email = email;

      final storedUsername = data?['username'];
      if (storedUsername != null && storedUsername.isNotEmpty) {
        _username = storedUsername;
      } else if (!_usernameInitialized && fallbackUsername != null) {
        _username = fallbackUsername;
      }

      _photoUrl = data?['photoUrl'] ?? user.photoURL;
      if (!_usernameInitialized && _username != null) {
        _usernameController.text = _username!;
        _usernameInitialized = true;
      }
    });
  }

  // =========================
  // SAVE PROFILE IMAGE
  // =========================

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
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final fileName = DateTime.now().millisecondsSinceEpoch;
      final path = 'profile_photos/${user.uid}/avatar_$fileName.jpg';
      final url = await _uploadWithFallback(path, _profileImage!);
      await user.updatePhotoURL(url);
      updates['photoUrl'] = url;
      _photoUrl = url;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updates, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String> _uploadWithFallback(String path, File file) async {
    try {
      return await _uploadToBucket(FirebaseStorage.instance, path, file);
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found' && e.code != 'bucket-not-found') {
        rethrow;
      }
      final fallbackStorage = FirebaseStorage.instanceFor(
        bucket: 'gs://moviq-1cbf7.firebasestorage.app',
      );
      return await _uploadToBucket(fallbackStorage, path, file);
    }
  }

  Future<String> _uploadToBucket(
    FirebaseStorage storage,
    String path,
    File file,
  ) async {
    final ref = storage.ref(path);
    final snapshot = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return snapshot.ref.getDownloadURL();
  }

  // =========================
  // SAVE USERNAME
  // =========================

  Future<void> _saveUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newUsername = _usernameController.text.trim().toLowerCase();
    final valid = RegExp(r'^[a-z0-9_]{3,15}$');

    if (!valid.hasMatch(newUsername)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username')),
      );
      return;
    }

    setState(() => _isSavingUsername = true);

    final db = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(user.uid);
    final usernameRef = db.collection('usernames').doc(newUsername);

    try {
      await db.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final oldUsername = userSnap.data()?['username'] as String?;

        // Get the new username doc
        final snap = await tx.get(usernameRef);
        final existingUid = snap.data()?['uid'] as String?;

        // Check if the new username is taken by someone else
        if (snap.exists && existingUid != null && existingUid != user.uid) {
          throw Exception('TAKEN');
        }

        // Delete the old username doc if it exists and is different
        if (oldUsername != null && oldUsername != newUsername) {
          final oldRef = db.collection('usernames').doc(oldUsername);
          tx.delete(oldRef);
        }

        // Set the new username doc
        tx.set(usernameRef, {'uid': user.uid});

        // Update user profile
        tx.set(userRef, {'username': newUsername}, SetOptions(merge: true));
      });

      setState(() {
        _username = newUsername;
        _usernameInitialized = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username already taken')),
      );
    } finally {
      if (mounted) setState(() => _isSavingUsername = false);
    }
  }

}

// =======================================================
// WIDGETS (UNCHANGED)
// =======================================================

class _UploadPhotoRow extends StatelessWidget {
  const _UploadPhotoRow({
    required this.onPick,
    required this.imageFile,
    required this.imageUrl,
    required this.isPicking,
    super.key,
  });

  final Future<void> Function() onPick;
  final File? imageFile;
  final String? imageUrl;
  final bool isPicking;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? imageProvider = imageFile != null
        ? FileImage(imageFile!)
        : (imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage('$imageUrl?v=${DateTime.now().millisecondsSinceEpoch}')
            : null);

    return InkWell(
      onTap: isPicking ? null : onPick,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 23,
              backgroundImage: imageProvider,
              backgroundColor: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isPicking ? 'Uploading...' : 'Upload a photo',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.email,
    required this.usernameController,
    required this.onSaveUsername,
    required this.pink,
    required this.isSaving,
    super.key,
  });

  final String? email;
  final TextEditingController usernameController;
  final VoidCallback? onSaveUsername;
  final Color pink;
  final bool isSaving;

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
          const Text('E-mail', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 6),
          Text(email ?? '-', style: const TextStyle(color: Colors.white)),
          const Divider(color: Colors.white, height: 20),
          const Text('Username', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 6),
          TextField(
            controller: usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'username',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onSaveUsername,
            child: Text(isSaving ? 'Saving...' : 'Save username'),
          ),
        ],
      ),
    );
  }
}
