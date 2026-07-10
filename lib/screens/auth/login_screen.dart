import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: 20),
            const _AuthBrandHeader(
              title: 'PromoHunter',
              subtitle: 'Masuk untuk lanjut berburu promo hemat.',
            ),
            const SizedBox(height: 34),
            Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Masuk',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Lihat password'
                              : 'Sembunyikan password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    if (auth.errorMessage != null) ...[
                      _AuthError(message: auth.errorMessage!),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: auth.isLoading ? null : () => _submit(auth),
                      child: Text(auth.isLoading ? 'Memproses...' : 'Masuk'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed:
                          auth.isLoading ? null : () => _submitGoogle(auth),
                      icon: const _GoogleMark(),
                      label: const Text('Masuk dengan Google'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AuthSwitchAction(
              text: 'Belum punya akun?',
              action: 'Daftar',
              onTap: () => Navigator.pushNamed(context, AppRoutes.register),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      await _finishLogin(auth);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.errorMessage ?? 'Login gagal')),
    );
  }

  Future<void> _submitGoogle(AuthProvider auth) async {
    final ok = await auth.loginWithGoogle();
    if (!mounted) return;
    if (ok) {
      await _finishLogin(auth);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.errorMessage ?? 'Login Google gagal')),
    );
  }

  Future<void> _finishLogin(AuthProvider auth) async {
    final userId = auth.currentUser?.id;
    if (userId != null) {
      final favoriteProvider = context.read<FavoriteProvider>();
      final reminderProvider = context.read<ReminderProvider>();
      final shoppingListProvider = context.read<ShoppingListProvider>();
      await favoriteProvider.bootstrapForUser(userId);
      await reminderProvider.bootstrapForUser(userId);
      await shoppingListProvider.bootstrap(userId);
      if (!mounted) return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (_) => false,
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AuthBrandHeader extends StatelessWidget {
  const _AuthBrandHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7EE),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.local_offer_rounded,
            color: Color(0xFF059669),
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
      ],
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF991B1B),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _AuthSwitchAction extends StatelessWidget {
  const _AuthSwitchAction({
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        Text(
          '$text ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(action),
        ),
      ],
    );
  }
}
