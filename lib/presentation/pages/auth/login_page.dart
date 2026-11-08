import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/routes.dart';
import '../../../services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isGuestNavigating = false;

  Future<void> _continueAsGuest() async {
    if (_isGuestNavigating) return;
    setState(() => _isGuestNavigating = true);
    try {
      await StorageService().setOnboardingComplete();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isGuestNavigating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan. Coba lagi.')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.main,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    await auth.login(
      email,
      _passwordController.text,
    );

    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
    } else if (auth.isEmailNotVerified) {
      // Email belum diverifikasi: tampilkan banner + aksi kirim ulang.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Email belum diverifikasi'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Kirim ulang',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: () => _handleResend(email),
          ),
        ),
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Coba lagi',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: _handleLogin,
          ),
        ),
      );
    }
  }

  Future<void> _handleResend(String email) async {
    final auth = context.read<AuthProvider>();
    final result = await auth.resendVerification(email);
    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data ?? 'Tautan verifikasi telah dikirim'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          action: SnackBarAction(
            label: 'Verifikasi',
            textColor: Theme.of(context).colorScheme.onSecondary,
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.verifyEmail,
                arguments: <String, dynamic>{'email': email},
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? auth.error ?? 'Gagal mengirim ulang'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.science,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk melanjutkan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                LoginForm(
                  emailController: _emailController,
                  passwordController: _passwordController,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: const Text('Lupa password?'),
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (!auth.isEmailNotVerified) return const SizedBox.shrink();
                    final pending = auth.pendingEmail ?? _emailController.text.trim();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mark_email_unread_outlined,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email belum diverifikasi. Cek inbox atau kirim ulang tautan.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => _handleResend(pending),
                            child: const Text('Kirim ulang'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final err = auth.error;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (err != null) ...[
                          Semantics(
                            liveRegion: true,
                            label: err,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color:
                                        Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      err,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : _handleLogin,
                                    child: const Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Semantics(
                          button: true,
                          enabled: !auth.isLoading,
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  auth.isLoading ? null : _handleLogin,
                              child: auth.isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                      ),
                                    )
                                  : const Text('Masuk'),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    child: Text.rich(
                      TextSpan(
                        text: "Belum punya akun? ",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        children: [
                          TextSpan(
                            text: 'Daftar',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _isGuestNavigating ? null : _continueAsGuest,
                    child: const Text('Lanjutkan tanpa akun'),
                  ),
                ),
                Center(
                  child: Text(
                    'Tanpa masuk, deteksi hanya bisa 5x per jam.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
