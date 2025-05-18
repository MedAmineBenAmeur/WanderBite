import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/core/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class PhotoCaptureScreen extends StatefulWidget {
  final void Function(String)? onAction;

  const PhotoCaptureScreen({
    Key? key,
    this.onAction,
  }) : super(key: key);

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  List<String> _photos = [];
  String? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission not granted')),
      );
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/photos');
      if (await dir.exists()) {
        final files = dir.listSync();
        setState(() {
          _photos = files
              .where((file) =>
                  file.path.endsWith('.jpg') ||
                  file.path.endsWith('.jpeg') ||
                  file.path.endsWith('.png'))
              .map((file) => file.path)
              .toList();
        });
      } else {
        await dir.create();
      }
    } catch (e) {
      debugPrint('Error loading photos: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (photo != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final now = DateTime.now();
        final formattedDate = DateFormat('yyyy_MM_dd_HH_mm_ss').format(now);
        final photoDir = Directory('${appDir.path}/photos');
        if (!await photoDir.exists()) {
          await photoDir.create();
        }

        final fileName = 'photo_$formattedDate.jpg';
        final savedImage =
            await File(photo.path).copy('${photoDir.path}/$fileName');

        setState(() {
          _photos.add(savedImage.path);
          _selectedPhoto = savedImage.path;
        });
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (photo != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final now = DateTime.now();
        final formattedDate = DateFormat('yyyy_MM_dd_HH_mm_ss').format(now);
        final photoDir = Directory('${appDir.path}/photos');
        if (!await photoDir.exists()) {
          await photoDir.create();
        }

        final fileName = 'photo_gallery_$formattedDate.jpg';
        final savedImage =
            await File(photo.path).copy('${photoDir.path}/$fileName');

        setState(() {
          _photos.add(savedImage.path);
          _selectedPhoto = savedImage.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking photo from gallery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking photo from gallery: $e')),
      );
    }
  }

  Future<void> _deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _photos.remove(path);
          if (_selectedPhoto == path) {
            _selectedPhoto = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isTravelTheme =
        themeProvider.themeType == AppConstants.travelTheme;

    return Column(
      children: [
        // Photo controls
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  isTravelTheme
                      ? 'Capture Your Travel Memories'
                      : 'Capture Your Food Images',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _capturePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Selected photo view
        if (_selectedPhoto != null)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        File(_selectedPhoto!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deletePhoto(_selectedPhoto!),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedPhoto = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Photo gallery
        Expanded(
          flex: _selectedPhoto != null ? 1 : 4,
          child: _photos.isEmpty
              ? Center(
                  child: Text(
                    isTravelTheme
                        ? 'No travel photos yet.\nTap Camera to capture one.'
                        : 'No food photos yet.\nTap Camera to capture one.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final path = _photos[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPhoto = path;
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              File(path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (_selectedPhoto == path)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 3.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
