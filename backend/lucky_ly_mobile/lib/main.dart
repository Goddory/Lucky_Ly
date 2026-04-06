import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'home_screen.dart';
import 'app_theme.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';

import 'package:app_links/app_links.dart';
import 'dart:async';
import 'providers/auth_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/store_provider.dart';
import 'core/services/socket_service.dart';
import 'core/services/api_client.dart';

// Entry point khởi chạy ứng dụng Flutter.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo WebView Platform để tránh lỗi "not been set"
  if (WebViewPlatform.instance == null) {
    if (defaultTargetPlatform == TargetPlatform.android) {
        WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }

  // Initialize SQLite factory on desktop before any openDatabase usage.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Khởi tạo Facebook Auth cho web/desktop
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "2016157219330688",
      cookie: true,
      xfbml: true,
      version: "v15.0",
    );
  }

  // Khởi tạo Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyC80tyTajho2-NMSc-y1UyrOCA-kcTFj5s',
        authDomain: 'lucky-ly.firebaseapp.com',
        projectId: 'lucky-ly',
        storageBucket: 'lucky-ly.firebasestorage.app',
        messagingSenderId: '301453242147',
        appId: '1:301453242147:android:40879057464e2f0013e696',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProxyProvider<AuthProvider, FriendProvider>(
          create: (context) => FriendProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => FriendProvider(auth),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, SocketService, ChatProvider>(
          create: (context) => ChatProvider(
            context.read<AuthProvider>(),
            context.read<SocketService>(),
          ),
          update: (context, auth, socket, previous) => ChatProvider(auth, socket),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StoreProvider>(
          create: (context) => StoreProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => StoreProvider(auth),
        ),
      ],
      child: const LuckyLyAuthApp(),
    ),
  );
}

// Widget root cấu hình theme và màn hình khởi đầu.
class LuckyLyAuthApp extends StatelessWidget {
  const LuckyLyAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentAppTheme = AppTheme.getTheme(themeProvider.currentTheme);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lucky Ly Auth',
      theme: ThemeData(
        scaffoldBackgroundColor: currentAppTheme.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: currentAppTheme.primary),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthScreenWrapper(),
    );
  }
}

// Wrapper để logout có thể navigate về đây
class AuthScreenWrapper extends StatelessWidget {
  const AuthScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isSessionHydrated) {
          return const Scaffold(
            body: Center(child: CustomLoading(size: 80)),
          );
        }

        if (!auth.isAuthenticated) {
          return const AuthScreen();
        }

        final restoredUser = Map<String, dynamic>.from(auth.userData ?? <String, dynamic>{});
        final restoredEmail = auth.userEmail ?? restoredUser['email']?.toString() ?? '';

        if (restoredUser['email'] == null && restoredEmail.isNotEmpty) {
          restoredUser['email'] = restoredEmail;
        }

        return HomeScreen(
          userEmail: restoredEmail,
          userData: restoredUser,
          accessToken: auth.accessToken ?? '',
          refreshToken: auth.refreshToken ?? '',
          apiBaseUrl: ApiClient.getBaseUrl(),
        );
      },
    );
  }
}

