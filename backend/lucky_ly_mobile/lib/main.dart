import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'home_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Entry point khởi chạy ứng dụng Flutter.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "2016157219330688",
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
  }
  runApp(const LuckyLyAuthApp());
}

// Widget root cấu hình theme và màn hình khởi đầu.
class LuckyLyAuthApp extends StatelessWidget {
  const LuckyLyAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lucky Ly Auth',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F7FC), // Màu nền sáng dịu nhẹ
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16B4C2)),
        useMaterial3: true,
        fontFamily: 'Roboto', // Sử dụng font mặc định chuẩn
      ),
      home: const AuthScreen(),
    );
  }
}

// Màn hình xác thực chứa cả Sign In và Sign Up (với UI hiện đại & mượt mà).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  // Base URL backend auth API, có thể override qua --dart-define.
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kIsWeb ? 'http://localhost:4000' : 'http://10.0.2.2:4000',
  );

  bool isSignUp = true;
  bool rememberMe = false;
  bool isSubmitting = false;

  final signUpEmailController = TextEditingController();
  final signUpPasswordController = TextEditingController();
  final signUpRepeatPasswordController = TextEditingController();

  final signInLoginController = TextEditingController();
  final signInPasswordController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );
    _slideAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    signUpEmailController.dispose();
    signUpPasswordController.dispose();
    signUpRepeatPasswordController.dispose();
    signInLoginController.dispose();
    signInPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0EA5D8), Color(0xFF19C6C4)], // Gradient nền mượt mà hơn
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(), // Scroll mượt theo chuẩn iOS/Android
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - _slideAnimation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF004C63).withValues(alpha: 0.12),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Responsive Title with Smooth Transition
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, -0.15),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            isSignUp ? 'Create Account' : 'Welcome Back',
                            key: ValueKey<bool>(isSignUp),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1392B1),
                              fontSize: size.width < 360 ? 32 : 36,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSignUp 
                            ? 'Sign up to get started' 
                            : 'Sign in to continue',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8B9CB0),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Sleek Switcher (Bật tắt giữa Sign In/Sign Up)
                        _AuthModeSwitch(
                          isSignUp: isSignUp,
                          onChanged: (value) => setState(() => isSignUp = value),
                        ),
                        const SizedBox(height: 32),
                        
                        // Form với animation tự co giãn kích thước
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                              return Stack(
                                alignment: Alignment.topCenter,
                                children: <Widget>[
                                  ...previousChildren,
                                  // ignore: use_null_aware_elements
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            child: isSignUp ? _buildSignUpForm() : _buildSignInForm(),
                          ),
                        ),
                        
                        const SizedBox(height: 36),
                        
                        // Khu vực đăng nhập Social
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.5)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(
                                  color: Color(0xFF9AA8B8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialButton(icon: Icons.apple, color: Colors.black87, onPressed: () => _showMessage('Apple login tapped.')),
                            SizedBox(width: 20),
                            _SocialButton(icon: Icons.facebook, color: Color(0xFF1877F2), onPressed: _loginWithFacebook),
                            SizedBox(width: 20),
                            _SocialButton(icon: Icons.email, color: Color(0xFFEA4335), onPressed: () => _showMessage('Google login tapped.')),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Nút tác vụ chính với hiệu ứng bóp (scale)
                        _PrimaryGradientButton(
                          text: isSignUp ? 'Sign up' : 'Sign in',
                          isLoading: isSubmitting,
                          onPressed: _handleSubmit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      key: const ValueKey('signup_form'),
      children: [
        _PillInput(
          controller: signUpEmailController,
          hint: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _PillInput(
          controller: signUpPasswordController,
          hint: 'Password',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _PillInput(
          controller: signUpRepeatPasswordController,
          hint: 'Repeat Password',
          icon: Icons.lock_reset_outlined,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: rememberMe,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                activeColor: const Color(0xFF18C7C2),
                side: const BorderSide(color: Color(0xFFCFD9E3), width: 1.5),
                onChanged: (value) {
                  setState(() => rememberMe = value ?? false);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => rememberMe = !rememberMe),
                child: const Text(
                  'I agree to the Terms & Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF7A8D9F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Column(
      key: const ValueKey('signin_form'),
      children: [
        _PillInput(
          controller: signInLoginController,
          hint: 'Username or Email',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _PillInput(
          controller: signInPasswordController,
          hint: 'Password',
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              _showMessage('Forgot password tapped.');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                color: Color(0xFF16B4C2),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (isSubmitting) return;

    if (isSignUp) {
      await _submitSignUp();
    } else {
      await _submitSignIn();
    }
  }

  Future<void> _submitSignUp() async {
    final email = signUpEmailController.text.trim();
    final password = signUpPasswordController.text;
    final repeatPassword = signUpRepeatPasswordController.text;

    if (email.isEmpty || password.isEmpty || repeatPassword.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (password != repeatPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (!_looksLikeEmail(email)) {
      _showMessage('Invalid email format.');
      return;
    }

    final username = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final fullName = email.split('@').first;

    setState(() => isSubmitting = true);
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'fullName': fullName,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = _safeDecodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showMessage('Sign up successful! Please sign in.', isError: false);
        setState(() => isSignUp = false);
      } else {
        _showMessage(body['message']?.toString() ?? 'Sign up failed.');
      }
    } catch (_) {
      _showMessage('Cannot connect to server. Check API_BASE_URL.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _submitSignIn() async {
    final login = signInLoginController.text.trim();
    final password = signInPasswordController.text;

    if (login.isEmpty || password.isEmpty) {
      _showMessage('Please enter login and password.');
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'login': login, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final body = _safeDecodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final user = body['user'] as Map<String, dynamic>?;
        final userLabel = user?['email']?.toString() ?? user?['username']?.toString() ?? 'user';
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(userEmail: userLabel),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      } else {
        _showMessage(body['message']?.toString() ?? 'Sign in failed.');
      }
    } catch (_) {
      _showMessage('Cannot connect to server. Check API_BASE_URL.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _loginWithFacebook() async {
    setState(() => isSubmitting = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        final userLabel = userData['email']?.toString() ?? userData['name']?.toString() ?? 'fb_user';

        final response = await http.post(
          Uri.parse('$_apiBaseUrl/api/auth/facebook-login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'facebookId': userData['id'],
            'email': userData['email'] ?? '',
            'name': userData['name'] ?? 'Facebook User',
            'avatarUrl': userData['picture']?['data']?['url']
          }),
        ).timeout(const Duration(seconds: 15));

        final body = _safeDecodeMap(response.body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(userEmail: userLabel),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          }
        } else {
          _showMessage(body['message']?.toString() ?? 'Failed to save Facebook user to database.');
        }
      } else if (result.status == LoginStatus.cancelled) {
        _showMessage('Facebook login cancelled.');
      } else {
        _showMessage('Facebook login failed: ${result.message}');
      }
    } catch (e) {
      _showMessage('Error during Facebook login: $e');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Map<String, dynamic> _safeDecodeMap(String source) {
    if (source.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          elevation: 10,
        )
      );
  }
}

// Nút chuyển đổi giữa Sign In và Sign Up (có AnimatedContainer mượt mà)
class _AuthModeSwitch extends StatelessWidget {
  const _AuthModeSwitch({required this.isSignUp, required this.onChanged});

  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Màu xám xanh nhạt sang trọng
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: !isSignUp ? Colors.white : Colors.transparent,
                  boxShadow: !isSignUp 
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: !isSignUp ? const Color(0xFF1392B1) : const Color(0xFF94A3B8),
                    fontWeight: !isSignUp ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 16,
                  ),
                  child: const Text('Sign In'),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: isSignUp ? Colors.white : Colors.transparent,
                  boxShadow: isSignUp 
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: isSignUp ? const Color(0xFF1392B1) : const Color(0xFF94A3B8),
                    fontWeight: isSignUp ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 16,
                  ),
                  child: const Text('Sign Up'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ô input dạng pill hiện đại với Icon và hiệu ứng Focus
class _PillInput extends StatefulWidget {
  const _PillInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<_PillInput> createState() => _PillInputState();
}

class _PillInputState extends State<_PillInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 60,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isFocused ? const Color(0xFF16B4C2) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: _isFocused ? [
          BoxShadow(
            color: const Color(0xFF16B4C2).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ] : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.icon,
              key: ValueKey(_isFocused),
              color: _isFocused ? const Color(0xFF16B4C2) : const Color(0xFFA0AEC0),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFA0AEC0),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// Nút action chính có nền gradient, hiệu ứng bấm (Scale) và trạng thái loading.
class _PrimaryGradientButton extends StatefulWidget {
  const _PrimaryGradientButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final Future<void> Function() onPressed;
  final bool isLoading;

  @override
  State<_PrimaryGradientButton> createState() => _PrimaryGradientButtonState();
}

class _PrimaryGradientButtonState extends State<_PrimaryGradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading) _animController.forward();
      },
      onTapUp: (_) {
        if (!widget.isLoading) {
          _animController.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () {
        if (!widget.isLoading) _animController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF199EF0), Color(0xFF18C7C2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF18C7C2).withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Nút Social Login bọc InkWell có hiệu ứng ripple tròn trịa
class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.color, required this.onPressed});

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
      ),
    );
  }
}
