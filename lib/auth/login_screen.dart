import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/auth/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isCheckingUsers = true;
  bool _hasUsers = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkIfUsersExist();
  }

  Future<void> _checkIfUsersExist() async {
    setState(() {
      _isCheckingUsers = true;
    });

    try {
      final userCount = await _authService.getUserCount();
      setState(() {
        _hasUsers = userCount > 0;
        _isCheckingUsers = false;
      });
    } catch (e) {
      setState(() {
        _hasUsers = false;
        _isCheckingUsers = false;
      });
      print('Error checking users: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Check if any users exist
        final userCount = await _authService.getUserCount();
        if (userCount == 0) {
          setState(() {
            _errorMessage =
                'No accounts exist. Please create an account first.';
            _isLoading = false;
          });
          return;
        }

        final user = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null) {
          // Login successful
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.isLoggedInKey, true);
          await prefs.setString(AppConstants.userNameKey, user.name);
          await prefs.setString('user_email', user.email);

          if (mounted) {
            Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
          }
        } else {
          // Login failed
          setState(() {
            _errorMessage = 'Invalid email or password';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
        print('Login error: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _isCheckingUsers
                ? const Center(child: CircularProgressIndicator())
                : _buildLoginContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App icon
          Icon(
            Icons.travel_explore,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to continue',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // No users message
          if (!_hasUsers)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade800),
              ),
              child: Column(
                children: [
                  Text(
                    'No accounts found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please create an account to get started',
                    style: TextStyle(color: Colors.amber.shade900),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Error message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red.shade900),
                textAlign: TextAlign.center,
              ),
            ),
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Login button
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Login'),
          ),
          const SizedBox(height: 16),
          // Register link
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.signupRoute);
            },
            child: const Text('Don\'t have an account? Sign up'),
          ),
          // Debug info
          FutureBuilder<int>(
            future: _authService.getUserCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Registered users: ${snapshot.data}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
