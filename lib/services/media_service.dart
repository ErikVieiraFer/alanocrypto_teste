import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAudio(dynamic audioData, String oderId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final extension = kIsWeb ? 'webm' : 'm4a';
    final contentType = kIsWeb ? 'audio/webm' : 'audio/m4a';

    final ref = _storage.ref('cupula_audio/${oderId}_$timestamp.$extension');

    if (audioData is Uint8List) {
      await ref.putData(audioData, SettableMetadata(contentType: contentType));
    } else if (audioData is File) {
      await ref.putFile(audioData, SettableMetadata(contentType: contentType));
    }

    return await ref.getDownloadURL();
  }

  Future<String> uploadVideo(dynamic videoData, String oderId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('cupula_videos/${oderId}_$timestamp.mp4');

    if (videoData is Uint8List) {
      await ref.putData(videoData, SettableMetadata(contentType: 'video/mp4'));
    } else if (videoData is File) {
      await ref.putFile(videoData, SettableMetadata(contentType: 'video/mp4'));
    }

    return await ref.getDownloadURL();
  }

  Future<String> uploadVideoFromFile(File videoFile, String oderId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('cupula_videos/${oderId}_$timestamp.mp4');
    await ref.putFile(videoFile, SettableMetadata(contentType: 'video/mp4'));
    return await ref.getDownloadURL();
  }
}
