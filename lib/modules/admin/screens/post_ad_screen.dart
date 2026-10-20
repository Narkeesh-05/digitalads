import 'dart:io';

import 'package:digitalads/data/models/ad_form_data.dart';
import 'package:digitalads/data/repositories/ad_draft_repository.dart';
import 'package:digitalads/data/repositories/ad_repository.dart';
import 'package:digitalads/data/repositories/media_upload_repository.dart';
import 'package:digitalads/data/services/location_service.dart';
import 'package:digitalads/modules/admin/screens/product_status.dart';
import 'package:digitalads/modules/admin/screens/video_trim_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:digitalads/data/models/ad_form_data.dart';
import '../../../app/theme.dart';
import 'bloc/ad_form/ad_form_bloc.dart';
import 'bloc/ad_form/ad_form_event.dart';
import 'bloc/ad_form/ad_form_state.dart';

/// Post a new ad, or edit an existing one when [adId] is given.
class PostAdScreen extends StatelessWidget {
  final String? adId;

  const PostAdScreen({super.key, this.adId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => AdFormBloc(
        adId: adId,
        ads: ctx.read<AdRepository>(),
        media: ctx.read<MediaUploadRepository>(),
        drafts: ctx.read<AdDraftRepository>(),
        location: ctx.read<LocationService>(),
      )..add(AdFormStarted()),
      child: _PostAdView(adId: adId),
    );
  }
}

class _PostAdView extends StatefulWidget {
  final String? adId;

  const _PostAdView({this.adId});

  @override
  State<_PostAdView> createState() => _PostAdViewState();
}

class _PostAdViewState extends State<_PostAdView> {
  // Business rules live in AdFormValidator; aliases keep the UI code short.
  static const int _minImages = AdFormValidator.minImages;
  static const int _maxImages = AdFormValidator.maxImages;
  static const Duration _maxVideoDuration = AdFormValidator.maxVideoDuration;

  bool get _isEdit => widget.adId != null;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _offerController = TextEditingController();

  final _quizQuestionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  int _correctAnswerIndex = 0;
  String _status = ProductStatus.available;

  List<AdImageItem> _images = [];
  File? _selectedVideo; // newly picked video
  String? _existingVideoUrl; // already uploaded video (edit mode)
  VideoPlayerController? _videoController;
  Duration? _videoDuration;

  bool _isProcessingVideo = false;
  bool _applyingData = false;

  bool get _hasVideo => _selectedVideo != null || _existingVideoUrl != null;

  List<TextEditingController> get _controllers => [
    _titleController,
    _descriptionController,
    _offerController,
    _phoneController,
    _whatsappController,
    _quizQuestionController,
    _option1Controller,
    _option2Controller,
    _option3Controller,
    _option4Controller,
  ];

  // ============================================================
  // UI STATE  <->  BLOC DATA
  // ============================================================

  /// Reads the form and packs it for the bloc.
  AdFormData _collect() => AdFormData(
    title: _titleController.text,
    description: _descriptionController.text,
    offer: _offerController.text,
    phone: _phoneController.text.trim(),
    whatsapp: _whatsappController.text.trim(),
    quizQuestion: _quizQuestionController.text,
    options: [
      _option1Controller.text,
      _option2Controller.text,
      _option3Controller.text,
      _option4Controller.text,
    ],
    correctIndex: _correctAnswerIndex,
    status: _status,
    images: List.of(_images),
    video: _selectedVideo,
    existingVideoUrl: _existingVideoUrl,
    videoDuration: _videoDuration,
  );

  /// Fills the form (edit load / draft restore).
  Future<void> _applyData(AdFormData d) async {
    _applyingData = true;
    _titleController.text = d.title;
    _descriptionController.text = d.description;
    _offerController.text = d.offer;
    _phoneController.text = d.phone;
    _whatsappController.text = d.whatsapp;
    _quizQuestionController.text = d.quizQuestion;
    _option1Controller.text = d.options[0];
    _option2Controller.text = d.options[1];
    _option3Controller.text = d.options[2];
    _option4Controller.text = d.options[3];
    _correctAnswerIndex = d.correctIndex;
    _status = d.status;
    _images = List.of(d.images);
    _selectedVideo = d.video;
    _existingVideoUrl = d.existingVideoUrl;
    _applyingData = false;

    await _initVideoPreview();
    if (mounted) setState(() {});
  }

