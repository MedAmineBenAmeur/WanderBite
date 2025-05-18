import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/core/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class AudioRecorderScreen extends StatefulWidget {
  final Function(String) onAction;
  const AudioRecorderScreen({Key? key, required this.onAction})
      : super(key: key);

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _recordingPath = '';
  List<String> _recordings = [];
  String _playingRecordingPath = '';
  String _recordingDuration = '00:00';
  String _currentlyPlayingTitle = '';
  StreamSubscription? _recorderSubscription;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadRecordings();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _recorderSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission not granted')),
      );
      return;
    }

    await _recorder.openRecorder();
    await _player.openPlayer();
    _isRecorderInitialized = true;
    _isPlayerInitialized = true;
  }

  Future<void> _loadRecordings() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/recordings');
      if (await dir.exists()) {
        final files = dir.listSync();
        setState(() {
          _recordings = files
              .where((file) => file.path.endsWith('.aac'))
              .map((file) => file.path)
              .toList();
        });
      } else {
        await dir.create();
      }
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy_MM_dd_HH_mm_ss').format(now);
      final recordingDir = Directory('${appDir.path}/recordings');
      if (!await recordingDir.exists()) {
        await recordingDir.create();
      }

      _recordingPath = '${recordingDir.path}/recording_$formattedDate.aac';

      _recorderSubscription = _recorder.onProgress!.listen((event) {
        setState(() {
          _recordingDuration = _formatDuration(event.duration);
        });
      });

      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecorderInitialized || !_isRecording) {
      return;
    }

    try {
      await _recorder.stopRecorder();
      _recorderSubscription?.cancel();

      setState(() {
        _isRecording = false;
        _recordings.add(_recordingPath);
        _recordingDuration = '00:00';
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }

  Future<void> _playRecording(String path, String title) async {
    if (!_isPlayerInitialized || _isPlaying) {
      return;
    }

    try {
      setState(() {
        _isPlaying = true;
        _playingRecordingPath = path;
        _currentlyPlayingTitle = title;
      });

      await _player.startPlayer(
        fromURI: path,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _playingRecordingPath = '';
            _currentlyPlayingTitle = '';
          });
        },
      );
    } catch (e) {
      debugPrint('Error playing recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing recording: $e')),
      );
      setState(() {
        _isPlaying = false;
        _playingRecordingPath = '';
        _currentlyPlayingTitle = '';
      });
    }
  }

  Future<void> _stopPlayback() async {
    if (!_isPlayerInitialized || !_isPlaying) {
      return;
    }

    try {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
        _playingRecordingPath = '';
        _currentlyPlayingTitle = '';
      });
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  Future<void> _deleteRecording(String path) async {
    try {
      if (_isPlaying && _playingRecordingPath == path) {
        await _stopPlayback();
      }

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _recordings.remove(path);
        });
      }
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting recording: $e')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _extractTitle(String path) {
    final fileName = path.split('/').last;
    return fileName.replaceAll('.aac', '');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isTravelTheme =
        themeProvider.themeType == AppConstants.travelTheme;

    return Column(
      children: [
        // Recording controls
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  isTravelTheme
                      ? 'Record Your Travel Experiences'
                      : 'Record Your Cooking Instructions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  _isRecording
                      ? 'Recording: $_recordingDuration'
                      : 'Ready to Record',
                  style: TextStyle(
                    color: _isRecording ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRecording)
                      ElevatedButton.icon(
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.mic),
                        label: const Text('Record'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Currently playing
        if (_isPlaying)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: ListTile(
              leading: const Icon(Icons.music_note),
              title: Text('Now Playing: $_currentlyPlayingTitle'),
              trailing: IconButton(
                icon: const Icon(Icons.stop),
                onPressed: _stopPlayback,
              ),
            ),
          ),

        // Recordings list
        Expanded(
          child: _recordings.isEmpty
              ? Center(
                  child: Text(
                    isTravelTheme
                        ? 'No travel audio recordings yet.\nTap Record to create one.'
                        : 'No recipe audio recordings yet.\nTap Record to create one.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    final path = _recordings[index];
                    final title = _extractTitle(path);
                    final isPlaying =
                        _isPlaying && _playingRecordingPath == path;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteRecording(path),
                        ),
                        onTap: () {
                          if (isPlaying) {
                            _stopPlayback();
                          } else {
                            _playRecording(path, title);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
