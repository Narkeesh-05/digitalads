import 'dart:convert';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

// ============================================================================
// DOCUMENT TYPES
// ============================================================================

enum SellerDocumentType { fssai, gst, msme }

// ============================================================================
// RESULT MODELS
// ============================================================================

class DocumentVerificationResult {
  final bool verified;
  final String message;
  final String? legalName;

  DocumentVerificationResult({
    required this.verified,
    required this.message,
    this.legalName,
  });
}

class _GstApiResult {
  final bool success;
  final String message;
  final String? legalName;

  _GstApiResult({required this.success, required this.message, this.legalName});
}

// ============================================================================
// SERVICE
// ============================================================================

class DocumentVerificationService {
  DocumentVerificationService._();

  // TODO: Sign up free at https://appyflow.in/verify-gst/ and paste your
  // key_secret here. Free tier gives 50 GST verifications against the real
  // government database. Without this key, GST documents fall back to
  // OCR-only verification (same as FSSAI/MSME).
  static const String _appyFlowKeySecret = 'YOUR_APPYFLOW_KEY_SECRET';

  static final TextRecognizer _recognizer =
  TextRecognizer(script: TextRecognitionScript.latin);

  static final RegExp _gstRegex =
  RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

  static final RegExp _fssaiRegex = RegExp(r'^[0-9]{14}$');

  static final RegExp _msmeRegex =
  RegExp(r'^UDYAM-[A-Z]{2}-[0-9]{2}-[0-9]{7}$');

  /// Runs the full verification pipeline:
  /// 1. Format check on the entered number
  /// 2. OCR extraction from the uploaded document photo
  /// 3. Image/text quality check
  /// 4. Authority keyword check (filters out random/wrong images)
  /// 5. Number match between entered number and document text
  /// 6. For GST: cross-check against the real government database
  static Future<DocumentVerificationResult> verify({
    required File imageFile,
    required SellerDocumentType type,
    required String enteredNumber,
  }) async {
    final cleanedNumber =
    enteredNumber.trim().toUpperCase().replaceAll(' ', '');

    // ---- 1. Format check -----------------------------------------------
    final formatError = _checkFormat(type, cleanedNumber);
    if (formatError != null) {
      return DocumentVerificationResult(verified: false, message: formatError);
    }

    // ---- 2. OCR extraction ----------------------------------------------
    String extractedText;
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _recognizer.processImage(inputImage);
      extractedText = recognized.text;
    } catch (_) {
      return DocumentVerificationResult(
        verified: false,
        message: 'Could not read the document. Try a clearer, well-lit photo.',
      );
    }

    // ---- 3. Quality check -------------------------------------------------
    if (extractedText.trim().length < 25) {
      return DocumentVerificationResult(
        verified: false,
        message: 'Image is too blurry or unclear. Please re-upload a clear photo.',
      );
    }

    final normalizedText =
    extractedText.toUpperCase().replaceAll(RegExp(r'\s+'), '');

    // ---- 4. Authority keyword check ---------------------------------------
    final keywords = _keywordsFor(type);
    final hasKeyword = keywords.any((k) => normalizedText.contains(k));
    if (!hasKeyword) {
      return DocumentVerificationResult(
        verified: false,
        message: 'This does not look like a valid ${_typeLabel(type)} document.',
      );
    }

    // ---- 5. Number match ----------------------------------------------------
    if (!normalizedText.contains(cleanedNumber)) {
      return DocumentVerificationResult(
        verified: false,
        message: 'The number entered does not match the number on the document.',
      );
    }

    // ---- 6. Government database check (GST only) --------------------------
    if (type == SellerDocumentType.gst) {
      if (_appyFlowKeySecret == 'YOUR_APPYFLOW_KEY_SECRET') {
        // No API key configured yet — fall back to OCR-only verification.
        return DocumentVerificationResult(
          verified: true,
          message: 'Document verified (OCR only — add an AppyFlow key for live GST status checks).',
        );
      }

      final apiResult = await _checkGstWithGovernmentApi(cleanedNumber);
      if (!apiResult.success) {
        return DocumentVerificationResult(
          verified: false,
          message: apiResult.message,
        );
      }
      return DocumentVerificationResult(
        verified: true,
        message: 'Verified with government GST records${apiResult.legalName != null ? ' — ${apiResult.legalName}' : ''}',
        legalName: apiResult.legalName,
      );
    }

    // FSSAI / MSME: no free government API exists, OCR-based checks above
    // are the strongest verification available.
    return DocumentVerificationResult(
      verified: true,
      message: 'Document verified',
    );
  }

  static String? _checkFormat(SellerDocumentType type, String number) {
    switch (type) {
      case SellerDocumentType.gst:
        if (!_gstRegex.hasMatch(number)) return 'Invalid GST number format.';
        return null;
      case SellerDocumentType.fssai:
        if (!_fssaiRegex.hasMatch(number)) {
          return 'FSSAI license number must be 14 digits.';
        }
        return null;
      case SellerDocumentType.msme:
        if (!_msmeRegex.hasMatch(number)) {
          return 'Invalid MSME (Udyam) number format. Expected UDYAM-XX-00-0000000.';
        }
        return null;
    }
  }

  static List<String> _keywordsFor(SellerDocumentType type) {
    switch (type) {
      case SellerDocumentType.fssai:
        return ['FSSAI', 'FOODSAFETYANDSTANDARDS'];
      case SellerDocumentType.gst:
        return ['GST', 'GOODSANDSERVICESTAX', 'GSTIN'];
      case SellerDocumentType.msme:
        return ['UDYAM', 'MICROSMALLANDMEDIUM', 'MSME'];
    }
  }

  static String _typeLabel(SellerDocumentType type) {
    switch (type) {
      case SellerDocumentType.fssai:
        return 'FSSAI';
      case SellerDocumentType.gst:
        return 'GST';
      case SellerDocumentType.msme:
        return 'MSME';
    }
  }

  static Future<_GstApiResult> _checkGstWithGovernmentApi(
      String gstNumber) async {
    try {
      final uri = Uri.parse(
        'https://appyflow.in/api/verifyGST?gstNo=$gstNumber&key_secret=$_appyFlowKeySecret',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return _GstApiResult(
          success: false,
          message: 'GST verification service is unavailable right now.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['error'] == true) {
        return _GstApiResult(
          success: false,
          message: data['message']?.toString() ?? 'GST number not found in government records.',
        );
      }

      final taxpayerInfo = data['taxpayerInfo'] as Map<String, dynamic>?;
      if (taxpayerInfo == null) {
        return _GstApiResult(
          success: false,
          message: 'Could not fetch GST details for this number.',
        );
      }

      final status = taxpayerInfo['sts']?.toString() ?? '';
      final legalName = taxpayerInfo['lgnm']?.toString();

      if (status.toUpperCase() == 'ACTIVE') {
        return _GstApiResult(success: true, message: 'Active', legalName: legalName);
      }

      return _GstApiResult(
        success: false,
        message: 'GST registration status is "$status" (not active).',
      );
    } catch (_) {
      return _GstApiResult(
        success: false,
        message: 'Network error while checking GST status. Please try again.',
      );
    }
  }

  /// Call once when your app shuts down / the recognizer is no longer needed.
  static void dispose() {
    _recognizer.close();
  }
}