  Future<void> _initVideoPreview() async {
    VideoPlayerController? c;
    try {
      if (_selectedVideo != null) {
        c = VideoPlayerController.file(_selectedVideo!);
      } else if (_existingVideoUrl != null) {
        c = VideoPlayerController.networkUrl(Uri.parse(_existingVideoUrl!));
      }
      await c?.initialize();
    } catch (e) {
      debugPrint('Video preview failed: $e');
      await c?.dispose();
      c = null;
    }

    if (!mounted) {
      await c?.dispose();
      return;
    }

    final old = _videoController;
    _videoController = c;
    _videoDuration = c?.value.duration;
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  /// Draft auto-save (new ads only). The bloc debounces it.
  void _scheduleDraftSave() {
    if (_isEdit || _applyingData) return;
    context.read<AdFormBloc>().add(DraftChanged(_collect()));
  }

  void _submit() => context.read<AdFormBloc>().add(SubmitAd(_collect()));

  void _onBlocState(BuildContext context, AdFormState state) {
    if (state is AdFormLoaded) {
      _applyData(state.data);
      if (state.fromDraft) {
        _showSnackBar(
          'Your previous ad details have been restored.',
          isError: false,
        );
      }
    } else if (state is AdFormLoadFailed) {
      _showSnackBar(state.message, isError: true);
      Navigator.pop(context);
    } else if (state is AdFormFailure) {
      _showSnackBar(state.message, isError: true);
    } else if (state is AdFormSuccess) {
      _showSnackBar(
        state.isEdit ? 'Ad Updated Successfully!' : 'Ad Posted Successfully!',
        isError: false,
      );
      Navigator.pop(context, true);
    }
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_scheduleDraftSave);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(_scheduleDraftSave);
      c.dispose();
    }
    _videoController?.dispose();
    super.dispose();
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();

      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 90,
      );

      if (pickedFiles.isEmpty) return;

      var files = pickedFiles.map((e) => File(e.path)).toList();

      if (files.length > _maxImages) {
        files = files.take(_maxImages).toList();
        _showSnackBar(
          'You can upload up to $_maxImages images — the first $_maxImages were kept.',
          isError: true,
        );
      }

      setState(() {
        _images = files.map(AdImageItem.local).toList();
      });
      _scheduleDraftSave();
    } catch (e) {
      _showSnackBar(
        'Unable to select images',
        isError: true,
      );
    }
  }

  Future<void> _addMoreImages() async {
    if (_images.length >= _maxImages) {
      _showSnackBar(
        'You\'ve already selected the maximum of $_maxImages images.',
        isError: true,
      );
      return;
    }

    try {
      final picker = ImagePicker();

      final remainingSlots = _maxImages - _images.length;

      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 90,
      );

      if (pickedFiles.isEmpty) return;

      var newFiles = pickedFiles.map((e) => File(e.path)).toList();

      if (newFiles.length > remainingSlots) {
        newFiles = newFiles.take(remainingSlots).toList();

        _showSnackBar(
          'Only $remainingSlots more image${remainingSlots == 1 ? '' : 's'} could be added.',
          isError: true,
        );
      }

      setState(() {
        _images = [
          ..._images,
          ...newFiles.map(AdImageItem.local),
        ];
      });

      _scheduleDraftSave();
    } catch (e) {
      _showSnackBar(
        'Unable to select images',
        isError: true,
      );
    }
  }

  /// Downloads an already-uploaded image so it can be cropped again.
  Future<File> _downloadToTemp(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      final file = File(
        '${Directory.systemTemp.path}/edit_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);
      return file;
    } finally {
      client.close();
    }
  }

  /// Opens a native crop UI for one image, before upload.
  Future<void> _editImage(int index) async {
    try {
      final item = _images[index];

      final String sourcePath;
      if (item.isNetwork) {
        final downloaded = await _downloadToTemp(item.url!);
        sourcePath = downloaded.path;
      } else {
        sourcePath = item.file!.path;
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Edit Image',
          ),
        ],
      );

      if (cropped == null) return;
      if (!mounted || index >= _images.length) return;

      setState(() {
        _images[index] = AdImageItem.local(File(cropped.path));
      });

      _scheduleDraftSave();
    } catch (e) {
      _showSnackBar('Unable to edit image', isError: true);
    }
  }

  // ============================================================
  // VIDEO PICKER
  // ============================================================

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      setState(() => _isProcessingVideo = true);

      var videoFile = File(pickedFile.path);

      var controller = VideoPlayerController.file(videoFile);
      await controller.initialize();

      final duration = controller.value.duration;

      // Video is longer than the limit — send it straight to the trim
      // screen (same idea as WhatsApp cutting a status video before
      // posting) instead of silently rejecting it.
      if (duration > _maxVideoDuration) {
        await controller.dispose();

        if (!mounted) return;

        final trimmedFile = await Navigator.push<File?>(
          context,
          MaterialPageRoute(
            builder: (_) => VideoTrimScreen(
              videoFile: videoFile,
              maxDuration: _maxVideoDuration,
            ),
          ),
        );

        if (trimmedFile == null) {
          // User backed out of trimming — keep whatever video was there.
          if (mounted) setState(() => _isProcessingVideo = false);
          return;
        }

        videoFile = trimmedFile;
        controller = VideoPlayerController.file(videoFile);
        await controller.initialize();
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final oldController = _videoController;

      setState(() {
        _selectedVideo = videoFile;
        _existingVideoUrl = null;
        _videoController = controller;
        _videoDuration = controller.value.duration;
        _isProcessingVideo = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController?.dispose();
      });

      _scheduleDraftSave();
    } catch (e) {
      if (mounted) setState(() => _isProcessingVideo = false);
      _showSnackBar(
        'Unable to select video',
        isError: true,
      );
    }
  }

  /// Lets the user re-trim a newly picked video (e.g. to shorten it
  /// further, not just to get it under the limit).
  Future<void> _trimExistingVideo() async {
    if (_selectedVideo == null) return;

    final trimmedFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => VideoTrimScreen(
          videoFile: _selectedVideo!,
          maxDuration: _maxVideoDuration,
        ),
      ),
    );

    if (trimmedFile == null) return;

    final oldController = _videoController;
    final controller = VideoPlayerController.file(trimmedFile);
    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _selectedVideo = trimmedFile;
      _videoController = controller;
      _videoDuration = controller.value.duration;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController?.dispose();
    });

    _scheduleDraftSave();
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : const Color(0xFF1D9E75),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // FIELD DECORATION
  // ============================================================

  InputDecoration _fieldDeco(
      BuildContext context,
      String label,
      IconData icon,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
        size: 20,
      ),
      filled: true,
      fillColor: theme.brightness == Brightness.dark
          ? colorScheme.surfaceContainerHighest.withOpacity(.45)
          : const Color(0xFFF4F5F9),
      labelStyle: TextStyle(
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade400
            : Colors.grey.shade700,
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(.08)
              : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdFormBloc, AdFormState>(
      listener: _onBlocState,
      builder: _buildForm,
    );
  }

  Widget _buildForm(BuildContext context, AdFormState state) {
    final isLoadingAd = state is AdFormLoading;
    final isSubmitting = state is AdFormSubmitting;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final appBar = AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: Text(
        _isEdit ? 'Edit Ad' : 'Post New Ad',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
    );

    if (isLoadingAd) {
      return Scaffold(
        backgroundColor:
        isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF4F5F9),
        appBar: appBar,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF4F5F9),
      appBar: appBar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 900 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // MEDIA + DETAILS
                      isWide
                          ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildMediaSection(context),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailsSection(context),
                          ),
                        ],
                      )
                          : Column(
                        children: [
                          _buildMediaSection(context),
                          const SizedBox(height: 16),
                          _buildDetailsSection(context),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // QUIZ
                      _buildQuizSection(context),

                      const SizedBox(height: 24),

                      // POST / SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            AppColors.primary.withOpacity(.55),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEdit
                                    ? Icons.save_rounded
                                    : Icons.campaign_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEdit ? 'Save Changes' : 'Post Ad',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(
          color: Colors.white.withOpacity(.06),
        )
            : null,
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .3,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // MEDIA SECTION
  // ============================================================

  Widget _buildMediaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          context: context,
          title: 'PHOTOS',
          icon: Icons.photo_camera_outlined,
          subtitle:
          'Give size preference — pick $_minImages to $_maxImages images. Tap the crop icon on a photo to edit it before uploading.',
          children: [
            _buildImagePicker(context),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          context: context,
          title: 'VIDEO (OPTIONAL)',
          icon: Icons.videocam_outlined,
          subtitle:
          'Keep it under ${_maxVideoDuration.inSeconds} seconds — like a WhatsApp status. Longer videos open a trim screen automatically.',
          children: [
            _buildVideoPicker(context),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DETAILS SECTION
  // ============================================================

  Widget _buildDetailsSection(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return _sectionCard(
      context: context,
      title: 'AD DETAILS',
      icon: Icons.campaign_outlined,
      children: [
        TextField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          style: TextStyle(color: onSurface),
          decoration: _fieldDeco(
            context,
            'Ad Title',
            Icons.title_rounded,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          style: TextStyle(color: onSurface),
          decoration: _fieldDeco(
            context,
            'Description',
            Icons.description_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _offerController,
          textInputAction: TextInputAction.done,
          style: TextStyle(color: onSurface),
          decoration: _fieldDeco(
            context,
            'Offer Details (Optional)',
            Icons.local_offer_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          style: TextStyle(color: onSurface),
          decoration: _fieldDeco(
            context,
            'Contact Phone Number',
            Icons.phone_outlined,
          ).copyWith(
            prefixText: '+91 ',
            counterText: '',
            helperText: 'Shown on your ad so buyers can call you',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          style: TextStyle(color: onSurface),
          decoration: _fieldDeco(
            context,
            'WhatsApp Number (Optional)',
            Icons.whatshot,
          ).copyWith(
            prefixText: '+91 ',
            counterText: '',
            helperText: 'Add this to show a WhatsApp button on your ad',
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              _whatsappController.text = _phoneController.text.trim();
            },
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text(
              'Same as contact number',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),

        // PRODUCT STATUS (edit mode only; new ads start as Available)
        if (_isEdit) ...[
          const SizedBox(height: 10),
          Text(
            'Product Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Available'),
                selected: _status == ProductStatus.available,
                showCheckmark: false,
                selectedColor: const Color(0xFF1D9E75).withOpacity(.18),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _status == ProductStatus.available
                      ? const Color(0xFF1D9E75)
                      : onSurface,
                ),
                onSelected: (_) =>
                    setState(() => _status = ProductStatus.available),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Sold'),
                selected: _status == ProductStatus.sold,
                showCheckmark: false,
                selectedColor: const Color(0xFFE24B4A).withOpacity(.18),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _status == ProductStatus.sold
                      ? const Color(0xFFE24B4A)
                      : onSurface,
                ),
                onSelected: (_) =>
                    setState(() => _status = ProductStatus.sold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Widget _buildImagePicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_images.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withOpacity(.10)
                : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(.35),
              width: 1.3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 27,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap to select images',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$_minImages to $_maxImages images required',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final belowMin = _images.length < _minImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
            _images.length < _maxImages ? _images.length + 1 : _images.length,
            itemBuilder: (context, index) {
              // ADD MORE (only shown while under the max)
              if (index == _images.length) {
                return GestureDetector(
                  onTap: _addMoreImages,
                  child: Container(
                    width: 94,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withOpacity(.10)
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(.35),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // IMAGE (already uploaded or newly picked)
              final item = _images[index];

              return Stack(
                children: [
                  Container(
                    width: 94,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.isNetwork
                          ? Image.network(
                        item.url!,
                        fit: BoxFit.cover,
                        width: 94,
                        height: 100,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : Image.file(
                        item.file!,
                        fit: BoxFit.cover,
                        width: 94,
                        height: 100,
                      ),
                    ),
                  ),

                  // Remove
                  Positioned(
                    top: 5,
                    right: 13,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _images.removeAt(index);
                        });
                        _scheduleDraftSave();
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),

                  // Edit / crop
                  Positioned(
                    bottom: 5,
                    right: 13,
                    child: GestureDetector(
                      onTap: () => _editImage(index),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.crop_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),

                  // Image number
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_images.length} of $_maxImages images selected'
              '${belowMin ? ' — need at least $_minImages' : ''}',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: belowMin ? FontWeight.w600 : FontWeight.normal,
            color: belowMin
                ? AppColors.error
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VIDEO PICKER
  // ============================================================

  Widget _buildVideoPicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isProcessingVideo) {
      return Container(
        height: 125,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (!_hasVideo) {
      return GestureDetector(
        onTap: _pickVideo,
        child: Container(
          width: double.infinity,
          height: 125,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withOpacity(.10)
                : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(.35),
              width: 1.3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_library_outlined,
                  size: 25,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Tap to select video',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Under ${_maxVideoDuration.inSeconds} seconds',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _videoController;
    final durationLabel =
    _videoDuration != null ? '${_videoDuration!.inSeconds}s' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller != null && controller.value.isInitialized)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(controller),

                        // Play button overlay
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              controller.value.isPlaying
                                  ? controller.pause()
                                  : controller.play();
                            });
                          },
                          child: AnimatedOpacity(
                            duration: const Duration(
                              milliseconds: 200,
                            ),
                            opacity: controller.value.isPlaying ? .0 : 1.0,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    durationLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          )
        else if (_selectedVideo == null)
        // Existing video whose preview couldn't be loaded
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_rounded, color: Colors.white70, size: 30),
                  SizedBox(height: 6),
                  Text(
                    'Video attached (preview unavailable)',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Trim works on a newly picked video (an uploaded one can be
            // replaced with Change instead).
            if (_selectedVideo != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _trimExistingVideo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.content_cut_rounded, size: 16),
                  label: const Text(
                    'Trim',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickVideo,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withOpacity(.45),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedVideo = null;
                    _existingVideoUrl = null;
                    _videoDuration = null;
                    _videoController?.dispose();
                    _videoController = null;
                  });
                  _scheduleDraftSave();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withOpacity(.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // QUIZ SECTION
  // ============================================================

  Widget _buildQuizSection(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return _sectionCard(
      context: context,
      title: 'QUIZ SECTION',
      icon: Icons.quiz_outlined,
      children: [
        TextField(
          controller: _quizQuestionController,
          style: TextStyle(color: onSurface),
          decoration: _fieldDeco(
            context,
            'Quiz Question',
            Icons.help_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;

            final fields = [
              TextField(
                controller: _option1Controller,
                style: TextStyle(color: onSurface),
                decoration: _fieldDeco(
                  context,
                  'Option 1',
                  Icons.looks_one_rounded,
                ),
              ),
              TextField(
                controller: _option2Controller,
                style: TextStyle(color: onSurface),
                decoration: _fieldDeco(
                  context,
                  'Option 2',
                  Icons.looks_two_rounded,
                ),
              ),
              TextField(
                controller: _option3Controller,
                style: TextStyle(color: onSurface),
                decoration: _fieldDeco(
                  context,
                  'Option 3',
                  Icons.looks_3_rounded,
                ),
              ),
              TextField(
                controller: _option4Controller,
                style: TextStyle(color: onSurface),
                decoration: _fieldDeco(
                  context,
                  'Option 4',
                  Icons.looks_4_rounded,
                ),
              ),
            ];

            if (!isWide) {
              return Column(
                children: [
                  for (int i = 0; i < fields.length; i++) ...[
                    fields[i],
                    if (i != fields.length - 1) const SizedBox(height: 14),
                  ],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 14),
                    Expanded(child: fields[1]),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: fields[2]),
                    const SizedBox(width: 14),
                    Expanded(child: fields[3]),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // CORRECT ANSWER
        DropdownButtonFormField<int>(
          value: _correctAnswerIndex,
          dropdownColor: Theme.of(context).colorScheme.surface,
          style: TextStyle(
            color: onSurface,
            fontSize: 14,
          ),
          decoration: _fieldDeco(
            context,
            'Correct Answer',
            Icons.check_circle_outline_rounded,
          ),
          items: const [
            DropdownMenuItem(
              value: 0,
              child: Text('Option 1'),
            ),
            DropdownMenuItem(
              value: 1,
              child: Text('Option 2'),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('Option 3'),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('Option 4'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _correctAnswerIndex = value;
            });
            _scheduleDraftSave();
          },
        ),
      ],
    );
  }
}