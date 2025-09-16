import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_controller.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/snackbars.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../data/token_storage.dart';
import 'package:local_auth/local_auth.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _remember = true;
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final storage = ref.read(tokenStorageProvider);
      final saved = await storage.savedEmail();
      final remember = await storage.rememberMe();
      if (saved != null && remember) {
        _emailController.text = saved;
      }
      final localAuth = LocalAuthentication();
      _canUseBiometric = await localAuth.isDeviceSupported() && await localAuth.canCheckBiometrics;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        showErrorSnackbar(context, next.error.toString());
      }
      final user = next.valueOrNull;
      if (user != null) {
        context.go('/');
      }
    });

    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Masuk')),
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
                        Text('Forum Alumni', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: Validators.email,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                          validator: Validators.password,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _remember,
                              onChanged: (v) => setState(() => _remember = v ?? true),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            const Text('Ingat saya'),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              child: const Text('Daftar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: 'Masuk',
                          isLoading: isLoading,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await ref.read(authControllerProvider.notifier).login(
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                    remember: _remember,
                                  );
                            }
                          },
                        ),
                        if (_canUseBiometric) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final localAuth = LocalAuthentication();
                              try {
                                final ok = await localAuth.authenticate(
                                  localizedReason: 'Masuk dengan biometrik',
                                  options: const AuthenticationOptions(biometricOnly: true),
                                );
                                if (ok) {
                                  final storage = ref.read(tokenStorageProvider);
                                  final hasToken = await storage.hasValidAccessToken() || await storage.hasRefreshToken();
                                  if (hasToken) {
                                    await ref.read(authControllerProvider.notifier).restoreSession();
                                  } else {
                                    showErrorSnackbar(context, 'Tidak ada sesi tersimpan. Masuk terlebih dahulu.');
                                  }
                                }
                              } catch (e) {
                                showErrorSnackbar(context, 'Biometrik gagal: $e');
                              }
                            },
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Masuk dengan biometrik'),
                          ),
                        ],
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
