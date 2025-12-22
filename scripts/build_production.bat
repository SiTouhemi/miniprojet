@echo off
echo Building ISET Restaurant App for Production...

echo.
echo 1. Cleaning previous builds...
flutter clean
flutter pub get

echo.
echo 2. Running code generation...
flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo 3. Building Android APK...
flutter build apk --release --dart-define=ENV=production

echo.
echo 4. Building Android App Bundle...
flutter build appbundle --release --dart-define=ENV=production

echo.
echo 5. Building Web version...
flutter build web --release --dart-define=ENV=production

echo.
echo Build completed successfully!
echo.
echo Output files:
echo - Android APK: build\app\outputs\flutter-apk\app-release.apk
echo - Android Bundle: build\app\outputs\bundle\release\app-release.aab
echo - Web: build\web\

pause