# Classic Games Hub

Offline Android collection of board, card, and casual games.

## Games

**Wave 1:** Ludo, Snake & Ladder, Tic-Tac-Toe, Connect Four, Memory Match, 2048, Snake  
**Wave 2:** Chess, Checkers, Solitaire, Sudoku, Word Quest, Sky Dash, Trivia  
**Wave 3:** Dominoes, Color Cards, Rummy Lite, Carrom Lite, Property Tycoon, Word Rack

## Feedback

In-app **Feedback** (Contact / Rate / Survey) opens your email app and sends to `sales@sharadasoft.com` only when you tap Send.

## Build APK

```bash
flutter pub get
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Upgrade

Bump `version` in `pubspec.yaml` (increase the `+` build number), rebuild, and install the new APK over the old one (same `applicationId`).
