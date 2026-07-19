import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class MediaService {
  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndStoreImage({
    required String moveId,
    required String entityType,
    required String entityId,
    required ImageSource source,
  }) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) {
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return image.path;
    }

    final extension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';
    final reference = FirebaseStorage.instance.ref().child(
          'moves/$moveId/$entityType/$entityId/${DateTime.now().millisecondsSinceEpoch}.$extension',
        );
    try {
      await reference.putFile(
        File(image.path),
        SettableMetadata(
          contentType: extension == 'jpg' ? 'image/jpeg' : 'image/$extension',
        ),
      );
      return reference.getDownloadURL();
    } on FirebaseException {
      return image.path;
    }
  }
}

final mediaServiceProvider = Provider<MediaService>((ref) => MediaService());
