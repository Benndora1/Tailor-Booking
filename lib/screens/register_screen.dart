import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedRole = 'user'; // Default role is 'user'
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Handles registration with email and password
  Future<void> _registerWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Basic validation
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _nameController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all required fields.';
          _isLoading = false;
        });
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match.';
          _isLoading = false;
        });
        return;
      }

      // Additional validation for tailors
      if (_selectedRole == 'tailor' && _phoneController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Phone number is required for tailors.';
          _isLoading = false;
        });
        return;
      }

      // Call registerWithEmailAndPassword with all the required info
      final user = await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (user != null) {
        if (!mounted) return; // Ensure the widget is still mounted before navigating

        if (_selectedRole == 'tailor') {
          // Show pending approval dialog for tailor registrations
          _showPendingApprovalMessage(context);
        } else {
          // Normal user registration - go to login page
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show the pending approval message for tailors
  void _showPendingApprovalMessage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            FaIcon(FontAwesomeIcons.hourglass, color: Colors.orange),
            SizedBox(width: 12),
            Text('Application Pending'),
          ],
        ),
        content: const Text(
          'Thank you for registering as a tailor. Your application is pending approval from our administrators. '
              'You will be notified when your application is approved. Until then, you can log in as a regular user.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Create Account',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: FaIcon(FontAwesomeIcons.user),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: FaIcon(FontAwesomeIcons.envelope),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: FaIcon(FontAwesomeIcons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 16),

            // Confirm password field
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: FaIcon(FontAwesomeIcons.lockOpen),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 16),

            // Role selection
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Normal User')),
                DropdownMenuItem(value: 'tailor', child: Text('Tailor')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value ?? 'user'; // Default to 'user' if null
                });
              },
              decoration: InputDecoration(
                labelText: 'Select Role',
                prefixIcon: _selectedRole == 'tailor'
                    ? const FaIcon(FontAwesomeIcons.cut)
                    : const FaIcon(FontAwesomeIcons.userCircle),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Conditional fields for tailors
            if (_selectedRole == 'tailor') ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Tailor Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Phone number field
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: FaIcon(FontAwesomeIcons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              const SizedBox(height: 16),

              // Bio field
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio/Description (Optional)',
                  prefixIcon: FaIcon(FontAwesomeIcons.infoCircle),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.exclamationCircle, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ElevatedButton(
              onPressed: _isLoading ? null : _registerWithEmail,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  FaIcon(FontAwesomeIcons.userPlus),
                  SizedBox(width: 12),
                  Text('Register'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _authService.signInWithGoogle,
              icon: const FaIcon(
                FontAwesomeIcons.google,
                size: 20,
                color: Colors.red, // Google's brand color
              ),
              label: const Text('Register with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 1,
              ),
            ),
            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const FaIcon(FontAwesomeIcons.signInAlt, size: 16),
              label: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}