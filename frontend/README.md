# Tracking App (Frontend)

This Flutter frontend has been updated with a modern, attractive UI using a professional color palette, Google Fonts and Font Awesome icons.

## Highlights
- Updated theme with a professional color palette and typography (Poppins via `google_fonts`).
- New reusable `RoundedButton` component in `lib/widgets/custom_button.dart`.
- Improved layout and card-based UI for all main screens in `lib/screens/*` (Admin, User, Tracking).
- Updated icons via `font_awesome_flutter`.

## Running the App
Make sure you have Flutter SDK installed.

1. Fetch dependencies:
```powershell
cd frontend
flutter pub get
```

2. Run on an emulator or device:
```powershell
flutter run
```

The app is now configured to use the production backend at `https://tracking-app-8rsa.onrender.com` by default.

If you need to use a different backend URL (e.g., for local development), you can override it with:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:5000
```

## Modifying Theme
- Color palette and typography are defined in `lib/theme.dart` (AppColors and AppTheme).
- Update colors in `AppColors` to tune the overall appearance.

## Notes
- UI changes are non-functional; API integration still uses current `services` layer and `routes`.
- If you’d like a different color palette or design guidelines, I can adapt the theme and UI elements to match brand style.
