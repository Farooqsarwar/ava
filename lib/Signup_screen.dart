import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_auth_service.dart';
import 'login_screen.dart';
import 'home_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
  bool isLoadingGoogle = false;
  final supabase = Supabase.instance.client;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Google Sign-In method
  Future<void> _signInWithGoogle() async {
    setState(() => isLoadingGoogle = true);

    try {
      final user = await _googleAuthService.signInWithGoogle();

      if (user != null && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingGoogle = false);
      }
    }
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Sign up user
      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        data: {
          'username': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );

      if (response.user != null) {
        // The trigger should automatically create the user profile
        // Wait a moment for the trigger to execute
        await Future.delayed(const Duration(seconds: 2));

        // Verify the user profile was created
        try {
          final userProfile = await supabase
              .from('users')
              .select()
              .eq('id', response.user!.id)
              .single();

          if (userProfile.isEmpty) {
            // If trigger failed, try manual insert
            await _createUserProfile(response.user!);
          }
        } catch (e) {
          print('User profile check failed: $e');
          // Continue anyway as auth user is created
        }

        // Show success message and navigate to login
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please check your email for verification.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to login screen after a short delay
          await Future.delayed(const Duration(seconds: 2));

          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getUserFriendlyError(e.message)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Unexpected error during signup: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getUserFriendlyError(String error) {
    if (error.contains('User already registered')) {
      return 'This email is already registered. Please try logging in.';
    } else if (error.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('Password should be at least')) {
      return 'Password must be at least 6 characters long.';
    } else if (error.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    } else {
      return error;
    }
  }

  Future<void> _createUserProfile(User user) async {
    try {
      await supabase.from('users').insert({
        'id': user.id,
        'username': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'email_verified': false,
      });
    } catch (e) {
      print('Failed to create user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          height: MediaQuery.sizeOf(context).height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4BA1AE),
                Color(0xFF73B5C1),
                Color(0xFF82BDC8),
                Color(0xFF92C6CF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset("assets/L6.png"),
                    const SizedBox(height: 10),
                    const Text(
                      "Smart Care, Anytime, Anywhere",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildTextField(nameController, "Name", Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(emailController, "Email", Icons.email, email: true),
                    const SizedBox(height: 16),
                    _buildTextField(phoneController, "Phone", Icons.phone, phone: true),
                    const SizedBox(height: 16),
                    _buildTextField(passwordController, "Password", Icons.lock, password: true),
                    const SizedBox(height: 16),

                    // Register Button
                    SizedBox(
                      width: 100,
                      height: 60,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white54,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: isLoading ? null : registerUser,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OR divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.black.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.black.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Sign-In Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: isLoadingGoogle ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        icon: isLoadingGoogle
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                            : Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.login, size: 24);
                          },
                        ),
                        label: isLoadingGoogle
                            ? const Text('Signing in...')
                            : const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool email = false,
        bool phone = false,
        bool password = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: password && !isPasswordVisible,
        keyboardType: phone
            ? TextInputType.phone
            : email
            ? TextInputType.emailAddress
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          prefixIcon: Icon(icon),
          prefixIconColor: Colors.black,
          suffixIcon: password
              ? IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
          )
              : null,
          suffixIconColor: password ? Colors.black : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF000000)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF000000)),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Please enter $label";
          if (email && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return "Enter a valid email";
          }
          if (phone && !RegExp(r'^\d{10,15}$').hasMatch(value)) {
            return "Enter a valid phone number";
          }
          if (password && value.length < 6) {
            return "Password must be at least 6 characters";
          }
          return null;
        },
      ),
    );
  }
}