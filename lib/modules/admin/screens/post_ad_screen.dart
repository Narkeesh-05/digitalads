import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:digitalads/modules/admin/screens/video_trim_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme.dart';

/// One photo in the picker: either already uploaded (network) or newly
/// picked from the device (local file).
class _ImageItem {
  final String? url;
  final File? file;

  const _ImageItem.network(String this.url) : file = null;
  const _ImageItem.local(File this.file) : url = null;

  bool get isNetwork => url != null;
}

/// Post a new ad, or edit an existing one when [adId] is given.
class PostAdScreen extends StatefulWidget {
  final String? adId;

  const PostAdScreen({super.key, this.adId});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  // Business rules for media — keep these in one place so both the
  // validation and the hint text below always agree with each other.
  static const int _minImages = 3;
  static const int _maxImages = 5;
  static const Duration _maxVideoDuration = Duration(seconds: 30);

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

  Timer? _draftSaveTimer;
  bool _isRestoringDraft = false;

  int _correctAnswerIndex = 0;

  List<_ImageItem> _images = [];
  File? _selectedVideo; // newly picked video
  String? _existingVideoUrl; // already uploaded video (edit mode)
  VideoPlayerController? _videoController;
  Duration? _videoDuration;

  bool _isLoading = false;
  bool _isProcessingVideo = false;
  bool _isLoadingAd = false;

  bool get _hasVideo => _selectedVideo != null || _existingVideoUrl != null;

  final cloudinary = CloudinaryPublic(
    'dqs6gmhsp',
    'digitalads',
    cache: false,
  );

  // ============================================================
  // DRAFT (new ads only)
  // ============================================================

