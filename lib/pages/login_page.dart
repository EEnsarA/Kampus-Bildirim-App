import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  void dispose() {
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
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
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
        // Başarı dialogu göster
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
                      'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi. '
                      'Lütfen gelen kutunuzu kontrol edin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Not: Spam/Gereksiz klasörünü de kontrol etmeyi unutmayın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.orange),
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
          context.go("/home");
        }
      } catch (e) {
        if (mounted) {
          // Exception mesajından "Exception: " prefix'ini temizle
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
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        // Her durumda yükleniyor'u durdur
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/logo.png", height: 120),
                const SizedBox(height: 20),
                Text(
                  "Kampüs Bildirim",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                if (!_isLogin) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Ad",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          validator:
                              (val) =>
                                  (!_isLogin && (val == null || val.isEmpty))
                                      ? "Ad gerekli"
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _surnameController,
                          decoration: const InputDecoration(
                            labelText: "Soyad",
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (val) =>
                                  (!_isLogin && (val == null || val.isEmpty))
                                      ? "Soyad gerekli"
                                      : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    items:
                        _departments.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(dept),
                          );
                        }).toList(),
                    onChanged:
                        (value) => setState(() => _selectedDepartment = value),
                    decoration: InputDecoration(
                      labelText: "Birim / Bölüm",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.school,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    validator:
                        (val) =>
                            (!_isLogin && val == null)
                                ? "Lütfen birim seçiniz"
                                : null,
                  ),
                ],
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "E-Posta",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.email,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen e-posta giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Şifre",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.lock,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifre giriniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(240, 41, 37, 89),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              _isLogin ? "Giriş Yap" : "Kayıt Ol",
                              style: TextStyle(fontSize: 18),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                // Şifremi Unuttum butonu (sadece giriş modunda)
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showPasswordResetDialog(),
                      child: const Text(
                        'Şifremi Unuttum',
                        style: TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                          });
                        },
                        icon: Icon(
                          _isLogin ? Icons.person_add : Icons.login,
                          size: 24,
                        ),
                        label: Text(
                          _isLogin ? "Kayıt Ol" : "Giriş Yap",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
