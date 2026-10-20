import 'dart:convert';
import 'dart:io';

import 'package:digitalads/data/models/ad_form_data.dart';
import 'package:digitalads/modules/admin/screens/product_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdDraftRepository {
  final FirebaseAuth _auth;

  AdDraftRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  String get _key => 'post_ad_draft_${_auth.currentUser?.uid ?? 'guest'}';

  Future<void> save(AdFormData d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final o = d.options;

      await prefs.setString(
        _key,
        jsonEncode({
          'title': d.title,
          'description': d.description,
          'offer': d.offer,
          'phone': d.phone,
          'whatsapp': d.whatsapp,
          'quizQuestion': d.quizQuestion,
          'option1': o[0],
          'option2': o[1],
          'option3': o[2],
          'option4': o[3],
          'correctAnswerIndex': d.correctIndex,
          'imagePaths': d.images
              .where((i) => i.file != null)
              .map((i) => i.file!.path)
              .toList(),
          'videoPath': d.video?.path,
          'savedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Draft save error: $e');
    }
  }

  /// Returns null when there is no (useful) draft.
  Future<AdFormData?> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == null || saved.isEmpty) return null;

      final m = jsonDecode(saved) as Map<String, dynamic>;
      String s(String k) => (m[k] ?? '').toString();

      final images = <AdImageItem>[];
      final paths = m['imagePaths'];
      if (paths is List) {
        for (final p in paths) {
          final f = File(p.toString());
          if (await f.exists()) images.add(AdImageItem.local(f));
        }
      }

      File? video;
      final vp = m['videoPath'];
      if (vp != null && vp.toString().isNotEmpty) {
        final f = File(vp.toString());
        if (await f.exists()) video = f;
      }

      var correct = 0;
      final c = m['correctAnswerIndex'];
      if (c is int && c >= 0 && c <= 3) correct = c;

      final data = AdFormData(
        title: s('title'),
        description: s('description'),
        offer: s('offer'),
        phone: s('phone'),
        whatsapp: s('whatsapp'),
        quizQuestion: s('quizQuestion'),
        options: [s('option1'), s('option2'), s('option3'), s('option4')],
        correctIndex: correct,
        status: ProductStatus.available,
        images: images,
        video: video,
      );

      return data.hasContent ? data : null;
    } catch (e) {
      debugPrint('Draft restore error: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('Draft clear error: $e');
    }
  }
}