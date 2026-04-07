// lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();

  @override
  void dispose() {
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login(AuthViewModel vm) async {
    FocusScope.of(context).unfocus();
    final success = await vm.login();
    if (success && mounted) widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Consumer<AuthViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor:          Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                _Header(),

                // ── Form ────────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Title
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize:   26,
                            fontWeight: FontWeight.w800,
                            color:      AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to your technician account',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 32),

                        // Phone
                        _FieldLabel('Mobile Number'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:   _phoneCtrl,
                          focusNode:    _phoneFocus,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: vm.setPhone,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passwordFocus),
                          decoration: const InputDecoration(
                            hintText:    'Enter your 10-digit number',
                            prefixIcon:  Icon(Icons.phone_outlined,
                                color: AppColors.textGrey),
                            prefixText:  '+91 ',
                            prefixStyle: TextStyle(
                                color:      AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize:   14),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password
                        _FieldLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller:      _passCtrl,
                          focusNode:       _passwordFocus,
                          obscureText:     !vm.isPasswordVisible,
                          onChanged:       vm.setPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(vm),
                          decoration: InputDecoration(
                            hintText:   'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppColors.textGrey),
                            suffixIcon: GestureDetector(
                              onTap: vm.togglePasswordVisibility,
                              child: Icon(
                                vm.isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textGrey,
                                size:  20,
                              ),
                            ),
                          ),
                        ),

                        // Error
                        if (vm.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(vm.errorMessage!),
                        ],

                        const SizedBox(height: 32),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: vm.isLoading ? null : () => _login(vm),
                            child: vm.isLoading
                                ? const SizedBox(
                                    width:  22,
                                    height: 22,
                                    child:  CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Footer
                        Center(
                          child: Text(
                            'Speedonet Technician Portal v1.0',
                            style: TextStyle(
                              fontSize: 12,
                              color:    AppColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 40,
        bottom: 40,
        left:   24,
        right:  24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width:  72,
            height: 72,
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.engineering_rounded,
              color: Colors.white,
              size:  36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SPEEDONET',
            style: TextStyle(
              color:       Colors.white,
              fontSize:    22,
              fontWeight:  FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Technician Portal',
            style: TextStyle(
              color:    Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize:   13,
      fontWeight: FontWeight.w600,
      color:      AppColors.textDark,
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color:        AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.primary, size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(
              color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    ]),
  );
}
