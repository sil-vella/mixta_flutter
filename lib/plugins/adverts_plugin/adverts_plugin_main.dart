import 'package:mixta_guess_who/plugins/adverts_plugin/modules/admobs/banner/banner_ad.dart';
import 'package:mixta_guess_who/plugins/adverts_plugin/modules/admobs/interstitial/interstitial_ad.dart';
import 'package:mixta_guess_who/plugins/adverts_plugin/modules/admobs/rewarded/rewarded_ad.dart';
import 'package:flutter/material.dart';
import '../../core/00_base/plugin_base.dart';
import '../../core/managers/hooks_manager.dart';
import '../../core/managers/module_manager.dart';
import '../../core/managers/navigation_manager.dart';
import '../../core/managers/services_manager.dart';
import '../../core/managers/state_manager.dart';
import '../../tools/logging/logger.dart';
import '../../utils/consts/config.dart';

class AdvertsPlugin extends PluginBase {
  final ServicesManager servicesManager;
  final StateManager stateManager; // ✅ Add StateManager
  final interstitialAdUnitId = Config.admobsInterstitial01;
  final rewardedAdUnitId = Config.admobsRewarded01;

  AdvertsPlugin(
      HooksManager hooksManager, ModuleManager moduleManager, NavigationContainer navigationContainer,
      this.stateManager) // ✅ Pass StateManager
      : servicesManager = ServicesManager(),
        super(hooksManager, moduleManager) {

    moduleMap.addAll({
      'admobs_banner_ad_module': () => BannerAdModule(),
      'admobs_interstitial_ad_module': () => InterstitialAdModule(interstitialAdUnitId),
      'admobs_rewarded_ad_module': () => RewardedAdModule(rewardedAdUnitId),
    });

    hookMap.addAll({
      'app_startup': () {
        _preLoadAds(); // ✅ Initialize ads on startup
      },
    });
  }

  /// ✅ Define initial states for this plugin
  @override
  Map<String, Map<String, dynamic>> getInitialStates() {
    return {

    };
  }

  /// ✅ Preload all ads to ensure fast loading
  Future<void> _preLoadAds() async {
    final bannerAdModule = moduleManager.getModule('admobs_banner_ad_module');
    final interstitialAdModule = moduleManager.getModule('admobs_interstitial_ad_module');
    final rewardedAdModule = moduleManager.getModule('admobs_rewarded_ad_module');

    if (bannerAdModule != null) {
      await bannerAdModule.callMethod("loadBannerAd", Config.admobsTopBanner);
      await bannerAdModule.callMethod("loadBannerAd", Config.admobsBottomBanner);
      Logger().info('✅ Banner Ads preloaded.');
    } else {
      Logger().error('❌ Failed to preload Banner Ads: Module not found.');
    }


    if (interstitialAdModule != null) {
      await interstitialAdModule.callMethod("loadInterstitialAd");
      Logger().info('✅ Interstitial Ad preloaded.');
    } else {
      Logger().error('❌ Failed to preload Interstitial Ad: Module not found.');
    }

    if (rewardedAdModule != null) {
      await rewardedAdModule.callMethod("loadRewardedAd");
      Logger().info('✅ Rewarded Ad preloaded.');
    } else {
      Logger().error('❌ Failed to preload Rewarded Ad: Module not found.');
    }
  }
}
