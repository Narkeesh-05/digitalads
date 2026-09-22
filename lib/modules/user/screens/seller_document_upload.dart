import 'dart:io';

import 'package:digitalads/modules/user/screens/seller_document_verification.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../services/cloudinary_service.dart';

// ============================================================================
// RESULT PASSED BACK TO THE PARENT SCREEN ONCE VERIFIED
// ============================================================================

class SellerDocumentResult {
  final String documentUrl;
  final String documentNumber;
  final SellerDocumentType documentType;
  final String? legalName;

  SellerDocumentResult({
    required this.documentUrl,
    required this.documentNumber,
    required this.documentType,
    this.legalName,
  });
}

// ============================================================================
// WIDGET
// ============================================================================

/// Shows an FSSAI upload flow for food/restaurant categories, or a GST/MSME
/// choice for every other category. Calls [onVerified] with a
/// [SellerDocumentResult] once the document passes verification, or null
/// whenever the verified state is cleared (new photo picked, type changed).
class SellerDocumentUpload extends StatefulWidget {
  final String? category;
  final bool isDark;
  final ValueChanged<SellerDocumentResult?> onVerified;

  const SellerDocumentUpload({
    super.key,
    required this.category,
    required this.isDark,
    required this.onVerified,
  });

  @override
  State<SellerDocumentUpload> createState() => _SellerDocumentUploadState();
}

class _SellerDocumentUploadState extends State<SellerDocumentUpload> {
  static const List<String> _foodCategories = [
    'Restaurant & Food',
    'Bakery & Sweets',
  ];

  SellerDocumentType _docType = SellerDocumentType.gst;
  File? _pickedImage;
  final _numberController = TextEditingController();

  bool _verifying = false;
  bool _verified = false;
  String? _statusMessage;
  bool _statusIsError = false;

  bool get _isFoodCategory =>
      widget.category != null && _foodCategories.contains(widget.category);

  @override
  void initState() {
    super.initState();
    if (_isFoodCategory) _docType = SellerDocumentType.fssai;
  }

  @override
  void didUpdateWidget(covariant SellerDocumentUpload oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category == widget.category) return;

    final wasFood = oldWidget.category != null &&
        _foodCategories.contains(oldWidget.category);

    if (_isFoodCategory == wasFood) return;

    // didUpdateWidget runs while the parent is still mid-build (it just
    // called setState to change the category), so calling setState here
    // — and widget.onVerified(), which setState()s the parent again —
    // must be deferred to after this frame finishes, or Flutter throws
    // "setState() or markNeedsBuild() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _docType = _isFoodCategory
            ? SellerDocumentType.fssai
            : SellerDocumentType.gst;
        _resetVerification();
      });
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _resetVerification() {
    _pickedImage = null;
    _numberController.clear();
    _verified = false;
    _statusMessage = null;
    widget.onVerified(null);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _verified = false;
      _statusMessage = null;
    });
    widget.onVerified(null);
  }

  Future<void> _verifyDocument() async {
    if (_pickedImage == null) {
      setState(() {
        _statusMessage = 'Please upload the document photo first.';
        _statusIsError = true;
      });
      return;
    }
    if (_numberController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Please enter the document number.';
        _statusIsError = true;
      });
      return;
    }

    setState(() {
      _verifying = true;
      _statusMessage = null;
    });

    final result = await DocumentVerificationService.verify(
      imageFile: _pickedImage!,
      type: _docType,
      enteredNumber: _numberController.text,
    );

    if (!result.verified) {
      setState(() {
        _verifying = false;
        _verified = false;
        _statusMessage = result.message;
        _statusIsError = true;
      });
      widget.onVerified(null);
      return;
    }

    // Only upload to Cloudinary once the document has passed verification.
    final url = await CloudinaryService.uploadImage(_pickedImage!);

    if (url == null) {
      setState(() {
        _verifying = false;
        _verified = false;
        _statusMessage = 'Verified, but the upload failed. Please try again.';
        _statusIsError = true;
      });
      widget.onVerified(null);
      return;
    }

    setState(() {
      _verifying = false;
      _verified = true;
      _statusMessage = result.message;
      _statusIsError = false;
    });

    widget.onVerified(
      SellerDocumentResult(
        documentUrl: url,
        documentNumber: _numberController.text.trim().toUpperCase(),
        documentType: _docType,
        legalName: result.legalName,
      ),
    );
  }

  void _changeDocument() => setState(_resetVerification);

  String _typeLabel(SellerDocumentType type) {
    switch (type) {
      case SellerDocumentType.fssai:
        return 'FSSAI License';
      case SellerDocumentType.gst:
        return 'GST Certificate';
      case SellerDocumentType.msme:
        return 'MSME (Udyam) Certificate';
    }
  }

  String _numberHint(SellerDocumentType type) {
    switch (type) {
      case SellerDocumentType.fssai:
        return 'e.g. 12345678901234';
      case SellerDocumentType.gst:
        return 'e.g. 22AAAAA0000A1Z5';
      case SellerDocumentType.msme:
        return 'e.g. UDYAM-KL-01-0000123';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E212B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(.06) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .15 : .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'BUSINESS DOCUMENT VERIFICATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color:
                  isDark ? Colors.grey.shade400 : AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isFoodCategory)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Food & restaurant businesses must upload their FSSAI license.',
                style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _typeChip(
                    label: 'GST',
                    selected: _docType == SellerDocumentType.gst,
                    isDark: isDark,
                    onTap: () {
                      if (_verified || _verifying) return;
                      setState(() {
                        _docType = SellerDocumentType.gst;
                        _resetVerification();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _typeChip(
                    label: 'MSME',
                    selected: _docType == SellerDocumentType.msme,
                    isDark: isDark,
                    onTap: () {
                      if (_verified || _verifying) return;
                      setState(() {
                        _docType = SellerDocumentType.msme;
                        _resetVerification();
                      });
                    },
                  ),
                ),
              ],
            ),

          const SizedBox(height: 14),

          TextField(
            controller: _numberController,
            enabled: !_verified && !_verifying,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: '${_typeLabel(_docType)} number',
              hintText: _numberHint(_docType),
              filled: true,
              fillColor:
              isDark ? const Color(0xFF252936) : const Color(0xFFF4F5F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (_pickedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _pickedImage!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (!_verified)
            OutlinedButton.icon(
              onPressed: _verifying ? null : _pickImage,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(_pickedImage == null
                  ? Icons.upload_file_rounded
                  : Icons.refresh_rounded),
              label: Text(_pickedImage == null
                  ? 'Upload ${_typeLabel(_docType)} photo'
                  : 'Change photo'),
            ),

          const SizedBox(height: 10),

          if (_verified)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                const Color(0xFF1D9E75).withOpacity(isDark ? .18 : .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF1D9E75), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document Verified',
                          style: TextStyle(
                            color: Color(0xFF1D9E75),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (_statusMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _statusMessage!,
                              style: const TextStyle(
                                color: Color(0xFF1D9E75),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _changeDocument,
                    child: const Text('Change'),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verifyDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  AppColors.primary.withOpacity(.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _verifying
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text('Verify Document'),
              ),
            ),

          if (_statusMessage != null && _statusIsError) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? const Color(0xFF252936) : const Color(0xFFF4F5F9)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}