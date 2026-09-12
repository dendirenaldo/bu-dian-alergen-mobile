import 'package:flutter/material.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_password_field.dart';
import '../../../core/utils/validators.dart';

class RegisterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const RegisterForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Nama Lengkap',
          child: AppTextField(
            controller: nameController,
            label: 'Nama Lengkap',
            hintText: 'Masukkan nama lengkap Anda',
            prefixIcon: Icons.person_outline,
            validator: (value) => Validators.minLength(value, 2, 'Nama'),
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
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
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: 'Konfirmasi Kata Sandi',
          child: AppPasswordField(
            controller: confirmPasswordController,
            label: 'Konfirmasi Kata Sandi',
            hintText: 'Masukkan ulang kata sandi',
            validator: (value) => Validators.confirmPassword(value, passwordController.text),
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }
}
