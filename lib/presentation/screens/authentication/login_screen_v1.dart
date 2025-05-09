import 'package:amd_chat_ai/config/user_storage.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:amd_chat_ai/config/dio_clients.dart';
import 'package:amd_chat_ai/model/sign_up_response.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberLogin = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();

    // Validate initial state of fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_emailController.text.isNotEmpty) {
        _validateEmail(_emailController.text);
      }

      if (_passwordController.text.isNotEmpty) {
        _validatePassword(_passwordController.text);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required';
      });
    } else if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Email format invalid';
      });
    } else {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _validatePassword(String password) {
    setState(() {
      _passwordError = password.isEmpty ? 'Password is required' : null;
    });
  }

  bool get _isFormValid =>
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _isValidEmail(_emailController.text) &&
      _emailError == null &&
      _passwordError == null;

  Future<SignUpResponse?> login(String email, String password) async {
    try {
      final response = await DioClients.authClient.post(
        '/api/v1/auth/password/sign-in',
        data: {'email': email, 'password': password},
      );
      final signInResponse = SignUpResponse.fromJson(response.data);
      await UserStorage.saveUserInfo(signInResponse);
      return signInResponse;
    } on DioException catch (e) {
      debugPrint('Signin error: ${e.response?.data ?? e.message}');
      return null;
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showCustomSnackBar('Please fill in all fields', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await login(email, password);

      if (!mounted) return;

      if (response != null) {
        Navigator.pushReplacementNamed(context, '/chat-ai');
      } else {
        _showCustomSnackBar('Invalid email or password', isError: true);
      }
    } catch (e) {
      if (!mounted) return;

      _showCustomSnackBar('An error occurred: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showCustomSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF4CAF50),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
      elevation: 6,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'DISMISS',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Welcome back to login!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to your account. Get easier than search engines results.',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        _validateEmail(_emailController.text.trim());
                      }
                    },
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.mail_outline,
                          color: Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        errorText: _emailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            if (_isValidEmail(value)) {
                              _emailError = null;
                            }
                          });
                        }
                      },
                      onEditingComplete: () {
                        _validateEmail(_emailController.text.trim());
                        FocusScope.of(context).nextFocus();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        _validatePassword(_passwordController.text.trim());
                      }
                    },
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[400],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey[400],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        errorText: _passwordError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _passwordError =
                              value.isEmpty ? 'Password is required' : null;
                        });
                      },
                      onEditingComplete: () {
                        _validatePassword(_passwordController.text.trim());
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberLogin,
                        onChanged: (value) {
                          setState(() {
                            _rememberLogin = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Text(
                        'Remember login info',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to forget password screen
                      Navigator.pushNamed(context, '/forget-password');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    (_isSubmitting || !_isFormValid) ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  disabledBackgroundColor: Colors.grey[300],
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Or sign in with using',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Handle Google sign in
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(color: Colors.grey[200]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://www.google.com/favicon.ico',
                      height: 18,
                      width: 18,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                          color: Colors.red,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Continue With Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
