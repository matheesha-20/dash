import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum AuthView { login, signup }
enum AuthMode { email, phone }

/// ---------------------------------------------------------------------------
/// Main AuthScreen Container
/// ---------------------------------------------------------------------------
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({super.key, required this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthView _currentView = AuthView.login;

  @override
  Widget build(BuildContext context) {
    if (_currentView == AuthView.login) {
      return LoginScreen(
        onBack: () => Navigator.of(context).maybePop(),
        onSwitchToCreate: () => setState(() => _currentView = AuthView.signup),
        onAuthSuccess: widget.onAuthSuccess,
      );
    } else {
      return CreateAccountScreen(
        onBack: () => setState(() => _currentView = AuthView.login),
        onSwitchToLogin: () => setState(() => _currentView = AuthView.login),
        onAuthSuccess: widget.onAuthSuccess,
      );
    }
  }
}

/// ---------------------------------------------------------------------------
/// 1. Login Screen (Firebase)
/// ---------------------------------------------------------------------------
class LoginScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSwitchToCreate;
  final VoidCallback onAuthSuccess;

  const LoginScreen({
    super.key,
    required this.onBack,
    required this.onSwitchToCreate,
    required this.onAuthSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthMode _mode = AuthMode.email;
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  String? _identifierError;
  String? _passwordError;
  String? _formError;
  bool _submitting = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s()\-]'), '');
    return cleaned.length >= 8;
  }

  bool _validate() {
    bool ok = true;
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    setState(() {
      if (_mode == AuthMode.email && !_isValidEmail(identifier)) {
        _identifierError = "Enter a valid email address.";
        ok = false;
      } else if (_mode == AuthMode.phone && !_isValidPhone(identifier)) {
        _identifierError = "Enter a valid phone number.";
        ok = false;
      } else {
        _identifierError = null;
      }

      if (password.isEmpty) {
        _passwordError = "Enter your password.";
        ok = false;
      } else {
        _passwordError = null;
      }
    });

    return ok;
  }

  Future<void> _handleSubmit() async {
    setState(() => _formError = null);
    if (!_validate()) return;

    setState(() => _submitting = true);

    try {
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text;

      if (_mode == AuthMode.email) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );
        widget.onAuthSuccess();
      } else {
        setState(() {
          _formError = "Phone login via password requires OTP setup. Please use Email.";
          _submitting = false;
        });
        return;
      }
    } on FirebaseAuthException catch (err) {
      setState(() {
        _formError = err.message ?? "Authentication failed (${err.code}).";
        _submitting = false;
      });
    } catch (err) {
      setState(() {
        _formError = "Login failed: ${err.toString()}";
        _submitting = false;
      });
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08070D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Welcome back",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Log in to pick up where you left off.",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // Mode Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        label: "Email",
                        icon: Icons.email_outlined,
                        isActive: _mode == AuthMode.email,
                        onTap: () {
                          setState(() {
                            _mode = AuthMode.email;
                            _identifierController.clear();
                            _identifierError = null;
                            _formError = null;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        label: "Phone",
                        icon: Icons.phone_outlined,
                        isActive: _mode == AuthMode.phone,
                        onTap: () {
                          setState(() {
                            _mode = AuthMode.phone;
                            _identifierController.clear();
                            _identifierError = null;
                            _formError = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input
              Text(
                _mode == AuthMode.email ? "Email address" : "Phone number",
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _identifierController,
                keyboardType: _mode == AuthMode.email ? TextInputType.emailAddress : TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (_) {
                  if (_identifierError != null) setState(() => _identifierError = null);
                },
                decoration: _inputDecoration(
                  hint: _mode == AuthMode.email ? "you@example.com" : "+1 555 123 4567",
                  hasError: _identifierError != null,
                ),
              ),
              if (_identifierError != null) _buildFieldError(_identifierError!),

              const SizedBox(height: 20),

              // Password
              const Text(
                "Password",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (_) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
                decoration: _inputDecoration(
                  hint: "Enter your password",
                  hasError: _passwordError != null,
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              if (_passwordError != null) _buildFieldError(_passwordError!),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    if (_identifierController.text.trim().isNotEmpty && _mode == AuthMode.email) {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: _identifierController.text.trim());
                        setState(() => _formError = "Password reset link sent to your email!");
                      } catch (e) {
                        setState(() => _formError = "Error sending password reset email.");
                      }
                    } else {
                      setState(() => _formError = "Please enter your email above first.");
                    }
                  },
                  child: const Text("Forgot password?", style: TextStyle(color: Color(0xFFA9C9FC), fontSize: 12)),
                ),
              ),

              if (_formError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(_formError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),

              // Submit Button
              Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8EC5FC), Color(0xFFD4A5EC)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B1432)))
                      : const Text("Log in", style: TextStyle(color: Color(0xFF1B1432), fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("New to Dash? ", style: TextStyle(color: Colors.white54, fontSize: 13)),
                  GestureDetector(
                    onTap: widget.onSwitchToCreate,
                    child: const Text("Create an account", style: TextStyle(color: Color(0xFFA9C9FC), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({required String label, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive ? const LinearGradient(colors: [Color(0xFF8EC5FC), Color(0xFFD4A5EC)]) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? const Color(0xFF1B1432) : Colors.white60),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isActive ? const Color(0xFF1B1432) : Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldError(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
    );
  }

  InputDecoration _inputDecoration({required String hint, required bool hasError, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: hasError ? Colors.redAccent : const Color(0xFF8EC5FC)),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// 2. Create Account Screen (Firebase Auth + Firestore + Storage)
/// ---------------------------------------------------------------------------
class CreateAccountScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSwitchToLogin;
  final VoidCallback onAuthSuccess;

  const CreateAccountScreen({
    super.key,
    required this.onBack,
    required this.onSwitchToLogin,
    required this.onAuthSuccess,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Uint8List? _avatarBytes;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _passwordFocused = false;
  bool _submitting = false;

  Map<String, String?> _errors = {};
  String? _formError;

  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() => _passwordFocused = _passwordFocusNode.hasFocus);
    });
  }

  Future<void> _handleAvatarPick() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        setState(() => _formError = "Profile picture must be under 5 MB.");
        return;
      }
      setState(() {
        _avatarBytes = bytes;
        _formError = null;
      });
    }
  }

  bool _hasMinLength(String p) => p.length >= 8;
  bool _hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p);
  bool _hasLowercase(String p) => RegExp(r'[a-z]').hasMatch(p);
  bool _hasNumber(String p) => RegExp(r'[0-9]').hasMatch(p);

  bool _isPasswordValid(String p) {
    return _hasMinLength(p) && _hasUppercase(p) && _hasLowercase(p) && _hasNumber(p);
  }

  bool _validate() {
    final newErrors = <String, String?>{};

    if (_nameController.text.trim().length < 2) {
      newErrors['name'] = "Please enter your full name (2+ characters).";
    }
    if (_phoneController.text.replaceAll(RegExp(r'[\s()\-]'), '').length < 8) {
      newErrors['phone'] = "Enter a valid phone number (8+ digits).";
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      newErrors['email'] = "Enter a valid email address.";
    }
    if (!_isPasswordValid(_passwordController.text)) {
      newErrors['password'] = "Password doesn't meet requirements.";
    }
    if (_confirmController.text != _passwordController.text) {
      newErrors['confirm'] = "Passwords don't match.";
    }

    setState(() => _errors = newErrors);
    return newErrors.isEmpty;
  }

  Future<void> _handleSubmit() async {
  setState(() => _formError = null);
  if (!_validate()) return;

  setState(() => _submitting = true);

  try {
    // 1. Create Firebase Auth User
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final user = credential.user;
    if (user == null) throw Exception("User creation failed.");

    String? photoUrl;

    // 2. Upload Avatar to Firebase Storage
    if (_avatarBytes != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
        
        final uploadTask = await ref.putData(
          _avatarBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        photoUrl = await uploadTask.ref.getDownloadURL();
      } catch (storageError) {
        // Storage Fail වුණොත් Console එකේ print කරනවා
        debugPrint("Avatar Upload Error: $storageError");
      }
    }

    // 3. Update Auth Profile
    await user.updateDisplayName(_nameController.text.trim());
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // 4. Save details in Cloud Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    widget.onAuthSuccess();
  } catch (err, stack) {
    // Web එකේ JS Object Cast වෙන Crash එක නවත්වන Safe Error Extraction
    debugPrint("FULL ERROR: $err");
    debugPrint("STACKTRACE: $stack");

    String cleanError = "An unexpected error occurred.";

    if (err is FirebaseAuthException) {
      cleanError = err.message ?? err.code;
    } else if (err is FirebaseException) {
      cleanError = "${err.plugin}/${err.code}: ${err.message ?? ''}";
    } else {
      // Dynamic JS object extraction to prevent 'JavaScriptObject' casting error
      dynamic dynamicErr = err;
      try {
        if (dynamicErr?.message != null) {
          cleanError = dynamicErr.message.toString();
        } else if (dynamicErr?.code != null) {
          cleanError = dynamicErr.code.toString();
        } else {
          cleanError = err.toString();
        }
      } catch (_) {
        cleanError = "Unknown authentication error.";
      }
    }

    setState(() {
      _formError = cleanError;
      _submitting = false;
    });
  }
}
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passwordText = _passwordController.text;

    return Scaffold(
      backgroundColor: const Color(0xFF08070D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Create your account", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text("Join Dash and stay beautifully connected.", style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),

              // DP Picker
              Center(
                child: GestureDetector(
                  onTap: _handleAvatarPick,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                          image: _avatarBytes != null
                              ? DecorationImage(image: MemoryImage(_avatarBytes!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _avatarBytes == null
                            ? const Center(child: Icon(Icons.person, size: 40, color: Colors.white38))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Color(0xFF8EC5FC), Color(0xFFD4A5EC)]),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF1B1432)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildField("Full name", _nameController, hint: "e.g. Alex Rivera", error: _errors['name']),
              const SizedBox(height: 16),
              _buildField("Phone number", _phoneController, hint: "+1 555 123 4567", type: TextInputType.phone, error: _errors['phone']),
              const SizedBox(height: 16),
              _buildField("Email", _emailController, hint: "you@example.com", type: TextInputType.emailAddress, error: _errors['email']),
              const SizedBox(height: 16),
              _buildField(
                "Password",
                _passwordController,
                hint: "Create a strong password",
                obscureText: !_showPassword,
                focusNode: _passwordFocusNode,
                error: _errors['password'],
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),

              if ((_passwordFocused || _errors['password'] != null) && passwordText.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ruleRow("8+ characters", _hasMinLength(passwordText)),
                      _ruleRow("Uppercase letter", _hasUppercase(passwordText)),
                      _ruleRow("Lowercase letter", _hasLowercase(passwordText)),
                      _ruleRow("Number", _hasNumber(passwordText)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildField(
                "Confirm password",
                _confirmController,
                hint: "Re-enter password",
                obscureText: !_showConfirm,
                error: _errors['confirm'],
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              const SizedBox(height: 20),

              if (_formError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text(_formError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],

              Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8EC5FC), Color(0xFFD4A5EC)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                  child: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B1432)))
                      : const Text("Create account", style: TextStyle(color: Color(0xFF1B1432), fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(color: Colors.white54, fontSize: 13)),
                  GestureDetector(
                    onTap: widget.onSwitchToLogin,
                    child: const Text("Log in", style: TextStyle(color: Color(0xFFA9C9FC), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ruleRow(String text, bool passed) {
    return Row(
      children: [
        Icon(passed ? Icons.check_circle : Icons.circle_outlined, size: 14, color: passed ? Colors.greenAccent : Colors.white30),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: passed ? Colors.white70 : Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required String hint,
    TextInputType type = TextInputType.text,
    bool obscureText = false,
    FocusNode? focusNode,
    String? error,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: type,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError ? Colors.redAccent : const Color(0xFF8EC5FC)),
            ),
          ),
        ),
        if (hasError) Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      ],
    );
  }
}