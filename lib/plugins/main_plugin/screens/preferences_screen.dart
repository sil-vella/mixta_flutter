import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../../core/00_base/screen_base.dart';
import '../../../core/managers/module_manager.dart';
import '../../../core/managers/services_manager.dart';
import '../../../tools/logging/logger.dart';

class PreferencesScreen extends BaseScreen {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Create Account";
  }

  @override
  PreferencesScreenState createState() => PreferencesScreenState();
}

class PreferencesScreenState extends BaseScreenState<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Logger logger = Logger();
  final ServicesManager servicesManager = ServicesManager();

  bool _isLoading = false;
  String _errorMessage = "";

  /// Encrypt password using SHA-256 (One-way encryption)
  String _encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register User: Calls the backend `/register` API
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final connectionModule = ModuleManager().getModule('connection_module');
    final sharedPrefService = servicesManager.getService('shared_pref');

    if (connectionModule == null) {
      logger.error("❌ ConnectionModule not found!");
      setState(() {
        _isLoading = false;
        _errorMessage = "Connection module not available.";
      });
      return;
    } else {
      logger.info("✅ ConnectionModule found!");
    }

    if (sharedPrefService == null) {
      logger.error("❌ SharedPrefManager (service) not found!");
      setState(() {
        _isLoading = false;
        _errorMessage = "Preferences service not available.";
      });
      return;
    } else {
      logger.info("✅ SharedPrefManager found as a service!");
    }

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _encryptPassword(_passwordController.text.trim());

    // ✅ Retrieve points and level from Shared Preferences via ServiceManager
    final points = await sharedPrefService.callServiceMethod('getInt', ['points']) ?? 0;
    final level = await sharedPrefService.callServiceMethod('getInt', ['level']) ?? 1; // ✅ Default to level 1
    logger.info("🏆 Retrieved points: $points | Level: $level");

    try {
      logger.info("⚡ Sending registration request to `/register`...");

      // ✅ Send user details to the backend
      final response = await connectionModule.callMethod(
        'sendPostRequest',
        [
          "/register",
          {
            "username": username,
            "email": email,
            "password": password,
            "points": points,
            "level": level,  // ✅ Include level in registration request
          }
        ],
      );

      logger.info("✅ Response from server: $response");

      if (response != null && response['message'] == "User registered successfully") {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created Successfully!")),
        );
      } else {
        logger.error("❌ Server Error: ${response?["error"]}");
        setState(() {
          _isLoading = false;
          _errorMessage = response?["error"] ?? "Failed to register user.";
        });
      }
    } catch (e) {
      logger.error("❌ Error while connecting to server: $e", error: e);

      setState(() {
        _isLoading = false;
        _errorMessage = "Error: Server is unreachable. Check your network connection.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Create an Account",
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
                validator: (value) => !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value!)
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

              /// Error Message (if any)
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),

              /// Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                child: _isLoading ? const CircularProgressIndicator() : const Text("Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
