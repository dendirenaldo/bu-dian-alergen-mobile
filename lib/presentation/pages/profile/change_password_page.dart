import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_password_field.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/password_strength_meter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password berhasil diubah'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? auth.error ?? 'Gagal mengubah password'),
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
      appBar: AppBar(title: const Text('Ubah Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPasswordField(
                  label: 'Password Saat Ini',
                  hintText: 'Masukkan password saat ini',
                  controller: _currentController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Password saat ini'),
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
                  label: 'Konfirmasi Password Baru',
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
                            : const Text('Simpan Password'),
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
