import 'package:flutter/material.dart';
import '../../tools/logging/logger.dart';
import 'hooks_manager.dart';

class NavigationContainer extends ChangeNotifier {
  static final NavigationContainer _instance = NavigationContainer._internal();

  factory NavigationContainer() => _instance;

  NavigationContainer._internal();

  final Map<String, WidgetBuilder> _routes = {};
  final List<DrawerItem> _drawerItems = [];

  Map<String, WidgetBuilder> get routes => _routes;
  List<DrawerItem> get drawerItems => _drawerItems;

  // Register a new route
  void registerRoute(String route, WidgetBuilder builder) {
    _routes[route] = builder;
    Logger().info('Route registered: $route');
    notifyListeners();
  }

  // ✅ Register a new navigation item with an optional position
  void registerNavItem(DrawerItem item, {int? position}) {
    if (position != null && position >= 0 && position < _drawerItems.length) {
      _drawerItems.insert(position, item); // Insert at specified position
    } else {
      _drawerItems.add(item); // Default to adding at the end
    }

    Logger().info('DrawerItem added: ${item.label} at position ${position ?? _drawerItems.length - 1}');
    notifyListeners();
  }

  // ✅ New navigateTo Method
  void navigateTo(BuildContext context, String route) {
    if (_routes.containsKey(route)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: _routes[route]!),
      );
    } else {
      Logger().error('Navigation Error: Route not found: $route');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Route not found')),
      );
    }
  }

  // Register the reg_nav hook
  void registerNavHook(HooksManager hooksManager) {
    hooksManager.registerHook('reg_nav', () {
      notifyListeners();
    });
  }

  // Trigger navigation updates
  void triggerNavUpdate(HooksManager hooksManager) {
    hooksManager.triggerHook('reg_nav');
  }
}

class DrawerItem {
  final String label;
  final String route;
  final IconData icon;

  DrawerItem({
    required this.label,
    required this.route,
    required this.icon,
  });
}
