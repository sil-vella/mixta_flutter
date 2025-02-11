import 'package:flutter/material.dart';
import '../../utils/consts/theme_consts.dart';
import '../managers/navigation_manager.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NavigationContainer navContainer = NavigationContainer();

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primaryColor), // ✅ Use primary theme color instead of blue
            child: Text(
              'Navigation Menu',
              style: AppTextStyles.headingMedium(color: AppColors.accentColor), // 🌟 Gold Accent
            ),
          ),

          ...navContainer.drawerItems.map((item) => ListTile(
            leading: Icon(item.icon),
            title: Text(item.label),
            onTap: () {
              Navigator.pop(context); // Close drawer
              navContainer.navigateTo(context, item.route);
            },
          )),
        ],
      ),
    );
  }
}
