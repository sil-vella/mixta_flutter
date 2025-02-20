import 'package:flutter/material.dart';
import 'package:mixta_guess_who/plugins/game_plugin/modules/function_helper_module/function_helper_module.dart';
import 'package:mixta_guess_who/plugins/game_plugin/screens/progress_screen/progress_screen.dart';
import '../../../../core/00_base/screen_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/navigation_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../../../utils/consts/theme_consts.dart';
import '../../modules/connections_module/connections_module.dart';
import '../../modules/login_module/login_module.dart';
import 'components/user_login.dart';
import 'components/user_register.dart';

class PreferencesScreen extends BaseScreen {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Profile";
  }

  @override
  PreferencesScreenState createState() => PreferencesScreenState();
}

class PreferencesScreenState extends BaseScreenState<PreferencesScreen> {
  final Logger logger = Logger();
  final loginModule = LoginModule();
  final sharedPrefService = ServicesManager().getService('shared_pref');
  final functionsHelperModule = FunctionHelperModule();

  bool _isLoggedIn = false;
  String? _username;
  String? _email;
  bool _showRegisterForm = false;
  String? _selectedCategory = "Mixed"; // Stores the currently selected category

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadSelectedCategory();
  }

  /// ✅ Fetch stored category selection from SharedPreferences
  Future<void> _loadSelectedCategory() async {
    if (sharedPrefService == null) return;

    final savedCategory = await sharedPrefService?.callServiceMethod('getString', ['category']) ?? "Mixed";

    setState(() {
      _selectedCategory = savedCategory;
    });

    logger.info("📊 Loaded selected category: $_selectedCategory");
  }

  /// ✅ Handle category selection & update SharedPreferences
  Future<void> _updateCategory(String category) async {
    if (sharedPrefService == null) return;

    await sharedPrefService?.callServiceMethod('setString', ['category', category]);

    setState(() {
      _selectedCategory = category;
    });

    logger.info("✅ Selected Category Updated: $category");
    Navigator.pop(context); // Close modal after selection
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


  /// ✅ UI for showing category selection modal
  void _showCategorySelector() async {
    if (sharedPrefService == null) return;

    // ✅ Properly await the result before using it
    List<String> categories = await sharedPrefService!.callServiceMethod('getStringList', ['available_categories']) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final formattedCategory = _formatCategory(category); // Format the category name
                    return ListTile(
                      title: Text(formattedCategory),
                      trailing: _selectedCategory == category
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () => _updateCategory(category),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper function to format category names
  String _formatCategory(String category) {
    // Replace underscores with spaces
    String formatted = category.replaceAll('_', ' ');
    // Capitalize the first letter of each word
    formatted = formatted.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return formatted;
  }


  /// ✅ Show confirmation dialog before deleting the account
  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This will undo all your progress"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteUser();
    }
  }

  Future<void> _deleteUser() async {
    try {
      Logger().info("🧹 deleting user...");
      final response = await loginModule.deleteUser();

      if (response != null && response.containsKey("success")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["success"])),
        );
        await functionsHelperModule.clearUserProgress();
        // ✅ Redirect to login screen after deletion
        await _logoutUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?["error"] ?? "Failed to delete account."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      logger.error("❌ Error deleting user: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error. Please check your connection."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20), // ✅ Better spacing

            // Select Category Button
            OutlinedButton.icon(
              onPressed: _showCategorySelector,
              icon: const Icon(Icons.category, color: AppColors.accentColor),
              label: Text(
                "Selected Category: ${_formatCategory(_selectedCategory!)}",
                style: AppTextStyles.buttonText,
              ),
            ),
            const SizedBox(height: 20),
            _isLoggedIn
                ? _buildUserSection()
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
            const SizedBox(height: 10),

            // ✅ View Progress Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  NavigationContainer().navigateTo(context, "/progress");
                },
                child: const Text("View Your Progress"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Improved User Info Section with Card Layout
  Widget _buildUserSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: AppColors.primaryColor,
      elevation: 4,
      margin: AppPadding.defaultPadding,
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account Details",
              style: AppTextStyles.headingMedium(color: AppColors.accentColor),
            ),
            const Divider(
              color: AppColors.lightGray,
              thickness: 1,
            ),
            const SizedBox(height: 10),
            Text(
              "👤 Username: $_username",
              style: AppTextStyles.bodyMedium,
            ),
            Text(
              "📧 Email: $_email",
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Action Buttons - Logout & Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logout Button
                OutlinedButton(
                  onPressed: _logoutUser,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentColor,
                    side: const BorderSide(color: AppColors.accentColor),
                  ),
                  child: const Text("Logout"),
                ),

                // Delete Account Button
                ElevatedButton(
                  onPressed: _confirmDeleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    "Delete Account",
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}