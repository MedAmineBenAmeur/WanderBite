import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:WanderBite/auth/models/user_model.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  static const _fileName = 'users.json';

  // Get the file path
  Future<File> get _userFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Load users from file
  Future<List<User>> _loadUsers() async {
    try {
      final file = await _userFile;

      // Check if file exists
      if (!await file.exists()) {
        await file.create();
        await file.writeAsString('[]');
        return [];
      }

      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(contents) as List<dynamic>;
      return jsonList.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print('Error loading users: $e');
      return [];
    }
  }

  // Save users to file
  Future<void> _saveUsers(List<User> users) async {
    try {
      final file = await _userFile;
      final jsonList = users.map((user) => user.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving users: $e');
    }
  }

  // Register a new user
  Future<bool> register(String name, String email, String password) async {
    try {
      // Load existing users
      final users = await _loadUsers();

      // Check if email already exists
      final emailExists =
          users.any((user) => user.email.toLowerCase() == email.toLowerCase());
      if (emailExists) {
        return false; // Email already in use
      }

      // Add new user
      final newUser = User(
        name: name,
        email: email,
        password: password,
      );

      users.add(newUser);

      // Save updated users list
      await _saveUsers(users);

      return true; // Registration successful
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Login user
  Future<User?> login(String email, String password) async {
    try {
      // Load existing users
      final users = await _loadUsers();

      // Find user with matching email and password
      final user = users.firstWhere(
        (user) =>
            user.email.toLowerCase() == email.toLowerCase() &&
            user.password == password,
        orElse: () => User(name: '', email: '', password: ''),
      );

      // Check if user was found
      if (user.email.isEmpty) {
        return null; // Login failed
      }

      return user; // Login successful
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.isLoggedInKey) ?? false;

      if (!isLoggedIn) {
        return null; // No user logged in
      }

      final userEmail = prefs.getString('user_email');
      if (userEmail == null) {
        return null;
      }

      // Load users and find current one
      final users = await _loadUsers();
      return users.firstWhere(
        (user) => user.email.toLowerCase() == userEmail.toLowerCase(),
        orElse: () => User(name: '', email: '', password: ''),
      );
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String email,
    String? newName,
    String? newEmail,
    String? newPassword,
    String? profileImagePath,
  }) async {
    try {
      // Load existing users
      final users = await _loadUsers();

      // Find index of user with matching email
      final index = users.indexWhere(
          (user) => user.email.toLowerCase() == email.toLowerCase());

      if (index == -1) {
        return false; // User not found
      }

      // Update user
      final oldUser = users[index];
      final updatedUser = oldUser.copyWith(
        name: newName,
        email: newEmail,
        password: newPassword,
        profileImagePath: profileImagePath,
      );

      users[index] = updatedUser;

      // Save updated users list
      await _saveUsers(users);

      // Update shared preferences if email was changed
      if (newEmail != null && newEmail != email) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', newEmail);
      }

      // Update name in shared preferences if it was changed
      if (newName != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userNameKey, newName);
      }

      return true; // Update successful
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Save profile image and return the path
  Future<String?> saveProfileImage(XFile imageFile, String userEmail) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${directory.path}/profile_images');

      // Create directory if it doesn't exist
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      // Generate unique filename
      final filename =
          'profile_${userEmail.hashCode}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = '${profileImagesDir.path}/$filename';

      // Copy the image file
      final savedImage = await File(imageFile.path).copy(savedImagePath);

      // Update user with image path
      await updateUserProfile(
        email: userEmail,
        profileImagePath: savedImagePath,
      );

      return savedImagePath;
    } catch (e) {
      print('Error saving profile image: $e');
      return null;
    }
  }

  // Get current number of registered users (for debugging)
  Future<int> getUserCount() async {
    final users = await _loadUsers();
    return users.length;
  }

  // NEW METHOD: Get user file information for debugging
  Future<Map<String, dynamic>> getUserFileInfo() async {
    try {
      final file = await _userFile;
      final exists = await file.exists();
      String content = '';

      if (exists) {
        content = await file.readAsString();
      } else {
        content = 'File does not exist yet';
      }

      return {
        'filePath': file.path,
        'exists': exists,
        'content': content,
        'userCount': await getUserCount(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}
