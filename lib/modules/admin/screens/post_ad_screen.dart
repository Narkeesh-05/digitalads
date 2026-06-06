import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

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
        _selectedImages =
            pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
      });
      _videoController =
      VideoPlayerController.file(_selectedVideo!)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  Future<Position?> _getLocation() async {
    try {
      LocationPermission permission =
      await Geolocator.checkPermission();
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
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get location
      Position? position = await _getLocation();

      // Upload images to Cloudinary
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

      // Upload video if selected
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

      // Save ad to Firebase
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
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Post New Ad',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              const Text(
                '📸 Images',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: _selectedImages.isEmpty ? 120 : null,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.orange, width: 1.5),
                  ),
                  child: _selectedImages.isEmpty
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 40, color: Colors.orange),
                      SizedBox(height: 8),
                      Text(
                        'Tap to select images',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                          _selectedImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index ==
                                _selectedImages.length) {
                              return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  width: 100,
                                  margin:
                                  const EdgeInsets.only(
                                      right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.orange),
                                    borderRadius:
                                    BorderRadius.circular(
                                        8),
                                  ),
                                  child: const Icon(
                                      Icons.add,
                                      color: Colors.orange),
                                ),
                              );
                            }
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  margin:
                                  const EdgeInsets.only(
                                      right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(
                                        8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(
                                        8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages
                                            .removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration:
                                      const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Video Section
              const Text(
                '🎥 Video (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  width: double.infinity,
                  height: _selectedVideo == null ? 100 : null,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.orange, width: 1.5),
                  ),
                  child: _selectedVideo == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library,
                          size: 40, color: Colors.orange),
                      SizedBox(height: 8),
                      Text(
                        'Tap to select video (Optional)',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      if (_videoController != null &&
                          _videoController!.value.isInitialized)
                        AspectRatio(
                          aspectRatio: _videoController!
                              .value.aspectRatio,
                          child:
                          VideoPlayer(_videoController!),
                        ),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedVideo = null;
                                _videoController?.dispose();
                                _videoController = null;
                              });
                            },
                            child: const Text(
                              'Remove Video',
                              style:
                              TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Ad Title',
                  prefixIcon:
                  const Icon(Icons.title, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description,
                      color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Offer
              TextField(
                controller: _offerController,
                decoration: InputDecoration(
                  labelText: 'Offer Details (Optional)',
                  prefixIcon: const Icon(Icons.local_offer,
                      color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Post Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postAd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : const Text(
                    'Post Ad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),

              // Quiz Section
              const Text(
                '📝 Quiz Section',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quizQuestionController,
                decoration: InputDecoration(
                  labelText: 'Quiz Question',
                  prefixIcon:
                  const Icon(Icons.quiz, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _option1Controller,
                decoration: InputDecoration(
                  labelText: 'Option 1',
                  prefixIcon:
                  const Icon(Icons.looks_one, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _option2Controller,
                decoration: InputDecoration(
                  labelText: 'Option 2',
                  prefixIcon:
                  const Icon(Icons.looks_two, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _option3Controller,
                decoration: InputDecoration(
                  labelText: 'Option 3',
                  prefixIcon:
                  const Icon(Icons.looks_3, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _option4Controller,
                decoration: InputDecoration(
                  labelText: 'Option 4',
                  prefixIcon:
                  const Icon(Icons.looks_4, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _correctAnswerIndex,
                decoration: InputDecoration(
                  labelText: 'Correct Answer',
                  prefixIcon: const Icon(Icons.check_circle,
                      color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}