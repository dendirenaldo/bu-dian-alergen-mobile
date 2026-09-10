import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/validators.dart';

class RegisterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  const RegisterForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          validator: (value) => Validators.minLength(value, 2, 'Nama'),
          decoration: const InputDecoration(
            hintText: 'Nama Lengkap',
            prefixIcon: Icon(LucideIcons.user),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(LucideIcons.mail),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          validator: Validators.password,
          decoration: InputDecoration(
            hintText: 'Kata Sandi',
            prefixIcon: const Icon(LucideIcons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
              ),
              onPressed: onTogglePassword,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmPassword,
          validator: (value) => Validators.confirmPassword(value, passwordController.text),
          decoration: InputDecoration(
            hintText: 'Konfirmasi Kata Sandi',
            prefixIcon: const Icon(LucideIcons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword
                    ? LucideIcons.eyeOff
                    : LucideIcons.eye,
              ),
              onPressed: onToggleConfirmPassword,
            ),
          ),
        ),
      ],
    );
  }
}
