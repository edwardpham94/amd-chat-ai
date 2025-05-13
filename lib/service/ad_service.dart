import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isInitialized = false;
  DateTime? _lastAdShownTime;
  static const Duration _adInterval = Duration(minutes: 10);
  bool _isTimerTriggered = false;

  // Test ad unit ID for development
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  // Production ad unit ID
  static const String _productionAdUnitId =
      'ca-app-pub-3510698121634536/4372330556';

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob SDK initialized successfully');
      loadInterstitialAd();
    } catch (e) {
      debugPrint('Failed to initialize AdMob SDK: $e');
    }
  }

  void loadInterstitialAd() {
    if (!_isInitialized) {
      debugPrint('AdMob SDK not initialized yet');
      return;
    }

    // Dispose of the old ad if it exists
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;

    debugPrint('Loading interstitial ad...');
    InterstitialAd.load(
      // Use test ad unit ID during development
      adUnitId: _testAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          // Set up full-screen callbacks
          _interstitialAd!
              .fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Ad dismissed');
              _isInterstitialAdReady = false;
              _lastAdShownTime = DateTime.now();
              loadInterstitialAd(); // Load the next ad immediately
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Failed to show ad: $error');
              _isInterstitialAdReady = false;
              ad.dispose();
              loadInterstitialAd(); // Try to load another ad
            },
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Ad showed successfully');
              _lastAdShownTime = DateTime.now();
              _isTimerTriggered = false; // Reset timer trigger after showing ad
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load interstitial ad: $error');
          _isInterstitialAdReady = false;
          _interstitialAd?.dispose();
          // Retry loading after a short delay
          Future.delayed(const Duration(seconds: 30), loadInterstitialAd);
        },
      ),
    );
  }

  void showInterstitialAd({bool isTimerTriggered = false}) {
    if (!_isInitialized) {
      debugPrint('AdMob SDK not initialized yet');
      return;
    }

    // Set timer trigger flag
    _isTimerTriggered = isTimerTriggered;

    // Only check time interval if not triggered by timer
    if (!_isTimerTriggered && _lastAdShownTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShownTime!);
      if (timeSinceLastAd < _adInterval) {
        debugPrint(
          'Ad shown recently, waiting ${_adInterval.inMinutes} minutes between ads',
        );
        return;
      }
    }

    if (!_isInterstitialAdReady || _interstitialAd == null) {
      debugPrint('Interstitial ad not ready yet, loading new ad...');
      loadInterstitialAd();
      return;
    }

    debugPrint('Showing interstitial ad...');
    _interstitialAd!.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
