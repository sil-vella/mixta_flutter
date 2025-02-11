import 'package:flutter/material.dart';

class RegisterWidget extends StatefulWidget {
  final Future<void> Function(String username, String email, String password) onRegister;
  final VoidCallback onBackToLogin;

  const RegisterWidget({
    Key? key,
    required this.onRegister,
    required this.onBackToLogin,
  }) : super(key: key);

  @override
  _RegisterWidgetState createState() => _RegisterWidgetState();
}

class _RegisterWidgetState extends State<RegisterWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isRegistering = false;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isRegistering = true;
    });

    await widget.onRegister(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isRegistering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Register",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          /// Username Field
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: "Username"),
            validator: (value) => value!.length < 5 ? "Username must be at least 5 characters long." : null,
          ),
          const SizedBox(height: 10),

          /// Email Field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
            !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value!)
                ? "Enter a valid email."
                : null,
          ),
          const SizedBox(height: 10),

          /// Password Field
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
            validator: (value) => value!.length < 8 ? "Password must be at least 8 characters long." : null,
          ),
          const SizedBox(height: 20),

          /// Register Button
          ElevatedButton(
            onPressed: _isRegistering ? null : _registerUser,
            child: _isRegistering ? const CircularProgressIndicator() : const Text("Create Account"),
          ),

          const SizedBox(height: 10),

          /// Toggle to Login Form
          TextButton(
            onPressed: widget.onBackToLogin,
            child: const Text("Back to Login"),
          ),
        ],
      ),
    );
  }
}
