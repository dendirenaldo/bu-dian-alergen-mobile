import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_password_field.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/password_strength_meter.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({super.key, this.token = ''});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.token);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.resetPassword(
      token: _tokenController.text.trim(),
      newPassword: _newController.text,
    );
    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.data ?? 'Password berhasil direset'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? auth.error ?? 'Gagal mereset password'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Coba lagi',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: _handleSubmit,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Buat Password Baru',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan token dari email dan password baru Anda.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Token',
                  hintText: 'Tempel token reset',
                  controller: _tokenController,
                  textInputAction: TextInputAction.next,
                  isRequired: true,
                  validator: (v) => Validators.required(v, 'Token'),
                ),
                const SizedBox(height: 16),
                AppPasswordField(
                  label: 'Password Baru',
                  hintText: 'Minimal 8 karakter',
                  controller: _newController,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                PasswordStrengthMeter(password: _newController.text),
                const SizedBox(height: 16),
                AppPasswordField(
                  label: 'Konfirmasi Password',
                  hintText: 'Ulangi password baru',
                  controller: _confirmController,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirmPassword(v, _newController.text),
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
                                  color:
                                      Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : _handleSubmit,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleSubmit,
                        child: auth.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              )
                            : const Text('Reset Password'),
                      ),
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