  String get _draftKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return 'post_ad_draft_guest';
    }

    return 'post_ad_draft_$uid';
  }

  void _scheduleDraftSave() {
    if (_isEdit || _isRestoringDraft) return;

    _draftSaveTimer?.cancel();

    _draftSaveTimer = Timer(
      const Duration(milliseconds: 500),
      _saveDraft,
    );
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final draft = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'offer': _offerController.text,
        'phone': _phoneController.text,
        'whatsapp': _whatsappController.text,
        'quizQuestion': _quizQuestionController.text,
        'option1': _option1Controller.text,
        'option2': _option2Controller.text,
        'option3': _option3Controller.text,
        'option4': _option4Controller.text,
        'correctAnswerIndex': _correctAnswerIndex,
        'imagePaths': _images
            .where((i) => i.file != null)
            .map((i) => i.file!.path)
            .toList(),
        'videoPath': _selectedVideo?.path,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_draftKey, jsonEncode(draft));

      debugPrint('Post Ad draft saved');
    } catch (e) {
      debugPrint('Draft save error: $e');
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedDraft = prefs.getString(_draftKey);

      if (savedDraft == null || savedDraft.isEmpty) {
        debugPrint('No Post Ad draft found');
        return;
      }

      final Map<String, dynamic> draft =
      jsonDecode(savedDraft) as Map<String, dynamic>;

      _isRestoringDraft = true;

      _titleController.text = draft['title']?.toString() ?? '';
      _descriptionController.text = draft['description']?.toString() ?? '';
      _offerController.text = draft['offer']?.toString() ?? '';
      _phoneController.text = draft['phone']?.toString() ?? '';
      _whatsappController.text = draft['whatsapp']?.toString() ?? '';
      _quizQuestionController.text = draft['quizQuestion']?.toString() ?? '';
      _option1Controller.text = draft['option1']?.toString() ?? '';
      _option2Controller.text = draft['option2']?.toString() ?? '';
      _option3Controller.text = draft['option3']?.toString() ?? '';
      _option4Controller.text = draft['option4']?.toString() ?? '';

      final savedCorrectIndex = draft['correctAnswerIndex'];

      if (savedCorrectIndex is int &&
          savedCorrectIndex >= 0 &&
          savedCorrectIndex <= 3) {
        _correctAnswerIndex = savedCorrectIndex;
      }

      // Images
      final savedImagePaths = draft['imagePaths'];

      if (savedImagePaths is List) {
        final restored = <_ImageItem>[];

        for (final path in savedImagePaths) {
          final file = File(path.toString());

          if (await file.exists()) {
            restored.add(_ImageItem.local(file));
          }
        }

        _images = restored;
      }

      // Video
      final savedVideoPath = draft['videoPath'];

      if (savedVideoPath != null && savedVideoPath.toString().isNotEmpty) {
        final videoFile = File(savedVideoPath.toString());

        if (await videoFile.exists()) {
          _selectedVideo = videoFile;

          final controller = VideoPlayerController.file(videoFile);

          await controller.initialize();

          _videoController = controller;
          _videoDuration = controller.value.duration;
        }
      }

      _isRestoringDraft = false;

      debugPrint('Post Ad draft restored');

      if (mounted) {
        final hasData = _titleController.text.isNotEmpty ||
            _descriptionController.text.isNotEmpty ||
            _offerController.text.isNotEmpty ||
            _images.isNotEmpty ||
            _selectedVideo != null ||
            _quizQuestionController.text.isNotEmpty;

        if (hasData) {
          _showSnackBar(
            'Your previous ad details have been restored.',
            isError: false,
          );
        }

        setState(() {});
      }
    } catch (e) {
      _isRestoringDraft = false;

      debugPrint('Draft restore error: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_draftKey);

      debugPrint('Post Ad draft cleared');
    } catch (e) {
      debugPrint('Draft clear error: $e');
    }
  }

  // ============================================================
  // LOAD EXISTING AD (edit mode)
  // ============================================================

  /// "+919876543210" -> "9876543210"
  String _last10Digits(dynamic raw) {
    final digits = (raw ?? '').toString().replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) return digits.substring(digits.length - 10);
    return digits;
  }

  void _failLoad(String message) {
    if (!mounted) return;
    _showSnackBar(message, isError: true);
    Navigator.pop(context);
  }

  Future<void> _loadExistingAd() async {
    try {
      final snap =
      await FirebaseDatabase.instance.ref('ads/${widget.adId}').get();

      if (!snap.exists || snap.value is! Map) {
        _failLoad('This ad no longer exists.');
        return;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);

      // Only the seller who posted the ad may edit it.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || data['adminId'] != uid) {
        _failLoad('You can only edit your own ads.');
        return;
      }

      _titleController.text = (data['title'] ?? '').toString();
      _descriptionController.text = (data['description'] ?? '').toString();
      _offerController.text = (data['offer'] ?? '').toString();
      _phoneController.text = _last10Digits(data['phone']);
      _whatsappController.text = _last10Digits(data['whatsapp']);

      // Images (stored as a List or a Map, with a legacy single imageUrl)
      final urls = <String>[];
      final rawImages = data['imageUrls'];
      if (rawImages is List) {
        urls.addAll(
          rawImages.where((e) => e != null).map((e) => e.toString()),
        );
      } else if (rawImages is Map) {
        urls.addAll(rawImages.values.map((e) => e.toString()));
      }
      if (urls.isEmpty &&
          data['imageUrl'] != null &&
          data['imageUrl'].toString().isNotEmpty) {
        urls.add(data['imageUrl'].toString());
      }

      // Quiz
      final quiz = data['quiz'];
      if (quiz is Map) {
        _quizQuestionController.text = (quiz['question'] ?? '').toString();

        final rawOptions = quiz['options'];
        final options = <String>[];
        if (rawOptions is List) {
          options.addAll(rawOptions.map((e) => (e ?? '').toString()));
        } else if (rawOptions is Map) {
          options.addAll(rawOptions.values.map((e) => (e ?? '').toString()));
        }

        final controllers = [
          _option1Controller,
          _option2Controller,
          _option3Controller,
          _option4Controller,
        ];
        for (var i = 0; i < controllers.length && i < options.length; i++) {
          controllers[i].text = options[i];
        }

        final correct = quiz['correctIndex'];
        if (correct is int && correct >= 0 && correct <= 3) {
          _correctAnswerIndex = correct;
        }
      }

      // Video
      final videoUrl = (data['videoUrl'] ?? '').toString();
      VideoPlayerController? controller;
      if (videoUrl.isNotEmpty) {
        try {
          controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          await controller.initialize();
        } catch (e) {
          debugPrint('Existing video preview failed: $e');
          await controller?.dispose();
          controller = null;
        }
      }

      if (!mounted) {
        await controller?.dispose();
        return;
      }

      setState(() {
        _images = urls.map(_ImageItem.network).toList();
        _existingVideoUrl = videoUrl.isNotEmpty ? videoUrl : null;
        _videoController = controller;
        _videoDuration = controller?.value.duration;
        _isLoadingAd = false;
      });
    } catch (e) {
      debugPrint('Load ad error: $e');
      _failLoad('Unable to load ad. Please try again.');
    }
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      _isLoadingAd = true;
      _loadExistingAd();
    } else {
      _restoreDraft();
    }

    _titleController.addListener(_scheduleDraftSave);
    _descriptionController.addListener(_scheduleDraftSave);
    _offerController.addListener(_scheduleDraftSave);
    _phoneController.addListener(_scheduleDraftSave);
    _whatsappController.addListener(_scheduleDraftSave);

    _quizQuestionController.addListener(_scheduleDraftSave);
    _option1Controller.addListener(_scheduleDraftSave);
    _option2Controller.addListener(_scheduleDraftSave);
    _option3Controller.addListener(_scheduleDraftSave);
    _option4Controller.addListener(_scheduleDraftSave);
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();

    _titleController.removeListener(_scheduleDraftSave);
    _descriptionController.removeListener(_scheduleDraftSave);
    _offerController.removeListener(_scheduleDraftSave);
    _phoneController.removeListener(_scheduleDraftSave);
    _whatsappController.removeListener(_scheduleDraftSave);

    _quizQuestionController.removeListener(_scheduleDraftSave);
    _option1Controller.removeListener(_scheduleDraftSave);
    _option2Controller.removeListener(_scheduleDraftSave);
    _option3Controller.removeListener(_scheduleDraftSave);
    _option4Controller.removeListener(_scheduleDraftSave);

    _phoneController.dispose();
    _whatsappController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _offerController.dispose();

    _quizQuestionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();

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
        _images = files.map(_ImageItem.local).toList();
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
          ...newFiles.map(_ImageItem.local),
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
        _images[index] = _ImageItem.local(File(cropped.path));
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
  // LOCATION
  // ============================================================

  Future<Position?> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }

    return null;
  }

  // ============================================================
  // POST / SAVE AD
  // ============================================================

  Future<void> _postAd() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final phone = _phoneController.text.trim();
    final whatsapp = _whatsappController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      _showSnackBar(
        'Please enter a title and description.',
        isError: true,
      );
      return;
    }

    if (phone.length != 10) {
      _showSnackBar(
        'Please enter a valid 10-digit contact number.',
        isError: true,
      );
      return;
    }

    if (whatsapp.isNotEmpty && whatsapp.length != 10) {
      _showSnackBar(
        'WhatsApp number must be 10 digits (or leave it empty).',
        isError: true,
      );
      return;
    }

    if (_images.length < _minImages) {
      _showSnackBar(
        'Please select at least $_minImages images (up to $_maxImages).',
        isError: true,
      );
      return;
    }

    if (_images.length > _maxImages) {
      _showSnackBar(
        'Please keep it to $_maxImages images or fewer.',
        isError: true,
      );
      return;
    }

    if (_selectedVideo != null &&
        _videoDuration != null &&
        _videoDuration! > _maxVideoDuration) {
      _showSnackBar(
        'Video must be under ${_maxVideoDuration.inSeconds} seconds — please trim it first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User is not logged in.');
      }

      final uid = currentUser.uid;

      // New ads capture the location; edits keep the original one.
      final Position? position = _isEdit ? null : await _getLocation();

      // ----------------------------------------------------------
      // IMAGES — keep already-uploaded ones, upload only new ones
      // ----------------------------------------------------------

      final List<String> imageUrls = [];

      for (final item in _images) {
        if (item.isNetwork) {
          imageUrls.add(item.url!);
        } else {
          final CloudinaryResponse response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              item.file!.path,
              resourceType: CloudinaryResourceType.Image,
            ),
          );

          imageUrls.add(response.secureUrl);
        }
      }

      // ----------------------------------------------------------
      // VIDEO — new upload, or keep existing, or none
      // ----------------------------------------------------------

      String? videoUrl;

      if (_selectedVideo != null) {
        final CloudinaryResponse videoResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _selectedVideo!.path,
            resourceType: CloudinaryResourceType.Video,
          ),
        );

        videoUrl = videoResponse.secureUrl;
      } else {
        videoUrl = _existingVideoUrl;
      }

      // ----------------------------------------------------------
      // FIREBASE DATABASE
      // ----------------------------------------------------------

      final Map<String, Object?> adData = {
        'title': title,
        'description': description,
        'offer': _offerController.text.trim(),
        'phone': '+91$phone',
        // Optional — the WhatsApp button only shows when this is set.
        'whatsapp': whatsapp.isEmpty ? null : '+91$whatsapp',
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'quiz': {
          'question': _quizQuestionController.text.trim(),
          'options': [
            _option1Controller.text.trim(),
            _option2Controller.text.trim(),
            _option3Controller.text.trim(),
            _option4Controller.text.trim(),
          ],
          'correctIndex': _correctAnswerIndex,
        },
      };

      if (_isEdit) {
        // update() only touches these fields, so likes, comments, views
        // and quiz attempts stay as they are.
        await FirebaseDatabase.instance.ref('ads/${widget.adId}').update({
          ...adData,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        await FirebaseDatabase.instance.ref('ads').push().set({
          ...adData,
          'adminId': uid,
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Successfully posted → remove saved draft
        await _clearDraft();
      }

      if (!mounted) return;

      _showSnackBar(
        _isEdit ? 'Ad Updated Successfully!' : 'Ad Posted Successfully!',
        isError: false,
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Post ad error: $e');

      if (mounted) {
        _showSnackBar(
          'Error: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

    if (_isLoadingAd) {
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
                          onPressed: _isLoading ? null : _postAd,
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
                          child: _isLoading
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
            // FontAwesomeIcons.whatsapp,
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