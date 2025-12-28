import 'dart:async'; // Timer için gerekli
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kampus_bildirim/services/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLogin = true;

  // Tasarım için ana renk
  final Color _primaryColor = const Color.fromARGB(255, 41, 37, 89);

  // --- SLIDER (VEGAS) DEĞİŞKENLERİ ---
  int _currentImageIndex = 0;
  late Timer _timer;

  // Resim yollarının pubspec.yaml ile uyumlu olduğundan emin ol
  final List<String> _backgroundImages = [
    "assets/images/login_bg/vegas-imgs/3.jpg",
    "assets/images/login_bg/vegas-imgs/4.jpg",
    "assets/images/login_bg/vegas-imgs/17.jpg",
    "assets/images/login_bg/vegas-imgs/19.jpg",
    "assets/images/login_bg/vegas-imgs/21.jpg",
    "assets/images/login_bg/vegas-imgs/22.jpg",
    "assets/images/login_bg/vegas-imgs/25.jpg",
    "assets/images/login_bg/vegas-imgs/27.jpg",
    "assets/images/login_bg/vegas-imgs/28.jpg",
    "assets/images/login_bg/vegas-imgs/31.jpg",
    "assets/images/login_bg/vegas-imgs/32.jpg",
    "assets/images/login_bg/vegas-imgs/34.jpg",
    "assets/images/login_bg/vegas-imgs/35.jpg",
    "assets/images/login_bg/vegas-imgs/36.jpg",
    "assets/images/login_bg/vegas-imgs/37.jpg",
    "assets/images/login_bg/vegas-imgs/38.jpg",
    "assets/images/login_bg/vegas-imgs/39.jpg",
    "assets/images/login_bg/vegas-imgs/45.jpg",
    "assets/images/login_bg/vegas-imgs/51.jpg",
  ];

  String? _selectedDepartment;
  final List<String> _departments = [
    "Bilgisayar Mühendisliği",
    "Elektrik-Elektronik Müh.",
    "Makine Mühendisliği",
    "Mimarlık",
    "İdari Personel",
    "Güvenlik",
    "Öğrenci İşleri",
  ];

  @override
  void initState() {
    super.initState();
    // 5 saniyede bir resim değiştiren zamanlayıcı
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % _backgroundImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Sayfadan çıkınca timer'ı durdur
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  /// Şifre sıfırlama dialogunu göster
  void _showPasswordResetDialog() {
    final resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: Colors.blue),
                SizedBox(width: 10),
                Text('Şifre Sıfırlama'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'E-posta adresinizi girin. Şifre sıfırlama bağlantısı göndereceğiz.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = resetEmailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen e-posta adresinizi girin'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _sendPasswordResetEmail(email);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Gönder'),
              ),
            ],
          ),
    );
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(email: email);

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                icon: const Icon(
                  Icons.mark_email_read,
                  size: 60,
                  color: Colors.green,
                ),
                title: const Text('E-posta Gönderildi!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi. Lütfen gelen kutunuzu kontrol edin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = ref.read(authServiceProvider);
        if (_isLogin) {
          await authService.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          await authService.register(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            surname: _surnameController.text.trim(),
            department: _selectedDepartment!,
          );
        }
        if (mounted) {
          await _saveFcmToken();
          context.go("/home");
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      debugPrint('FCM Token hatası: $e');
    }
  }

  // Modern Input Tasarımı Yardımcı Metodu
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BURADA STACK KULLANIYORUZ (Resim + Perde + Form)
    return Scaffold(
      body: Stack(
        children: [
          // 1. KATMAN: Arka Plan Resim Slider'ı (AnimatedSwitcher)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500), // Geçiş süresi
              child: Image.asset(
                _backgroundImages[_currentImageIndex],
                // Key, resim değiştiğinde animasyonun tetiklenmesi için şarttır
                key: ValueKey<String>(_backgroundImages[_currentImageIndex]),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // 2. KATMAN: Karanlık Perde (Yazıların okunması için)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // Üst kısım: Hafif karartma (Kampüs görünsün)
                    Colors.black.withValues(alpha: 0.3),

                    // Orta kısım: Biraz daha koyu
                    Colors.black.withValues(alpha: 0.5),

                    // Alt kısım: Tam koyu (Formun arkası net olsun)
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  // Geçiş durakları (0.0 = Başlangıç, 1.0 = Bitiş)
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 3. KATMAN: Form İçeriği
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO ALANI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 80,
                      width: 80,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Başlık Yazısı
                  const Text(
                    "Kampüs Bildirim",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4.0,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _isLogin
                        ? "Hoş geldiniz, lütfen giriş yapın."
                        : "Aramıza katılmak için formu doldurun.",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // FORM KARTI
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, // Kartın içi beyaz kalsın
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // KAYIT OLMA ALANLARI
                          if (!_isLogin) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameController,
                                    decoration: _buildInputDecoration(
                                      "Ad",
                                      Icons.person,
                                    ),
                                    validator:
                                        (val) =>
                                            (!_isLogin &&
                                                    (val == null ||
                                                        val.isEmpty))
                                                ? "Gerekli"
                                                : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _surnameController,
                                    decoration: _buildInputDecoration(
                                      "Soyad",
                                      Icons.person_outline,
                                    ),
                                    validator:
                                        (val) =>
                                            (!_isLogin &&
                                                    (val == null ||
                                                        val.isEmpty))
                                                ? "Gerekli"
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              items:
                                  _departments.map((dept) {
                                    return DropdownMenuItem(
                                      value: dept,
                                      child: Text(
                                        dept,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                              onChanged:
                                  (value) => setState(
                                    () => _selectedDepartment = value,
                                  ),
                              decoration: _buildInputDecoration(
                                "Birim",
                                Icons.school,
                              ),
                              validator:
                                  (val) =>
                                      (!_isLogin && val == null)
                                          ? "Seçiniz"
                                          : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ORTAK ALANLAR (Email & Password)
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _buildInputDecoration(
                              "E-Posta",
                              Icons.email,
                            ),
                            validator:
                                (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'E-posta gerekli'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: _buildInputDecoration(
                              "Şifre",
                              Icons.lock,
                            ),
                            validator:
                                (value) =>
                                    (value == null || value.isEmpty)
                                        ? 'Şifre gerekli'
                                        : null,
                          ),

                          // Şifremi Unuttum (Sadece Login'de)
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _showPasswordResetDialog(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade600,
                                ),
                                child: const Text(
                                  'Şifremi Unuttum?',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 24),

                          // ANA BUTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        _isLogin ? "GİRİŞ YAP" : "KAYIT OL",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ALT DEĞİŞTİRME BUTONU
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin ? "Hesabınız yok mu?" : "Zaten üye misiniz?",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isLogin ? "Kayıt Olun" : "Giriş Yapın",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
