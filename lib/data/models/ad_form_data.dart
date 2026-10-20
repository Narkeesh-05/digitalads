import 'dart:io';

import 'package:digitalads/modules/admin/screens/product_status.dart';

/// One photo in the picker: already uploaded (network) or newly picked (local).
class AdImageItem {
  final String? url;
  final File? file;

  const AdImageItem.network(String this.url) : file = null;
  const AdImageItem.local(File this.file) : url = null;

  bool get isNetwork => url != null;
}

/// Everything the Post/Edit Ad form holds.
class AdFormData {
  final String title;
  final String description;
  final String offer;
  final String phone; // 10 digits, without +91
  final String whatsapp; // 10 digits or empty
  final String quizQuestion;
  final List<String> options; // always 4
  final int correctIndex;
  final String status;
  final List<AdImageItem> images;
  final File? video; // newly picked
  final String? existingVideoUrl; // already uploaded (edit mode)
  final Duration? videoDuration;

  const AdFormData({
    this.title = '',
    this.description = '',
    this.offer = '',
    this.phone = '',
    this.whatsapp = '',
    this.quizQuestion = '',
    this.options = const ['', '', '', ''],
    this.correctIndex = 0,
    required this.status,
    this.images = const [],
    this.video,
    this.existingVideoUrl,
    this.videoDuration,
  });

  bool get hasContent =>
      title.isNotEmpty ||
          description.isNotEmpty ||
          offer.isNotEmpty ||
          quizQuestion.isNotEmpty ||
          images.isNotEmpty ||
          video != null;

  /// Builds form data from a Firebase ad node (edit mode).
  factory AdFormData.fromMap(Map<String, dynamic> data) {
    String last10(dynamic raw) {
      final digits = (raw ?? '').toString().replaceAll(RegExp(r'\D'), '');
      return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    }

    final urls = <String>[];
    final rawImages = data['imageUrls'];
    if (rawImages is List) {
      urls.addAll(rawImages.where((e) => e != null).map((e) => e.toString()));
    } else if (rawImages is Map) {
      urls.addAll(rawImages.values.map((e) => e.toString()));
    }
    if (urls.isEmpty &&
        data['imageUrl'] != null &&
        data['imageUrl'].toString().isNotEmpty) {
      urls.add(data['imageUrl'].toString());
    }

    var question = '';
    final options = ['', '', '', ''];
    var correct = 0;
    final quiz = data['quiz'];
    if (quiz is Map) {
      question = (quiz['question'] ?? '').toString();
      final rawOptions = quiz['options'];
      final list = <String>[];
      if (rawOptions is List) {
        list.addAll(rawOptions.map((e) => (e ?? '').toString()));
      } else if (rawOptions is Map) {
        list.addAll(rawOptions.values.map((e) => (e ?? '').toString()));
      }
      for (var i = 0; i < 4 && i < list.length; i++) {
        options[i] = list[i];
      }
      final c = quiz['correctIndex'];
      if (c is int && c >= 0 && c <= 3) correct = c;
    }

    final videoUrl = (data['videoUrl'] ?? '').toString();

    return AdFormData(
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      offer: (data['offer'] ?? '').toString(),
      phone: last10(data['phone']),
      whatsapp: last10(data['whatsapp']),
      quizQuestion: question,
      options: options,
      correctIndex: correct,
      status: ProductStatus.isSold(data)
          ? ProductStatus.sold
          : ProductStatus.available,
      images: urls.map(AdImageItem.network).toList(),
      existingVideoUrl: videoUrl.isNotEmpty ? videoUrl : null,
    );
  }
}

/// Business rules for the ad form.
class AdFormValidator {
  static const int minImages = 3;
  static const int maxImages = 5;
  static const Duration maxVideoDuration = Duration(seconds: 30);

  /// Returns an error message, or null when valid.
  static String? validate(AdFormData d) {
    final phone = d.phone.trim();
    final whatsapp = d.whatsapp.trim();

    if (d.title.trim().isEmpty || d.description.trim().isEmpty) {
      return 'Please enter a title and description.';
    }
    if (phone.length != 10) {
      return 'Please enter a valid 10-digit contact number.';
    }
    if (whatsapp.isNotEmpty && whatsapp.length != 10) {
      return 'WhatsApp number must be 10 digits (or leave it empty).';
    }
    if (d.images.length < minImages) {
      return 'Please select at least $minImages images (up to $maxImages).';
    }
    if (d.images.length > maxImages) {
      return 'Please keep it to $maxImages images or fewer.';
    }
    if (d.video != null &&
        d.videoDuration != null &&
        d.videoDuration! > maxVideoDuration) {
      return 'Video must be under ${maxVideoDuration.inSeconds} seconds — please trim it first.';
    }
    return null;
  }
}