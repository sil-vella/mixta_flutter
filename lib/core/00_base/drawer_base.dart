import 'package:flutter/material.dart';
import '../managers/navigation_manager.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final NavigationContainer navContainer = NavigationContainer();

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Navigation Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
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
