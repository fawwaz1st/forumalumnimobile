import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/auth_controller.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/password_strength_indicator.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/snackbars.dart';
import '../../shared/widgets/loading_overlay.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        showErrorSnackbar(context, next.error.toString());
      } else if (next.hasValue && next.value != null) {
        showSuccessSnackbar(context, 'Registrasi berhasil');
        context.go('/');
      }
    });

    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Daftar Akun')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Buat Akun Baru', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _nameCtrl,
                          label: 'Nama Lengkap',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (v) => Validators.requiredField(v, fieldName: 'Nama'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: Validators.email,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _passwordCtrl,
                          label: 'Password',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                          validator: Validators.password,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 8),
                        PasswordStrengthIndicator(password: _passwordCtrl.text),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _confirmCtrl,
                          label: 'Konfirmasi Password',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                          validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Daftar',
                          isLoading: isLoading,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await ref.read(authControllerProvider.notifier).register(
                                    _nameCtrl.text.trim(),
                                    _emailCtrl.text.trim(),
                                    _passwordCtrl.text,
                                  );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Sudah punya akun? Masuk'),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
