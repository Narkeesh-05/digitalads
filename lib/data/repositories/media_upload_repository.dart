import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:digitalads/data/models/ad_form_data.dart';

class MediaUploadRepository {
  final CloudinaryPublic _cloudinary;

  MediaUploadRepository({CloudinaryPublic? cloudinary})
      : _cloudinary = cloudinary ??
      CloudinaryPublic('dqs6gmhsp', 'digitalads', cache: false);

  /// Keeps already-uploaded images, uploads only the new ones.
  Future<List<String>> resolveImages(List<AdImageItem> items) {
    return Future.wait(
      items.map((item) async {
        if (item.isNetwork) return item.url!;

        final res = await _cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            item.file!.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        return res.secureUrl;
      }),
    );
  }

  /// New video -> upload. No new video -> keep existing url (or null).
  Future<String?> resolveVideo({File? newVideo, String? existingUrl}) async {
    if (newVideo == null) return existingUrl;

    final res = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        newVideo.path,
        resourceType: CloudinaryResourceType.Video,
      ),
    );
    return res.secureUrl;
  }
}