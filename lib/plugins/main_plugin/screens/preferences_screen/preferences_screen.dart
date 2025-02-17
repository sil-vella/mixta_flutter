import 'package:flutter/material.dart';
import '../../../../core/00_base/screen_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../modules/connections_module/connections_module.dart';
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

  Map<String, dynamic> _categories = {};
  String? _selectedCategory = "Mixed";
  int _categoryPoints = 0;
  int _categoryLevel = 1;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchCategories();
    _loadCategoryProgress();
  }

  /// ✅ Fetch stored category progress from SharedPreferences
  Future<void> _loadCategoryProgress() async {
    if (sharedPrefService == null) return;

    final savedCategory = await sharedPrefService?.callServiceMethod('getString', ['category']) ?? "Mixed";
    final points = await sharedPrefService?.callServiceMethod('getInt', ['points_$savedCategory']) ?? 0;
    final level = await sharedPrefService?.callServiceMethod('getInt', ['level_$savedCategory']) ?? 1;

    setState(() {
      _selectedCategory = savedCategory;
      _categoryPoints = points;
      _categoryLevel = level;
    });

    logger.info("📊 Loaded progress: $_selectedCategory -> Points: $_categoryPoints | Level: $_categoryLevel");
  }

  /// ✅ Handle category selection & update SharedPreferences
  Future<void> _updateCategory(String category) async {
    if (sharedPrefService == null) return;

    final points = await sharedPrefService?.callServiceMethod('getInt', ['points_$category']) ?? 0;
    final level = await sharedPrefService?.callServiceMethod('getInt', ['level_$category']) ?? 1;

    setState(() {
      _selectedCategory = category;
      _categoryPoints = points;
      _categoryLevel = level;
    });

    await sharedPrefService?.callServiceMethod('setString', ['category', category]);
    logger.info("✅ Selected Category Updated: $category");
  }

  /// ✅ Fetch categories from SharedPreferences first, fallback to backend if needed
  Future<void> _fetchCategories() async {
    if (sharedPrefService == null) return;

    List<String> cachedCategories = await sharedPrefService?.callServiceMethod('getStringList', ['available_categories']) ?? [];

    if (cachedCategories.isNotEmpty) {
      logger.info('📜 Loaded categories from SharedPreferences: $cachedCategories');

      setState(() {
        _categories = {for (var cat in cachedCategories) cat: {"levels": 1}};
      });

      return;
    }

    logger.error('⚠️ No categories found in SharedPreferences.');
  }

  Future<void> _checkLoginStatus() async {
    if (sharedPrefService == null) return;

    final username = await sharedPrefService?.callServiceMethod('getString', ['username']);
    final email = await sharedPrefService?.callServiceMethod('getString', ['email']);
    final isLoggedIn = await sharedPrefService?.callServiceMethod('getBool', ['is_logged_in']) ?? false;

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
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Account Details",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Text("Username: $_username"),
        Text("Email: $_email"),
        const SizedBox(height: 10),
        Text("Category: $_selectedCategory"),
        Text("Points: $_categoryPoints"),
        Text("Level: $_categoryLevel"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _logoutUser,
          child: const Text("Logout"),
        ),
      ],
    );
  }

  /// ✅ Category Selector Modal
  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: _categories.keys.map((category) {
                      return ListTile(
                        title: Text(category.toUpperCase()),
                        trailing: _selectedCategory == category
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          _updateCategory(category);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _showCategorySelector,
            child: const Text("Select Category"),
          ),

          const SizedBox(height: 10),
          Text(
            "Selected Category: $_selectedCategory",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            "Points: $_categoryPoints",
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            "Level: $_categoryLevel",
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: _isLoggedIn
                  ? _buildUserInfo()
                  : _showRegisterForm
                  ? RegisterWidget(
                onRegister: (username, email, password) async {
                  final result = await loginModule.registerUser(
                    username: username,
                    email: email,
                    password: password,
                  );
                  if (result.containsKey("success")) {
                    await _checkLoginStatus();
                    setState(() => _showRegisterForm = false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result["error"] ?? "Registration failed."),
                        backgroundColor: Colors.red,
                      ),
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
          ),
        ],
      ),
    );
  }
}