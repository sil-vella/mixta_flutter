import 'package:flutter/material.dart';

class LoginWidget extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onRegisterToggle;

  const LoginWidget({
    Key? key,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onRegisterToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Login",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        /// Email Field
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "Email"),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),

        /// Password Field
        TextFormField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: "Password"),
          obscureText: true,
        ),
        const SizedBox(height: 20),

        /// Login Button
        ElevatedButton(
          onPressed: onLogin,
          child: const Text("Login"),
        ),

        const SizedBox(height: 10),

        /// Toggle to Registration Form
        TextButton(
          onPressed: onRegisterToggle,
          child: const Text("Register a new user"),
        ),
      ],
    );
  }
}
