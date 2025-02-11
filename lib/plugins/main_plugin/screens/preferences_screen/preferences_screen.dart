import 'package:flutter/material.dart';
import '../../../../core/00_base/screen_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../modules/login_module/login_module.dart';
import 'components/user_login.dart';
import 'components/user_register.dart';

class PreferencesScreen extends BaseScreen {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Account Settings";
  }

  @override
  PreferencesScreenState createState() => PreferencesScreenState();
}

class PreferencesScreenState extends BaseScreenState<PreferencesScreen> {
  final Logger logger = Logger();
  final loginModule = LoginModule();
  final sharedPrefService = ServicesManager().getService('shared_pref');

  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  bool _showRegisterForm = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    if (sharedPrefService == null) {
      logger.error("❌ SharedPrefManager not found!");
      return;
    }

    final username = await sharedPrefService?.callServiceMethod('getString', ['username']);
    final email = await sharedPrefService?.callServiceMethod('getString', ['email']);
    final isLoggedIn = await sharedPrefService?.callServiceMethod('getBool', ['is_logged_in']) ?? false;

    logger.info("📝 Checking login status -> Username: $username, Email: $email, isLoggedIn: $isLoggedIn");

    setState(() {
      _username = username;
      _email = email;
      _isLoggedIn = isLoggedIn;
    });
  }

  /// ✅ Handle user login
  Future<void> _loginUser() async {
    final response = await loginModule.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (response.containsKey("success")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["success"])),
      );
      await _checkLoginStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["error"] ?? "Login failed."), backgroundColor: Colors.red),
      );
    }
  }

  /// ✅ Handle user logout
  Future<void> _logoutUser() async {
    if (sharedPrefService == null) return;

    await sharedPrefService?.callServiceMethod('setBool', ['is_logged_in', false]);
    await sharedPrefService?.callServiceMethod('remove', ['username']);
    await sharedPrefService?.callServiceMethod('remove', ['email']);

    setState(() {
      _isLoggedIn = false;
      _username = null;
      _email = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully.")),
    );
  }

  /// ✅ UI for Logged-in Users
  Widget _buildLogoutView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Account Details",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Text("Username: $_username"),
        Text("Email: $_email"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _logoutUser,
          child: const Text("Logout"),
        ),
      ],
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isLoggedIn
            ? _buildLogoutView()
            : _showRegisterForm
            ? RegisterWidget(
          onRegister: (username, email, password) async {
            final result = await loginModule.registerUser(username: username, email: email, password: password);
            if (result.containsKey("success")) {
              await _checkLoginStatus();
              setState(() => _showRegisterForm = false);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result["error"] ?? "Registration failed."), backgroundColor: Colors.red),
              );
            }
          },
          onBackToLogin: () => setState(() => _showRegisterForm = false),
        )
            : LoginWidget(
          emailController: _emailController,
          passwordController: _passwordController,
          onLogin: _loginUser,
          onRegisterToggle: () => setState(() => _showRegisterForm = true),
        ),
      ),
    );
  }
}
