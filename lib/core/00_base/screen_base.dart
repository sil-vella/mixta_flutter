import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../tools/logging/logger.dart';
import '../managers/app_manager.dart';
import '../managers/module_manager.dart';
import '../managers/navigation_manager.dart';
import '../../utils/consts/config.dart'; // ✅ Import AdMob Config

abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);

  /// Define a method to compute the title dynamically
  String computeTitle(BuildContext context);

  @override
  BaseScreenState createState();
}

abstract class BaseScreenState<T extends BaseScreen> extends State<T> {
  late final AppManager appManager;
  late final ModuleManager moduleManager;
  late final dynamic bannerAdModule;

  @override
  void initState() {
    super.initState();

    // ✅ Retrieve AppManager from Provider
    appManager = Provider.of<AppManager>(context, listen: false);
    moduleManager = appManager.moduleManager; // ✅ Use existing instance

    // ✅ Fetch the BannerAdModule **once**
    bannerAdModule = moduleManager.getModule('admobs_banner_ad_module');

    // ✅ Preload top and bottom banners with correct argument passing
    if (bannerAdModule != null) {
      bannerAdModule.callMethod("loadBannerAd", Config.admobsTopBanner);
      bannerAdModule.callMethod("loadBannerAd", Config.admobsBottomBanner);
      Logger().info('✅ Banner Ads preloaded.');
    } else {
      Logger().error("❌ BannerAdModule not found.");
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return SafeArea( // ✅ Ensures the top banner is below the status bar
      child: Column(
        children: [
          // ✅ Top Banner Ad
          if (bannerAdModule != null)
            Container(
              height: 50,
              alignment: Alignment.center,
              child: bannerAdModule.callMethod("getBannerWidget", [Config.admobsTopBanner, context]) ?? const SizedBox(),
            ),

          // ✅ Scaffold inside Column (So AppBar is Below Banner)
          Expanded(
            child: Consumer<NavigationContainer>(
              builder: (context, navigationContainer, child) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(widget.computeTitle(context)),
                  ),
                  drawer: Drawer(
                    child: ListView(
                      children: [
                        DrawerHeader(
                          decoration: const BoxDecoration(color: Colors.blue),
                          child: const Text(
                            'Navigation Menu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        ...navigationContainer.drawerItems.map(
                              (item) => ListTile(
                            leading: Icon(item.icon),
                            title: Text(item.label),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, item.route);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: buildContent(context),
                      ),

                      // ✅ Bottom Banner Ad
                      if (bannerAdModule != null)
                        Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: bannerAdModule.callMethod("getBannerWidget", [Config.admobsBottomBanner, context]) ?? const SizedBox(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Abstract method to be implemented in subclasses
  Widget buildContent(BuildContext context);
}
