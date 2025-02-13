import 'dart:ui';
import '../../../../../core/00_base/module_base.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdModule extends ModuleBase {
  final String adUnitId;
  RewardedAd? _rewardedAd;
  bool _isAdReady = false;

  RewardedAdModule._internal(this.adUnitId) {
    _registerRewardedMethods();
  }

  /// Factory method to create an instance with the specified ad unit ID
  factory RewardedAdModule(String adUnitId) {
    return RewardedAdModule._internal(adUnitId);
  }

  /// Registers methods with the module
  void _registerRewardedMethods() {
    registerMethod('loadRewardedAd', loadAd);
    registerMethod('showRewardedAd', showAd);
  }

  /// Loads the rewarded ad
  Future<void> loadAd() async {
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdReady = true;
          print('Rewarded Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isAdReady = false;
          print('Failed to load Rewarded Ad: $error');
        },
      ),
    );
  }

  /// Shows the rewarded ad
  Future<void> showAd(List<dynamic> args) async {
    if (_isAdReady && _rewardedAd != null) {
      VoidCallback onUserEarnedReward = args.isNotEmpty && args[0] is VoidCallback
          ? args[0] as VoidCallback
          : () {}; // Default empty function

      VoidCallback onAdDismissed = args.length > 1 && args[1] is VoidCallback
          ? args[1] as VoidCallback
          : () {}; // Default empty function

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (Ad ad) {
          onAdDismissed(); // ✅ Call the provided callback when the ad is closed
          _rewardedAd?.dispose(); // ✅ Dispose when ad is closed
          _rewardedAd = null;
          _isAdReady = false;
          loadAd(); // ✅ Preload the next ad
          print('✅ Rewarded Ad dismissed and disposed.');
        },
        onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
          _rewardedAd?.dispose(); // ✅ Dispose on failure
          _rewardedAd = null;
          _isAdReady = false;
          loadAd();
          print('❌ Failed to show Rewarded Ad: $error');
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onUserEarnedReward(); // ✅ Give reward to user
        },
      );
    } else {
      print('❌ Rewarded Ad not ready.');
    }
  }



  /// Disposes of the rewarded ad
  void dispose() {
    _rewardedAd?.dispose();
  }
}
