 
import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme.dart';

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  State<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _offerController = TextEditingController();

  final _quizQuestionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();

  int _correctAnswerIndex = 0;

  List<File> _selectedImages = [];
  File? _selectedVideo;
  VideoPlayerController? _videoController;

  bool _isLoading = false;

  final cloudinary = CloudinaryPublic(
    'dqs6gmhsp',
    'digitalads',
    cache: false,
  );

  @override
  void dispose() {
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

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages =
              pickedFiles.map((e) => File(e.path)).toList();
        });
      }
    } catch (e) {
      _showSnackBar(
        'Unable to select images',
        isError: true,
      );
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

      await _videoController?.dispose();

      final videoFile = File(pickedFile.path);

      final controller = VideoPlayerController.file(videoFile);

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _selectedVideo = videoFile;
        _videoController = controller;
      });
    } catch (e) {
      _showSnackBar(
        'Unable to select video',
        isError: true,
      );
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<Position?> _getLocation() async {
    try {
      LocationPermission permission =
      await Geolocator.checkPermission();

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
  // POST AD
  // ============================================================

  Future<void> _postAd() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        _selectedImages.isEmpty) {
      _showSnackBar(
        'Please enter title, description and select at least 1 image.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ----------------------------------------------------------
      // LOCATION
      // ----------------------------------------------------------

      final position = await _getLocation();

      // ----------------------------------------------------------
      // UPLOAD IMAGES
      // ----------------------------------------------------------

      final List<String> imageUrls = [];

      for (final image in _selectedImages) {
        final CloudinaryResponse response =
        await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );

        imageUrls.add(response.secureUrl);
      }

      // ----------------------------------------------------------
      // UPLOAD VIDEO
      // ----------------------------------------------------------

      String? videoUrl;

      if (_selectedVideo != null) {
        final CloudinaryResponse videoResponse =
        await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _selectedVideo!.path,
            resourceType: CloudinaryResourceType.Video,
          ),
        );

        videoUrl = videoResponse.secureUrl;
      }

      // ----------------------------------------------------------
      // CURRENT ADMIN
      // ----------------------------------------------------------

      final currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User is not logged in.');
      }

      final uid = currentUser.uid;

      // ----------------------------------------------------------
      // FIREBASE DATABASE
      // ----------------------------------------------------------

      await FirebaseDatabase.instance.ref('ads').push().set({
        'title': title,
        'description': description,
        'offer': _offerController.text.trim(),
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'adminId': uid,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'createdAt': DateTime.now().toIso8601String(),
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
      });

      if (!mounted) return;

      _showSnackBar(
        'Ad Posted Successfully!',
        isError: false,
      );

      Navigator.pop(context);
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
          backgroundColor:
          isError ? AppColors.error : const Color(0xFF1D9E75),
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
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade500
            : Colors.grey.shade500,
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

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF4F5F9),

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Post New Ad',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

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
                    crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                    children: [
                      // ------------------------------------------------
                      // MEDIA + DETAILS
                      // ------------------------------------------------

                      isWide
                          ? Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildMediaSection(context),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child:
                            _buildDetailsSection(context),
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

                      // ------------------------------------------------
                      // QUIZ
                      // ------------------------------------------------

                      _buildQuizSection(context),

                      const SizedBox(height: 24),

                      // ------------------------------------------------
                      // POST BUTTON
                      // ------------------------------------------------

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                          _isLoading ? null : _postAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            AppColors.primary.withOpacity(.55),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.campaign_rounded,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Post Ad',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.w600,
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
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : Colors.white,
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius:
                  BorderRadius.circular(10),
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
                    color: theme
                        .colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
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
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          context: context,
          title: 'PHOTOS',
          icon: Icons.photo_camera_outlined,
          children: [
            _buildImagePicker(context),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          context: context,
          title: 'VIDEO (OPTIONAL)',
          icon: Icons.videocam_outlined,
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
    return _sectionCard(
      context: context,
      title: 'AD DETAILS',
      icon: Icons.campaign_outlined,
      children: [
        TextField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface,
          ),
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
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface,
          ),
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
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface,
          ),
          decoration: _fieldDeco(
            context,
            'Offer Details (Optional)',
            Icons.local_offer_outlined,
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

    if (_selectedImages.isEmpty) {
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
            mainAxisAlignment:
            MainAxisAlignment.center,
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
              Text(
                'Tap to select images',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'You can select multiple images',
                style: TextStyle(
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
            _selectedImages.length + 1,
            itemBuilder: (context, index) {
              // -----------------------------------------------
              // ADD MORE
              // -----------------------------------------------

              if (index ==
                  _selectedImages.length) {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 94,
                    margin:
                    const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary
                          .withOpacity(.10)
                          : AppColors.primarySurface,
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary
                            .withOpacity(.35),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
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
                            color:
                            AppColors.primary,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // -----------------------------------------------
              // IMAGE
              // -----------------------------------------------

              return Stack(
                children: [
                  Container(
                    width: 94,
                    height: 100,
                    margin:
                    const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImages[index],
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
                          _selectedImages
                              .removeAt(index);
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration:
                        const BoxDecoration(
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

                  // Image number
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black
                            .withOpacity(.55),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight:
                          FontWeight.w600,
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
          '${_selectedImages.length} image${_selectedImages.length == 1 ? '' : 's'} selected',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
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

    if (_selectedVideo == null) {
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
              color:
              AppColors.primary.withOpacity(.35),
              width: 1.3,
            ),
          ),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(.12),
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
                'Optional promotional video',
                style: TextStyle(
                  color: isDark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _videoController;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        if (controller != null &&
            controller.value.isInitialized)
          ClipRRect(
            borderRadius:
            BorderRadius.circular(14),
            child: Container(
              color: Colors.black,
              child: AspectRatio(
                aspectRatio:
                controller.value.aspectRatio,
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
                        duration:
                        const Duration(
                          milliseconds: 200,
                        ),
                        opacity:
                        controller.value.isPlaying
                            ? .0
                            : 1.0,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration:
                          BoxDecoration(
                            color: Colors.black
                                .withOpacity(.55),
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
          )
        else
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius:
              BorderRadius.circular(14),
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickVideo,
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary
                        .withOpacity(.45),
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),
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
                    fontWeight:
                    FontWeight.w600,
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
                    _videoController?.dispose();
                    _videoController = null;
                  });
                },
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  AppColors.error,
                  side: BorderSide(
                    color: AppColors.error
                        .withOpacity(.35),
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),
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
                    fontWeight:
                    FontWeight.w600,
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
    return _sectionCard(
      context: context,
      title: 'QUIZ SECTION',
      icon: Icons.quiz_outlined,
      children: [
        TextField(
          controller: _quizQuestionController,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface,
          ),
          decoration: _fieldDeco(
            context,
            'Quiz Question',
            Icons.help_outline_rounded,
          ),
        ),

        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide =
                constraints.maxWidth > 500;

            final fields = [
              TextField(
                controller: _option1Controller,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
                decoration: _fieldDeco(
                  context,
                  'Option 1',
                  Icons.looks_one_rounded,
                ),
              ),
              TextField(
                controller: _option2Controller,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
                decoration: _fieldDeco(
                  context,
                  'Option 2',
                  Icons.looks_two_rounded,
                ),
              ),
              TextField(
                controller: _option3Controller,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
                decoration: _fieldDeco(
                  context,
                  'Option 3',
                  Icons.looks_3_rounded,
                ),
              ),
              TextField(
                controller: _option4Controller,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
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
                  for (int i = 0;
                  i < fields.length;
                  i++) ...[
                    fields[i],
                    if (i != fields.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: fields[0],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: fields[1],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: fields[2],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: fields[3],
                    ),
                  ],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        // --------------------------------------------------------
        // CORRECT ANSWER
        // --------------------------------------------------------

        DropdownButtonFormField<int>(
          value: _correctAnswerIndex,
          dropdownColor:
          Theme.of(context).colorScheme.surface,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface,
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
          },
        ),
      ],
    );
  }
}