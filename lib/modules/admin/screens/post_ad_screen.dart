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

  final cloudinary = CloudinaryPublic('dqs6gmhsp', 'digitalads', cache: false);

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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
      });
      _videoController = VideoPlayerController.file(_selectedVideo!)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  Future<Position?> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _postAd() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Please fill all fields and select at least 1 image!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Position? position = await _getLocation();

      List<String> imageUrls = [];
      for (File image in _selectedImages) {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            image.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        imageUrls.add(response.secureUrl);
      }

      String? videoUrl;
      if (_selectedVideo != null) {
        CloudinaryResponse videoResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            _selectedVideo!.path,
            resourceType: CloudinaryResourceType.Video,
          ),
        );
        videoUrl = videoResponse.secureUrl;
      }

      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseDatabase.instance.ref('ads').push().set({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad Posted Successfully!'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF4F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Post New Ad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                      isWide
                          ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildMediaSection()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDetailsSection()),
                          ],
                        ),
                      )
                          : Column(
                        children: [
                          _buildMediaSection(),
                          const SizedBox(height: 16),
                          _buildDetailsSection(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildQuizSection(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _postAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                              : const Text(
                            'Post Ad',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .3,
                  color: AppColors.textPrimary,
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

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionCard(
          title: 'PHOTOS',
          icon: Icons.photo_camera_outlined,
          children: [_buildImagePicker()],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'VIDEO (OPTIONAL)',
          icon: Icons.videocam_outlined,
          children: [_buildVideoPicker()],
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return _sectionCard(
      title: 'AD DETAILS',
      icon: Icons.campaign_outlined,
      children: [
        TextField(
          controller: _titleController,
          decoration: _fieldDeco('Ad Title', Icons.title_rounded),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration:
          _fieldDeco('Description', Icons.description_outlined),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _offerController,
          decoration: _fieldDeco(
              'Offer Details (Optional)', Icons.local_offer_outlined),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          width: double.infinity,
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(.35),
              width: 1.3,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  size: 36, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                'Tap to select images',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(.35),
                  ),
                ),
                child: Icon(Icons.add_rounded, color: AppColors.primary),
              ),
            );
          }
          return Stack(
            children: [
              Container(
                width: 90,
                height: 96,
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImages[index],
                    fit: BoxFit.cover,
                    width: 90,
                    height: 96,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPicker() {
    if (_selectedVideo == null) {
      return GestureDetector(
        onTap: _pickVideo,
        child: Container(
          width: double.infinity,
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(.35),
              width: 1.3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined,
                  size: 34, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                'Tap to select video',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_videoController != null &&
            _videoController!.value.isInitialized)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: AppColors.primary,
                size: 30,
              ),
              onPressed: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedVideo = null;
                  _videoController?.dispose();
                  _videoController = null;
                });
              },
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 18),
              label: const Text(
                'Remove Video',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizSection() {
    return _sectionCard(
      title: 'QUIZ SECTION',
      icon: Icons.quiz_outlined,
      children: [
        TextField(
          controller: _quizQuestionController,
          decoration: _fieldDeco('Quiz Question', Icons.help_outline_rounded),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            final fields = [
              TextField(
                controller: _option1Controller,
                decoration:
                _fieldDeco('Option 1', Icons.looks_one_rounded),
              ),
              TextField(
                controller: _option2Controller,
                decoration:
                _fieldDeco('Option 2', Icons.looks_two_rounded),
              ),
              TextField(
                controller: _option3Controller,
                decoration: _fieldDeco('Option 3', Icons.looks_3_rounded),
              ),
              TextField(
                controller: _option4Controller,
                decoration: _fieldDeco('Option 4', Icons.looks_4_rounded),
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
        DropdownButtonFormField<int>(
          value: _correctAnswerIndex,
          decoration: _fieldDeco(
              'Correct Answer', Icons.check_circle_outline_rounded),
          items: const [
            DropdownMenuItem(value: 0, child: Text('Option 1')),
            DropdownMenuItem(value: 1, child: Text('Option 2')),
            DropdownMenuItem(value: 2, child: Text('Option 3')),
            DropdownMenuItem(value: 3, child: Text('Option 4')),
          ],
          onChanged: (value) {
            setState(() => _correctAnswerIndex = value!);
          },
        ),
      ],
    );
  }
}