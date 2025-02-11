import 'package:guess_the_celebrity/core/managers/services_manager.dart';
import 'package:guess_the_celebrity/plugins/main_plugin/screens/home_screen.dart';
import 'package:guess_the_celebrity/utils/consts/theme_consts.dart';
import 'package:guess_the_celebrity/utils/consts/config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/managers/app_manager.dart';
import 'core/managers/navigation_manager.dart';
import 'core/managers/state_manager.dart';

Future<void> main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  final appManager = AppManager(); // Instantiate AppManager to access navigationContainer

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appManager),
        ChangeNotifierProvider(create: (_) => StateManager()),
        ChangeNotifierProvider.value(value: appManager.navigationContainer), // Provide NavigationContainer
      ],
      child: MyApp(),
    ),
  );
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppManager>(
      builder: (context, appManager, child) {
        if (!appManager.isInitialized) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final navContainer = NavigationContainer();

        return MaterialApp(
          title: Config.appTitle,
          theme: AppTheme.darkTheme,
          initialRoute: '/',
          routes: navContainer.routes,
        );
      },
    );
  }
}

