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
  Future<void> showAd({required VoidCallback onUserEarnedReward}) async {
    if (_isAdReady && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onUserEarnedReward();
        },
      );
      _rewardedAd = null;
      _isAdReady = false;
      loadAd(); // Preload next ad
    } else {
      print('Rewarded Ad not ready.');
    }
  }

  /// Disposes of the rewarded ad
  void dispose() {
    _rewardedAd?.dispose();
  }
}
