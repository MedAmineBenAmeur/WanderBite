import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:WanderBite/auth/services/auth_service.dart';

class UserDataViewScreen extends StatefulWidget {
  const UserDataViewScreen({Key? key}) : super(key: key);

  @override
  State<UserDataViewScreen> createState() => _UserDataViewScreenState();
}

class _UserDataViewScreenState extends State<UserDataViewScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _fileInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserFileInfo();
  }

  Future<void> _loadUserFileInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fileInfo = await _authService.getUserFileInfo();
      setState(() {
        _fileInfo = fileInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _fileInfo = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<void> _exportJsonFile() async {
    try {
      if (_fileInfo == null || !(_fileInfo!['exists'] as bool)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user data file exists yet')),
        );
        return;
      }

      // Create a temporary copy of the file in a shareable location
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/users_export.json');

      // Get the original file path
      final originalPath = _fileInfo!['filePath'] as String;
      final originalFile = File(originalPath);

      // Copy the file
      await originalFile.copy(tempFile.path);

      // Share the file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'User data from the app',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Data File'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserFileInfo,
            tooltip: 'Refresh',
          ),
          if (_fileInfo != null && (_fileInfo!['exists'] as bool))
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportJsonFile,
              tooltip: 'Export JSON File',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_fileInfo == null) {
      return const Center(child: Text('Unable to load file information'));
    }

    if (_fileInfo!.containsKey('error')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading file information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_fileInfo!['error'].toString()),
            ],
          ),
        ),
      );
    }

    final filePath = _fileInfo!['filePath'] as String;
    final exists = _fileInfo!['exists'] as bool;
    final content = _fileInfo!['content'] as String;
    final userCount = _fileInfo!['userCount'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File info
          const Text(
            'File Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoCard([
            _buildKeyValue('File exists', exists ? 'Yes' : 'No'),
            _buildKeyValue('User count', userCount.toString()),
            _buildKeyValue('File path', filePath),
          ]),
          const SizedBox(height: 24),

          // File content
          const Text(
            'File Content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              exists && content.isNotEmpty
                  ? _prettyPrintJson(content)
                  : 'No content available',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$key: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _prettyPrintJson(String jsonString) {
    try {
      final object = jsonDecode(jsonString);
      return const JsonEncoder.withIndent('  ').convert(object);
    } catch (e) {
      return jsonString;
    }
  }

  jsonDecode(String jsonString) {}
}
