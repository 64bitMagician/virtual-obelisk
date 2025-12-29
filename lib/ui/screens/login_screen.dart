import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true; // Toggle between "Login" and "Sign Up" views

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Simulates the backend call
  Future<void> _handleAuth() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Fake Network Delay (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      // Navigate to the App Shell (Home)
      // We use 'go' instead of 'push' to clear the history
      // (so you can't click "Back" to return to login)
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use LayoutBuilder to detect if we are on Desktop or Mobile
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // DESKTOP LAYOUT: Split Screen
            return Row(
              children: [
                // Left Side: The Art
                Expanded(
                  flex: 1, // Takes 50% width
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Image
                        Image.network(
                          'https://picsum.photos/id/1015/1000/1000',
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.6), // Darken it slightly
                          colorBlendMode: BlendMode.darken,
                        ),
                        // Overlay Text
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.brush, size: 80, color: Colors.white),
                              SizedBox(height: 20),
                              Text(
                                "ArtFlow",
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Where creativity connects.",
                                style: TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Right Side: The Form
                Expanded(
                  flex: 1, // Takes 50% width
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(32),
                      child: _buildForm(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // MOBILE LAYOUT: Simple Centered Form
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.brush, size: 60, color: Colors.deepPurple),
                      const SizedBox(height: 16),
                      Text(
                        "ArtFlow",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildForm(),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isLogin ? "Welcome Back" : "Join the Community",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Email Input
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Password Input
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),

        // Main Action Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleAuth,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_isLogin ? "Login" : "Create Account"),
        ),
        const SizedBox(height: 16),

        // Toggle Login/Signup
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
            });
          },
          child: Text(
            _isLogin
                ? "Don't have an account? Sign Up"
                : "Already have an account? Login",
          ),
        ),
      ],
    );
  }
}