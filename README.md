# ez8app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


flutter build web --release --web-renderer html --base-href /ez8/
cd build/web
git init
git add README.md
git add .
git commit -m "Deploy 1"    
git branch -M main
git push -u origin main
git remote add origin https://github.com/RathikumarJanushan/ez8app.git
git push -u origin janu5
git checkout 

git pull origin janu3




cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get