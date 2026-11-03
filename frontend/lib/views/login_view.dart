import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/api_service.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/auth_provider.dart';
import 'package:fixops_frontend/views/register_view.dart';
import 'package:fixops_frontend/widgets/glass_container.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemo(String email, String pass) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = pass;
    });
  }

  void _showServerConfig() {
    final serverController = TextEditingController(text: ApiService().baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Configure Backend Host',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Set the API endpoint for your local network or server:\n'
                '• Web / Localhost: http://127.0.0.1:8000/api/v1\n'
                '• Android Emulator: http://10.0.2.2:8000/api/v1\n'
                '• Physical LAN Device: http://<LAN_IP>:8000/api/v1',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: serverController,
                decoration: const InputDecoration(
                  labelText: 'Base API URL',
                  prefixIcon: Icon(Icons.link, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(ctx);
                      final newUrl = serverController.text.trim();
                      await ApiService().setCustomBaseUrl(newUrl);
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text('Server URL set to: $newUrl'),
                        ),
                      );
                    },
                    child: const Text('Save Host'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: GlassBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GlassContainer(
                blur: 24,
                opacity: 0.82,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(220), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon & Header
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(90),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.build_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'FIXOPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Facility Operations & Issue Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Quick Role Demo Selector Chips
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cream.withAlpha(120),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondary.withAlpha(90), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'QUICK DEMO ROLES (Click to Autofill):',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _demoChip(
                                label: 'Admin (Web)',
                                accentColor: AppColors.primary,
                                onTap: () => _fillDemo('admin', 'admin'),
                              ),
                              _demoChip(
                                label: 'Technician',
                                accentColor: AppColors.secondary,
                                onTap: () => _fillDemo('tech', 'tech'),
                              ),
                              _demoChip(
                                label: 'Student / Staff',
                                accentColor: AppColors.accentLime,
                                onTap: () => _fillDemo('user', 'user'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    const Text(
                      'Username or Email',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'admin, tech, or user@fixops.local',
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    const Text(
                      'Password',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign In Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, Color(0xFFFF6433)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(95),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final email = _emailController.text.trim();
                                final pass = _passwordController.text;
                                if (email.isEmpty || pass.isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Please enter email/username and password')),
                                  );
                                  return;
                                }
                                final ok = await auth.login(email, pass);
                                if (!ok && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.primary,
                                      content: Text(auth.errorMessage ?? 'Invalid login credentials'),
                                    ),
                                  );
                                }
                              },
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Sign In to Portal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterView()),
                            );
                          },
                          child: const Text(
                            'Create One',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Server Host Button
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.settings_ethernet_rounded, size: 16, color: AppColors.textMuted),
                        label: const Text('Configure Host / LAN IP', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        onPressed: _showServerConfig,
                      ),
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

  Widget _demoChip({
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(210),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withAlpha(160), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
