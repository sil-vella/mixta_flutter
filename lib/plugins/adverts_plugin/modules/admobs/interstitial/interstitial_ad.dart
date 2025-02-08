import '../../../../../core/00_base/module_base.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdModule extends ModuleBase {
  final String adUnitId;
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  InterstitialAdModule._internal(this.adUnitId) {
    _registerInterstitialMethods();
  }

  /// Factory method to create an instance with the specified ad unit ID
  factory InterstitialAdModule(String adUnitId) {
    return InterstitialAdModule._internal(adUnitId);
  }

  /// Registers methods with the module
  void _registerInterstitialMethods() {
    registerMethod('loadInterstitialAd', loadAd);
    registerMethod('showInterstitialAd', showAd);
  }

  /// Loads the interstitial ad
  Future<void> loadAd() async {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;
          print('Interstitial Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _isAdReady = false;
          print('Failed to load Interstitial Ad: $error');
        },
      ),
    );
  }

  /// Shows the interstitial ad
  Future<void> showAd() async {
    if (_isAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isAdReady = false;
      loadAd(); // Preload next ad
    } else {
      print('Interstitial Ad not ready.');
    }
  }

  /// Disposes of the interstitial ad
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