// Màn hình xác thực chứa cả Sign In và Sign Up (với UI hiện đại & mượt mà).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // Base URL backend auth API
  // Tự động sử dụng Render API khi build APK (release mode), hoặc localhost khi chạy debug
  static final String _apiBaseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
      ? const String.fromEnvironment('API_BASE_URL')
      : (kIsWeb 
          ? 'http://localhost:4000' 
          : ((defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
              ? 'https://lucky-ly-api.onrender.com'
              : 'http://localhost:4000'));

  // Web OAuth client id / server client id dùng để lấy token từ Google.
  static const String _googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '301453242147-i7a769fga6fmvmbdghnguntvhfe87r1c.apps.googleusercontent.com',
  );

  bool isSignUp = true;
  bool rememberMe = false;
  bool isSubmitting = false;
  bool _isSilentSigningIn = false;
  String _deviceId = '';
  bool _googleSignInInitialized = false;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  List<Map<String, String>> _savedAccounts = [];

  final signUpEmailController = TextEditingController();
  final signUpPasswordController = TextEditingController();
  final signUpRepeatPasswordController = TextEditingController();

  final signInLoginController = TextEditingController();
  final signInPasswordController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _loadSavedAccounts();
    _initDeviceId();
    _tryAutoLoginFromSavedSession();
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
    _linkSubscription?.cancel();
    _fadeController.dispose();
    signUpEmailController.dispose();
    signUpPasswordController.dispose();
    signUpRepeatPasswordController.dispose();
    signInLoginController.dispose();
    signInPasswordController.dispose();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was opened via link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // Subscribe to incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Incoming deep link: $uri');
    if ((uri.scheme == 'luckyly' && uri.path == '/claim') || uri.host == 'claim') {
      final token = uri.queryParameters['token'];
      if (token != null) {
         // Handle token
      }
    }
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString('saved_accounts');
      if (savedData != null) {
        final List<dynamic> decoded = jsonDecode(savedData);
        final normalized = decoded
            .map((e) => Map<String, String>.from(e))
            .map((account) => <String, String>{
                  'email': account['email']?.trim() ?? '',
                })
            .where((account) => account['email']!.isNotEmpty)
            .toList();

        await prefs.setString('saved_accounts', jsonEncode(normalized));

        setState(() {
          _savedAccounts = normalized;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved accounts: $e');
    }
  }

  Future<void> _saveAccount(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      // Loại bỏ tài khoản cũ nếu bị trùng số email
      _savedAccounts.removeWhere((acc) => acc['email'] == normalizedEmail);
      // Thêm lên đầu danh sách
      _savedAccounts.insert(0, {'email': normalizedEmail});
      // Chỉ giữ tối đa 5 tài khoản
      if (_savedAccounts.length > 5) {
        _savedAccounts = _savedAccounts.sublist(0, 5);
      }
      await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));
      await prefs.setString('last_login_email', normalizedEmail);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error saving account: $e');
    }
  }

  Future<void> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('device_id');
    if (existing != null && existing.isNotEmpty) {
      _deviceId = existing;
      return;
    }

    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    _deviceId = '$platform-${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('device_id', _deviceId);
  }

  Map<String, String> _buildDeviceInfo() {
    String platform;
    if (kIsWeb) {
      platform = 'web';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          platform = 'android';
          break;
        case TargetPlatform.iOS:
          platform = 'ios';
          break;
        case TargetPlatform.windows:
          platform = 'windows';
          break;
        case TargetPlatform.macOS:
          platform = 'macos';
          break;
        case TargetPlatform.linux:
          platform = 'linux';
          break;
        case TargetPlatform.fuchsia:
          platform = 'fuchsia';
          break;
      }
    }

    return {
      'platform': platform,
      'deviceName': 'LuckyLy $platform app',
      'deviceId': _deviceId.isNotEmpty
          ? _deviceId
          : '$platform-${DateTime.now().millisecondsSinceEpoch}'
    };
  }

  Future<void> _persistSessionTokens({
    required String email,
    required String accessToken,
    required String refreshToken,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || accessToken.isEmpty || refreshToken.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('last_login_email', normalizedEmail);
    await _secureStorage.write(
      key: 'refresh_token_$normalizedEmail',
      value: refreshToken,
    );
    await _saveAccount(normalizedEmail);
  }

  Future<Map<String, dynamic>?> _refreshWithSavedSession(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    final refreshToken = await _secureStorage.read(
      key: 'refresh_token_$normalizedEmail',
    );
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await http
        .post(
          Uri.parse('$_apiBaseUrl/api/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'refreshToken': refreshToken,
            ..._buildDeviceInfo(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await _secureStorage.delete(key: 'refresh_token_$normalizedEmail');
      return null;
    }

    final refreshed = _safeDecodeMap(response.body);
    final accessToken = refreshed['accessToken']?.toString() ?? '';
    final nextRefreshToken = refreshed['refreshToken']?.toString() ?? '';
    if (accessToken.isEmpty || nextRefreshToken.isEmpty) {
      return null;
    }

    await _persistSessionTokens(
      email: normalizedEmail,
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
    );

    return {
      'accessToken': accessToken,
      'refreshToken': nextRefreshToken,
    };
  }

  Future<void> _tryAutoLoginFromSavedSession() async {
    if (_isSilentSigningIn) return;

    _isSilentSigningIn = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginEmail = prefs.getString('last_login_email')?.trim().toLowerCase();
      final candidateEmail = (lastLoginEmail != null && lastLoginEmail.isNotEmpty)
          ? lastLoginEmail
          : (_savedAccounts.isNotEmpty ? (_savedAccounts.first['email'] ?? '') : '');

      if (candidateEmail.isEmpty) {
        return;
      }

      final refreshed = await _refreshWithSavedSession(candidateEmail);
      if (refreshed == null || !mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      authProvider.setSession(
        accessToken: refreshed['accessToken']?.toString() ?? '',
        refreshToken: refreshed['refreshToken']?.toString() ?? '',
        email: candidateEmail,
      );

      // Initialize Socket
      context.read<SocketService>().connect(refreshed['accessToken']!);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userEmail: candidateEmail,
            userData: {'email': candidateEmail},
            accessToken: refreshed['accessToken']?.toString() ?? '',
            refreshToken: refreshed['refreshToken']?.toString() ?? '',
            apiBaseUrl: _apiBaseUrl,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Silent login skipped: $e');
    } finally {
      _isSilentSigningIn = false;
    }
  }

  Future<void> _removeAccount(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _savedAccounts.removeWhere((acc) => acc['email'] == email);
      });
      await prefs.setString('saved_accounts', jsonEncode(_savedAccounts));
    } catch (e) {
      debugPrint('Error removing account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: Provider.of<ThemeProvider>(context).currentTheme == AppThemeType.defaultTheme
                ? const [Color(0xFF0EA5D8), Color(0xFF19C6C4)]
                : AppTheme.of(context).primaryGradient.colors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF004C63,
                          ).withValues(alpha: 0.12),
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
                            isSignUp ? 'Tạo Tài Khoản\nLuckyLy' : 'Chào Mừng Đến\nLuckyLy',
                            key: ValueKey<bool>(isSignUp),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Provider.of<ThemeProvider>(context).currentTheme == AppThemeType.defaultTheme
                                  ? const Color(0xFF1392B1)
                                  : AppTheme.of(context).primary,
                              fontSize: size.width < 360 ? 30 : 32,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSignUp
                              ? 'Đăng ký để bắt đầu trải nghiệm'
                              : 'Đăng nhập để tiếp tục',
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
                          onChanged: (value) =>
                              setState(() => isSignUp = value),
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
                            layoutBuilder:
                                (
                                  Widget? currentChild,
                                  List<Widget> previousChildren,
                                ) {
                                  return Stack(
                                    alignment: Alignment.topCenter,
                                    children: <Widget>[
                                      ...previousChildren,
                                      // ignore: use_null_aware_elements
                                      if (currentChild != null) currentChild,
                                    ],
                                  );
                                },
                            child: isSignUp
                                ? _buildSignUpForm()
                                : _buildSignInForm(),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Khu vực đăng nhập Social
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade200,
                                thickness: 1.5,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Hoặc tiếp tục với',
                                style: TextStyle(
                                  color: Color(0xFF9AA8B8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade200,
                                thickness: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialButton(
                              icon: Icons.facebook,
                              color: const Color(0xFF1877F2),
                              onTap: _handleFacebookLogin,
                            ),
                            const SizedBox(width: 20),
                            _SocialButton(
                              imagePath: 'assets/images/google_logo.png',
                              onTap: _handleGoogleLogin,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Nút tác vụ chính với hiệu ứng bóp (scale)
                        _PrimaryGradientButton(
                          text: isSignUp ? 'Đăng ký' : 'Đăng nhập',
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
          hint: 'Địa chỉ Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _PillInput(
          controller: signUpPasswordController,
          hint: 'Mật khẩu',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: signUpPasswordController,
          builder: (context, value, child) {
            final pass = value.text;
            if (pass.isEmpty) return const SizedBox.shrink();

            final List<String> errors = [];
            if (pass.length < 8) errors.add('Ít nhất 8 ký tự');
            if (!RegExp(r'[A-Z]').hasMatch(pass))
              errors.add('Cần ít nhất 1 chữ hoa');
            if (!RegExp(r'[a-z]').hasMatch(pass))
              errors.add('Cần ít nhất 1 chữ thường');
            if (!RegExp(r'[0-9]').hasMatch(pass))
              errors.add('Cần ít nhất 1 số');
            if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass))
              errors.add('Cần 1 ký tự đặc biệt');

            if (errors.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
              child: Text(
                'Mật khẩu chưa đạt: ${errors.join(", ")}',
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _PillInput(
          controller: signUpRepeatPasswordController,
          hint: 'Nhập lại mật khẩu',
          icon: Icons.lock_reset_outlined,
          isPassword: true,
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: Listenable.merge([
            signUpPasswordController,
            signUpRepeatPasswordController,
          ]),
          builder: (context, child) {
            final pass = signUpPasswordController.text;
            final repeatPass = signUpRepeatPasswordController.text;

            if (repeatPass.isEmpty || pass == repeatPass)
              return const SizedBox.shrink();

            return const Padding(
              padding: EdgeInsets.only(left: 12.0, bottom: 8.0),
              child: Text(
                'Mật khẩu nhập lại không khớp',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: rememberMe,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
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
                  'Tôi đồng ý với Điều khoản & Chính sách bảo mật',
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
          hint: 'Tên đăng nhập hoặc Email',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _PillInput(
          controller: signInPasswordController,
          hint: 'Mật khẩu',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_savedAccounts.isNotEmpty)
              TextButton(
                onPressed: () => _showSavedAccountsSheet(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      'Đăng nhập nhanh',
                      style: TextStyle(
                        color: Provider.of<ThemeProvider>(context).currentTheme == AppThemeType.defaultTheme ? const Color(0xFF16B4C2) : AppTheme.of(context).primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox.shrink(),
            TextButton(
              onPressed: () {
                _showForgotPasswordSheet(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  color: Provider.of<ThemeProvider>(context).currentTheme == AppThemeType.defaultTheme ? const Color(0xFF16B4C2) : AppTheme.of(context).primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSavedAccountsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: 32,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Chọn tài khoản',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1392B1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chọn một tài khoản bạn đã lưu trước đó để tiếp tục.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  if (_savedAccounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Không có tài khoản nào được lưu.'),
                      ),
                    )
                  else
                    ..._savedAccounts.map((acc) {
                      final email = acc['email'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            final refreshed = await _refreshWithSavedSession(email);
                            if (refreshed != null && mounted) {
                              final authProvider = context.read<AuthProvider>();
                              authProvider.setSession(
                                accessToken: refreshed['accessToken']?.toString() ?? '',
                                refreshToken: refreshed['refreshToken']?.toString() ?? '',
                                email: email,
                              );
                              
                              // Initialize Socket
                              context.read<SocketService>().connect(refreshed['accessToken']!);

                              Navigator.pop(ctx);
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => HomeScreen(
                                    userEmail: email,
                                    userData: {'email': email},
                                    accessToken:
                                        refreshed['accessToken']?.toString() ??
                                        '',
                                    refreshToken:
                                        refreshed['refreshToken']?.toString() ??
                                        '',
                                    apiBaseUrl: _apiBaseUrl,
                                  ),
                                ),
                              );
                              return;
                            }

                            signInLoginController.text = email;
                            signInPasswordController.clear();
                            Navigator.pop(ctx);
                            _showMessage('Phiên đăng nhập đã hết hạn, vui lòng nhập mật khẩu.');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_circle,
                                  color: Color(0xFF16B4C2),
                                  size: 36,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _removeAccount(email);
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
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
    _showMessage('Đang kết nối server, vui lòng chờ...', isError: false);
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
              ..._buildDeviceInfo(),
            }),
          )
          .timeout(const Duration(seconds: 90));

      final body = _safeDecodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final authProvider = context.read<AuthProvider>();
        authProvider.setSession(
          accessToken: body['accessToken'],
          refreshToken: body['refreshToken'],
          email: email,
          userData: body['user'],
        );
        await _saveAccount(email);
        await _navigateToHome(body);
      } else {
        _showMessage(body['message']?.toString() ?? 'Đăng ký thất bại.');
      }
    } on TimeoutException {
      _showMessage('Server đang khởi động (Render cold start), vui lòng thử lại sau 30 giây.');
    } catch (_) {
      _showMessage('Không thể kết nối server. Kiểm tra mạng hoặc thử lại.');
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
    _showMessage('Đang kết nối server, vui lòng chờ...', isError: false);
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'login': login,
              'password': password,
              ..._buildDeviceInfo(),
            }),
          )
          .timeout(const Duration(seconds: 90));

      final body = _safeDecodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final authProvider = context.read<AuthProvider>();
        authProvider.setSession(
          accessToken: body['accessToken'],
          refreshToken: body['refreshToken'],
          email: login,
          userData: body['user'],
        );
        await _saveAccount(login);
        await _navigateToHome(body);
      } else {
        _showMessage(body['message']?.toString() ?? 'Đăng nhập thất bại.');
      }
    } on TimeoutException {
      _showMessage('Server đang khởi động (Render cold start), vui lòng thử lại sau 30 giây.');
    } catch (_) {
      _showMessage('Không thể kết nối server. Kiểm tra mạng hoặc thử lại.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // Đăng nhập bằng Facebook: gọi Facebook SDK, gửi thông tin về backend
  Future<void> _handleFacebookLogin() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'id,name,email,picture.width(200)',
        );

        final facebookId = userData['id']?.toString() ?? '';
        final name = userData['name']?.toString() ?? 'Facebook User';
        final email = userData['email']?.toString() ?? '';
        final picture = userData['picture']?['data']?['url']?.toString();

        final response = await http
            .post(
              Uri.parse('$_apiBaseUrl/api/auth/facebook-login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'facebookId': facebookId,
                'name': name,
                'email': email,
                'avatarUrl': picture,
                ..._buildDeviceInfo(),
              }),
            )
            .timeout(const Duration(seconds: 15));

        final body = _safeDecodeMap(response.body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final authProvider = context.read<AuthProvider>();
          authProvider.setSession(
            accessToken: body['accessToken'],
            refreshToken: body['refreshToken'],
            email: email,
            userData: body['user'],
          );
          await _navigateToHome(body);
        } else {
          _showMessage(body['message']?.toString() ?? 'Facebook login failed.');
        }
      } else if (result.status == LoginStatus.cancelled) {
        _showMessage('Facebook login cancelled.');
      } else {
        _showMessage(
          'Facebook login failed: ${result.message ?? "Unknown error"}',
        );
        debugPrint('[Facebook] Error Result: ${result.message}');
      }
    } catch (e) {
      debugPrint('[Facebook] Exception during login: $e');
      _showMessage('Facebook login error: $e');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    if (kIsWeb) {
      await google_auth.GoogleSignIn.instance.initialize(clientId: _googleClientId);
    } else {
      await google_auth.GoogleSignIn.instance.initialize(serverClientId: _googleClientId);
    }

    _googleSignInInitialized = true;
  }

  bool _isGoogleLoginCancelled(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('cancel') ||
        message.contains('popup_closed') ||
        message.contains('popup closed') ||
        message.contains('aborted');
  }

  String _googleErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network')) {
      return 'Google login failed: network error.';
    }

    if (message.contains('api_exception: 10') ||
        message.contains('developer_error') ||
        message.contains('configuration')) {
      return 'Google login failed: OAuth client configuration error.';
    }

    return 'Google login failed. Please try again.';
  }

  // Đăng nhập bằng Google: gọi Google Sign-In, gửi idToken về backend
  Future<void> _handleGoogleLogin() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    try {
      await _ensureGoogleSignInInitialized();

      late final google_auth.GoogleSignInAccount account;
      try {
        account = await google_auth.GoogleSignIn.instance.authenticate(
          scopeHint: ['email', 'profile'],
        );
      } catch (e) {
        debugPrint('GoogleSignIn auth error: $e');
        if (_isGoogleLoginCancelled(e)) {
          _showMessage('Google login cancelled.');
        } else {
          _showMessage(_googleErrorMessage(e));
        }
        return;
      }

      final auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        _showMessage('Google login failed: no valid Google token returned.');
        return;
      }

      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/api/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken, ..._buildDeviceInfo()}),
          )
          .timeout(const Duration(seconds: 90));

      final body = _safeDecodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final authProvider = context.read<AuthProvider>();
        authProvider.setSession(
          accessToken: body['accessToken'],
          refreshToken: body['refreshToken'],
          email: body['user']?['email'] ?? '',
          userData: body['user'],
        );
        await _navigateToHome(body);
      } else {
        _showMessage(body['message']?.toString() ?? 'Google login failed.');
      }
    } on google_auth.GoogleSignInException catch (e) {
      if (e.code == google_auth.GoogleSignInExceptionCode.canceled) {
        _showMessage('Google login cancelled.');
      } else {
        _showMessage('Google login failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Google login unexpected error: $e');
      _showMessage(_googleErrorMessage(e));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  // Chức năng quên mật khẩu: Flow 3 bước (Nhập Email -> Nhập OTP -> Đổi Pass)
  void _showForgotPasswordSheet(BuildContext context) {
    int step = 1; // 1: Email, 2: OTP, 3: New Password
    String userEmail = '';
    String resetOtp = '';
    bool isLoading = false;

    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            Widget buildStepContent() {
              if (step == 1) {
                return Column(
                  children: [
                    Text(
                      'Quên mật khẩu',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1392B1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vui lòng nhập email đăng ký. Chúng tôi sẽ gửi mã OTP cho bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PillInput(
                      controller: emailController,
                      hint: 'Nhập email của bạn',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                );
              } else if (step == 2) {
                return Column(
                  children: [
                    Text(
                      'Xác thực OTP',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1392B1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mã 6 số đã được gửi tới:\n$userEmail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PillInput(
                      controller: otpController,
                      hint: 'Nhập mã 6 số',
                      icon: Icons.security,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Text(
                      'Tạo mật khẩu mới',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1392B1),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PillInput(
                      controller: newPassController,
                      hint: 'Mật khẩu mới',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    _PillInput(
                      controller: confirmPassController,
                      hint: 'Nhập lại mật khẩu',
                      icon: Icons.lock_reset_outlined,
                      isPassword: true,
                    ),
                  ],
                );
              }
            }

            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: bottomInset + 32,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: buildStepContent(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final navigator = Navigator.of(ctx);

                            if (step == 1) {
                              final email = emailController.text.trim();
                              if (email.isEmpty || !_looksLikeEmail(email)) {
                                _showMessage('Vui lòng nhập email hợp lệ');
                                return;
                              }
                              setModalState(() => isLoading = true);

                              try {
                                final res = await http
                                    .post(
                                      Uri.parse(
                                        '$_apiBaseUrl/api/auth/forgot-password',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({'email': email}),
                                    )
                                    .timeout(const Duration(seconds: 15));

                                if (res.statusCode >= 200 &&
                                    res.statusCode < 300) {
                                  userEmail = email;
                                  setModalState(() {
                                    isLoading = false;
                                    step = 2; // Chuyển sang bước nhập OTP
                                  });
                                  _showMessage(
                                    'Mã OTP đã được gửi!',
                                    isError: false,
                                  );
                                } else {
                                  final body = _safeDecodeMap(res.body);
                                  _showMessage(
                                    body['message']?.toString() ??
                                        'Gửi OTP thất bại',
                                  );
                                  setModalState(() => isLoading = false);
                                }
                              } catch (e) {
                                _showMessage('Lỗi mạng. Vui lòng thử lại.');
                                setModalState(() => isLoading = false);
                              }
                            } else if (step == 2) {
                              final otp = otpController.text.trim();
                              if (otp.length != 6) {
                                _showMessage('OTP phải gồm 6 chữ số');
                                return;
                              }

                              setModalState(() => isLoading = true);
                              try {
                                final res = await http
                                    .post(
                                      Uri.parse(
                                        '$_apiBaseUrl/api/auth/verify-reset-otp',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        'email': userEmail,
                                        'otp': otp,
                                      }),
                                    )
                                    .timeout(const Duration(seconds: 15));

                                if (res.statusCode >= 200 &&
                                    res.statusCode < 300) {
                                  resetOtp = otp;
                                  setModalState(() {
                                    isLoading = false;
                                    step = 3; // Chuyển sang bước đổi mật khẩu
                                  });
                                } else {
                                  final body = _safeDecodeMap(res.body);
                                  _showMessage(
                                    body['message']?.toString() ??
                                        'OTP không hợp lệ',
                                  );
                                  setModalState(() => isLoading = false);
                                }
                              } catch (e) {
                                _showMessage('Lỗi mạng. Vui lòng thử lại.');
                                setModalState(() => isLoading = false);
                              }
                            } else if (step == 3) {
                              final newPass = newPassController.text;
                              final confirmPass = confirmPassController.text;

                              if (newPass.isEmpty || confirmPass.isEmpty) {
                                _showMessage('Vui lòng điền đủ mật khẩu');
                                return;
                              }
                              if (newPass != confirmPass) {
                                _showMessage('Mật khẩu nhập lại không khớp');
                                return;
                              }

                              setModalState(() => isLoading = true);
                              try {
                                final res = await http
                                    .post(
                                      Uri.parse(
                                        '$_apiBaseUrl/api/auth/reset-password',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        'email': userEmail,
                                        'otp': resetOtp,
                                        'newPassword': newPass,
                                      }),
                                    )
                                    .timeout(const Duration(seconds: 15));

                                if (res.statusCode >= 200 &&
                                    res.statusCode < 300) {
                                  if (!ctx.mounted) return;
                                  if (navigator.canPop()) navigator.pop();
                                  _showMessage(
                                    'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập.',
                                    isError: false,
                                  );
                                } else {
                                  final body = _safeDecodeMap(res.body);
                                  _showMessage(
                                    body['message']?.toString() ??
                                        'Đặt lại thất bại',
                                  );
                                  setModalState(() => isLoading = false);
                                }
                              } catch (e) {
                                _showMessage('Lỗi kết nối. Thử lại sau.');
                                setModalState(() => isLoading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: const CustomLoading(size: 80),
                          )
                        : Text(
                            step == 1
                                ? 'Gửi mã xác nhận'
                                : (step == 2
                                      ? 'Xác thực OTP'
                                      : 'Xác nhận tạo mới'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToHome(Map<String, dynamic> responseBody) async {
    if (!mounted) return;
    
    // Lưu token vào SharedPreferences để dùng ở các màn hình khác (ví dụ: PaymentScreen)
    final prefs = await SharedPreferences.getInstance();
    final accessToken = responseBody['accessToken']?.toString() ?? '';
    final refreshToken = responseBody['refreshToken']?.toString() ?? '';
    
    if (accessToken.isNotEmpty) {
      await prefs.setString('access_token', accessToken);
      await prefs.setString('accessToken', accessToken);
    }
    if (refreshToken.isNotEmpty) {
      await prefs.setString('refresh_token', refreshToken);
      await prefs.setString('refreshToken', refreshToken);
    }

    final user = responseBody['user'] as Map<String, dynamic>? ?? {};
    final userEmail = user['email']?.toString().trim().toLowerCase() ?? '';

    // Initialize Socket
    if (accessToken.isNotEmpty) {
      context.read<SocketService>().connect(accessToken);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          userEmail: userEmail,
          userData: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
          apiBaseUrl: _apiBaseUrl,
        ),
      ),
    );
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isError
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          elevation: 10,
        ),
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
    final isDefaultTheme = Provider.of<ThemeProvider>(context).currentTheme == AppThemeType.defaultTheme;
    final primaryColor = isDefaultTheme ? const Color(0xFF1392B1) : AppTheme.of(context).primary;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
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
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: !isSignUp
                        ? primaryColor
                        : const Color(0xFF94A3B8),
                    fontWeight: !isSignUp ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 16,
                  ),
                  child: const Text('Đăng nhập'),
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
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: isSignUp
                        ? primaryColor
                        : const Color(0xFF94A3B8),
                    fontWeight: isSignUp ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 16,
                  ),
                  child: const Text('Đăng ký'),
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
    this.isPassword = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;

  @override
  State<_PillInput> createState() => _PillInputState();
}

class _PillInputState extends State<_PillInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
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
    final isDefaultTheme = Provider.of<ThemeProvider>(context).currentTheme == AppThemeType.defaultTheme;
    final primaryColor = isDefaultTheme ? const Color(0xFF16B4C2) : AppTheme.of(context).primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 60,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isFocused ? primaryColor : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.icon,
              key: ValueKey(_isFocused),
              color: _isFocused
                  ? primaryColor
                  : const Color(0xFFA0AEC0),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: _obscureText,
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
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _isFocused
                              ? const Color(0xFF16B4C2)
                              : const Color(0xFFA0AEC0),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (!widget.isPassword) const SizedBox(width: 16),
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

class _PrimaryGradientButtonState extends State<_PrimaryGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
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
    final isDefaultTheme = Provider.of<ThemeProvider>(context).currentTheme == AppThemeType.defaultTheme;
    final primaryGradient = isDefaultTheme ? const LinearGradient(
              colors: [Color(0xFF199EF0), Color(0xFF18C7C2)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ) : AppTheme.of(context).primaryGradient;
    final primaryShadowColor = isDefaultTheme ? const Color(0xFF18C7C2) : AppTheme.of(context).primaryLight;

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
            gradient: primaryGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: primaryShadowColor.withValues(alpha: 0.4),
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
                    child: const CustomLoading(size: 80),
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
  const _SocialButton({
    this.icon,
    this.imagePath,
    this.color,
    required this.onTap,
  });

  final IconData? icon;
  final String? imagePath;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: (color ?? Colors.grey).withValues(alpha: 0.1),
        highlightColor: (color ?? Colors.grey).withValues(alpha: 0.05),
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
          child: imagePath != null
              ? Center(child: Image.asset(imagePath!, width: 30, height: 30))
              : Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }
}
