import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/core/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({Key? key, required void Function(dynamic action) onAction}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  List<String> _videos = [];
  String? _selectedVideo;
  bool _isPlaying = false;
  double _currentPosition = 0;
  double _duration = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _checkPermissions();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission not granted')),
      );
    }
  }

  Future<void> _loadVideos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/videos');
      if (await dir.exists()) {
        final files = dir.listSync();
        setState(() {
          _videos = files
              .where((file) => file.path.endsWith('.mp4'))
              .map((file) => file.path)
              .toList();
        });
      } else {
        await dir.create();
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );

      if (video != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final now = DateTime.now();
        final formattedDate = DateFormat('yyyy_MM_dd_HH_mm_ss').format(now);
        final videoDir = Directory('${appDir.path}/videos');
        if (!await videoDir.exists()) {
          await videoDir.create();
        }

        final fileName = 'video_$formattedDate.mp4';
        final savedVideo =
            await File(video.path).copy('${videoDir.path}/$fileName');

        setState(() {
          _videos.add(savedVideo.path);
          _selectVideo(savedVideo.path);
        });
      }
    } catch (e) {
      debugPrint('Error recording video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording video: $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final now = DateTime.now();
        final formattedDate = DateFormat('yyyy_MM_dd_HH_mm_ss').format(now);
        final videoDir = Directory('${appDir.path}/videos');
        if (!await videoDir.exists()) {
          await videoDir.create();
        }

        final fileName = 'video_gallery_$formattedDate.mp4';
        final savedVideo =
            await File(video.path).copy('${videoDir.path}/$fileName');

        setState(() {
          _videos.add(savedVideo.path);
          _selectVideo(savedVideo.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking video from gallery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video from gallery: $e')),
      );
    }
  }

  Future<void> _selectVideo(String path) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();

    // Add listener for position updates
    controller.addListener(() {
      if (mounted) {
        setState(() {
          _currentPosition =
              controller.value.position.inMilliseconds.toDouble();
          _isPlaying = controller.value.isPlaying;
        });
      }
    });

    setState(() {
      _controller = controller;
      _isInitialized = true;
      _selectedVideo = path;
      _duration = controller.value.duration.inMilliseconds.toDouble();
      _currentPosition = 0;
    });
  }

  Future<void> _deleteVideo(String path) async {
    try {
      if (_selectedVideo == path && _controller != null) {
        await _controller!.pause();
        await _controller!.dispose();
        setState(() {
          _controller = null;
          _isInitialized = false;
          _selectedVideo = null;
        });
      }

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _videos.remove(path);
        });
      }
    } catch (e) {
      debugPrint('Error deleting video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: $e')),
      );
    }
  }

  String _extractTitle(String path) {
    final fileName = path.split('/').last;
    return fileName.replaceAll('.mp4', '');
  }

  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.round());
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isTravelTheme =
        themeProvider.themeType == AppConstants.travelTheme;

    return Column(
      children: [
        // Video controls
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  isTravelTheme
                      ? 'Capture Travel Videos'
                      : 'Capture Cooking Videos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _recordVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Record'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Selected video player
        if (_isInitialized && _controller != null)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Video progress
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Text(_formatDuration(_currentPosition)),
                        Expanded(
                          child: Slider(
                            value: _currentPosition,
                            min: 0,
                            max: _duration,
                            onChanged: (value) {
                              _controller?.seekTo(
                                  Duration(milliseconds: value.round()));
                              setState(() {
                                _currentPosition = value;
                              });
                            },
                          ),
                        ),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ),
                  // Video controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            if (_isPlaying) {
                              _controller?.pause();
                            } else {
                              _controller?.play();
                            }
                            _isPlaying = !_isPlaying;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay_5),
                        onPressed: () {
                          final newPosition = _currentPosition - 5000;
                          _controller?.seekTo(
                            Duration(
                              milliseconds:
                                  newPosition > 0 ? newPosition.round() : 0,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_5),
                        onPressed: () {
                          final newPosition = _currentPosition + 5000;
                          _controller?.seekTo(
                            Duration(
                              milliseconds: newPosition < _duration
                                  ? newPosition.round()
                                  : _duration.round(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (_selectedVideo != null) {
                            _deleteVideo(_selectedVideo!);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Video gallery
        Expanded(
          flex: _isInitialized && _controller != null ? 1 : 4,
          child: _videos.isEmpty
              ? Center(
                  child: Text(
                    isTravelTheme
                        ? 'No travel videos yet.\nTap Record to capture one.'
                        : 'No cooking videos yet.\nTap Record to capture one.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final path = _videos[index];
                    final title = _extractTitle(path);
                    final isSelected = _selectedVideo == path;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                      child: ListTile(
                        leading: const Icon(Icons.video_file),
                        title: Text(title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteVideo(path),
                        ),
                        onTap: () => _selectVideo(path),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
