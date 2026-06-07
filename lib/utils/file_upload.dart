import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> uploadToStorage(XFile file) async {
  try {
    final Uint8List bytes = await file.readAsBytes();
    final extension = file.name.split('.').last;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';

    await Supabase.instance.client.storage
        .from('HMS_images')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        );

    return Supabase.instance.client.storage
        .from('HMS_images')
        .getPublicUrl(fileName);
  } catch (e) {
    debugPrint('Upload error: $e');
    return null;
  }
}

Future<void> deleteFromStorage(String publicUrl) async {
  try {
    final fileName = publicUrl.split('/').last;

    await Supabase.instance.client.storage.from('HMS_images').remove([
      fileName,
    ]);

    debugPrint('Deleted: $fileName');
  } catch (e) {
    debugPrint('Delete error: $e');
  }
}
