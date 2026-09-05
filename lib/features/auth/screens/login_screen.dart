import 'package:flutter/material.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../presentation/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  late final LoginController _loginController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loginController = AppDependencies.createLoginController()
      ..addListener(_onLoginStateChanged);
  }

  void _onLoginStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _loginController
      ..removeListener(_onLoginStateChanged)
      ..dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await _loginController.login(
      phone: _mobileController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || result == null) {
      final message = _loginController.errorMessage;
      if (mounted && message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    await AppDependencies.sessionController.markAuthenticated(
      driverId: result.driver.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Match the near-white canvas of the supplied brand artwork so the
      // square image bounds are not visible on the login screen.
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              _buildLogo(),
              const SizedBox(height: 48),
              _buildForm(),
              const SizedBox(height: 24),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Semantics(
          label: 'AWA Transport',
          image: true,
          child: Image.asset(
            'assets/branding/awa_transport_logo.png',
            width: 280,
            height: 190,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Delivery Partner Login',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mobile Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              hintText: 'Enter 10-digit mobile number',
              prefixIcon: Icon(
                Icons.phone_android,
                color: AppTheme.textSecondary,
              ),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Mobile number is required';
              }
              if (value.length != 10) {
                return 'Enter a valid 10-digit mobile number';
              }
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                return 'Enter a valid mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _loginController.isLoading ? null : _login,
        child: _loginController.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Login'),
      ),
    );
  }
}
