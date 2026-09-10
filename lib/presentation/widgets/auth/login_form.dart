import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/validators.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }
}
