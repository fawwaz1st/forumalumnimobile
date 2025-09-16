import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_controller.dart';
import '../../shared/utils/validators.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/snackbars.dart';
import '../../shared/widgets/modern_loading_overlay.dart';
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

    return ModernLoadingOverlay(
      isLoading: isLoading,
      loadingText: 'Sedang masuk...',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo dan Welcome Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.forum_rounded,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Selamat Datang',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masuk ke akun Forum Alumni Anda',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: Validators.email,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscureText: true,
                              showPasswordToggle: true,
                              prefixIcon: const Icon(Icons.lock_outline),
                              validator: Validators.password,
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _remember,
                                  onChanged: (v) => setState(() => _remember = v ?? true),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                const Text('Ingat saya'),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 24),
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
                              const SizedBox(height: 16),
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
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Masuk dengan biometrik'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Daftar sekarang'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
