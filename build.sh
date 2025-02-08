#!/bin/bash

flutter build appbundle \
  --dart-define=API_URL_LOCAL=http://127.0.0.1:5000 \
  --dart-define=API_URL=https://fmif.reignofplay.com \
  --dart-define=ADMOBS_BOTTOM_BANNER01=ca-app-pub-3940256099942544/9214589741 \
  --dart-define=ADMOBS_INTERSTITIAL01=ca-app-pub-3940256099942544/1033173712 \
  --dart-define=ADMOBS_REWARDED01=ca-app-pub-3940256099942544/5224354917 \
  --split-debug-info=build/symbols
