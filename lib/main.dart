import 'package:mixta_guess_who/core/managers/services_manager.dart';
import 'package:mixta_guess_who/plugins/main_plugin/screens/home_screen.dart';
import 'package:mixta_guess_who/utils/consts/theme_consts.dart';
import 'package:mixta_guess_who/utils/consts/config.dart';
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
    // Assign global context when app initializes
    AppManager.globalContext = context;

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
          theme: AppTheme.darkTheme.copyWith(
            scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor, // ✅ Ensure solid background
          ),
          initialRoute: '/',
          routes: navContainer.routes,
        );

      },
    );
  }
}


