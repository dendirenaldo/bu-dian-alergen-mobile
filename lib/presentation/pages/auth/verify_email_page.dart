import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

/// Halaman verifikasi email.
///
/// Mendukung tiga alur:
/// 1. Deep link berisi token (`budian://verify-email?token=` atau
///    `https://<domain>/verify-email?token=`) → otomatis verifikasi.
/// 2. Input manual token dari email (fallback bila link tidak terbuka di app).
/// 3. Kirim ulang tautan verifikasi ke [email] (pending register / login
///    403 EMAIL_NOT_VERIFIED).
class VerifyEmailPage extends StatefulWidget {
  final String? token;
  final String? email;

  const VerifyEmailPage({super.key, this.token, this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  late final TextEditingController _emailController;
  bool _autoAttempted = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.token ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    final initialToken = widget.token?.trim() ?? '';
    if (initialToken.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_autoAttempted) {
          _autoAttempted = true;
          _handleVerify(auto: true);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Isi email pending dari provider bila argumen kosong.
    if (_emailController.text.trim().isEmpty) {
      final pending = context.read<AuthProvider>().pendingEmail;
      if (pending != null && pending.trim().isNotEmpty) {
        _emailController.text = pending.trim();
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify({bool auto = false}) async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.verifyEmail(_tokenController.text.trim());
    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data ?? 'Email berhasil diverifikasi'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } else if (!auto || mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? auth.error ?? 'Gagal memverifikasi email'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Coba lagi',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: _handleVerify,
          ),
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || Validators.email(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email valid untuk kirim ulang')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final result = await auth.resendVerification(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? (result.data ?? 'Tautan verifikasi telah dikirim')
              : (result.error ?? auth.error ?? 'Gagal mengirim ulang verifikasi'),
        ),
        backgroundColor: result.isSuccess
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cek Email Anda',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kami mengirim tautan verifikasi. Buka tautan dari email, '
                  'atau tempel token di bawah bila tautan tidak membuka aplikasi.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Token Verifikasi',
                  hintText: 'Tempel token dari email',
                  controller: _tokenController,
                  textInputAction: TextInputAction.done,
                  isRequired: true,
                  validator: (v) => Validators.required(v, 'Token'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email (untuk kirim ulang)',
                  hintText: 'nama@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (_) => null,
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final success = auth.successMessage;
                    if (success != null && success.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  success,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleVerify,
                            child: auth.isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).colorScheme.surface,
                                    ),
                                  )
                                : const Text('Verifikasi Email'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: auth.isLoading ? null : _handleResend,
                            child: const Text('Kirim Ulang Email'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRoutes.login,
                                (route) => false,
                              );
                            },
                            child: const Text('Kembali ke Masuk'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
