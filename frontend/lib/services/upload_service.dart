import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class UploadService {
  static final SupabaseClient _client = SupabaseService.instance.client;
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from the gallery
  static Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images from the gallery
  static Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1000,
      );
      return images;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Upload multiple images to Supabase Storage
  static Future<List<String>> uploadImages({
    required List<XFile> xFiles,
    required String bucket,
    required String userId,
    String? folderPrefix,
  }) async {
    final List<String> urls = [];
    for (int i = 0; i < xFiles.length; i++) {
        final String name = '${folderPrefix ?? "img"}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await uploadImage(
            xFile: xFiles[i],
            bucket: bucket,
            userId: userId,
            fileName: name,
        );
        if (url != null) urls.add(url);
    }
    return urls;
  }

  /// Upload an image to Supabase Storage
  static Future<String?> uploadImage({
    required XFile xFile,
    required String bucket,
    required String userId,
    String? fileName,
  }) async {
    try {
      final bytes = await xFile.readAsBytes();
      final name = fileName ?? 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = '$userId/$name';

      // Upload file as bytes (supports Web, Windows, Android, iOS)
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Get public URL
      final String publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      debugPrint('✅ Upload successful: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('❌ Supabase Storage Error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected Upload Error: $e');
      return null;
    }
  }

  /// Delete an image from Supabase Storage
  static Future<bool> deleteImage({
    required String bucket,
    required String path,
  }) async {
    try {
      // Extract the relative path if a full URL was provided
      String relativePath = path;
      if (path.contains('/public/')) {
        relativePath = path.split('/public/').last.split('/').skip(1).join('/');
      }

      await _client.storage.from(bucket).remove([relativePath]);
      debugPrint('✅ Deleted: $relativePath');
      return true;
    } catch (e) {
      debugPrint('❌ Delete Error: $e');
      return false;
    }
  }
}
