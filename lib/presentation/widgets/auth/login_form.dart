import 'package:flutter/material.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_password_field.dart';
import '../../../core/utils/validators.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Email',
          child: AppTextField(
            controller: emailController,
            label: 'Email',
            hintText: 'Masukkan email Anda',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Kata Sandi',
          child: AppPasswordField(
            controller: passwordController,
            label: 'Kata Sandi',
            hintText: 'Masukkan kata sandi',
            validator: Validators.password,
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }
}
