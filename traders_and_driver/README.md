# TradeMaster

TradeMaster is a Flutter app that connects traders and drivers with secure phone-based authentication and role-based navigation.

## What this app does

- Displays a welcoming home screen with login and registration entry points.
- Supports user registration with phone number verification (OTP) via Supabase.
- Allows users to choose a role at registration: `Trader` or `Driver`.
- Uses Supabase authentication to log in, verify users, and manage user metadata.
- Includes dedicated pages for trader, driver, and admin workflows.

## Key features

- Home screen with branded landing design and buttons for login/register.
- Registration flow with full name, phone number, password, role selection, OTP verification, and password setup.
- Login flow for returning users.
- Support for forgotten password recovery.
- Supabase integration configured in `lib/main.dart`.

## Project structure

- `lib/main.dart` — app entry point and route definitions.
- `lib/screens/home_page.dart` — landing page with navigation to auth flows.
- `lib/screens/login_page.dart` — login screen for existing users.
- `lib/screens/register_page.dart` — registration form with phone OTP verification.
- `lib/screens/forgot_password_page.dart` — password recovery screen.
- `lib/screens/trader_page.dart` — trader-specific UI.
- `lib/screens/driver_page.dart` — driver-specific UI.
- `lib/screens/admin_page.dart` — admin dashboard UI.

## How to use

1. Install Flutter and set up your development environment.
2. Open the project folder in VS Code or your preferred editor.
3. Run:
   ```bash
   flutter pub get
   flutter run
   ```
4. Use the app to navigate from the home screen to `Login` or `Register`.
5. In registration, select either `Trader` or `Driver`, enter the required details, send the OTP, then verify and complete registration.
6. After registration, log in with your phone number and password.

## Supabase setup

The app initializes Supabase in `lib/main.dart` using a project URL and anonymous key. Before publishing or sharing the project, replace the embedded Supabase credentials with your own secure values.

## Notes

- The current app includes placeholder route names and should be adapted if you change navigation patterns.
- Passwords are validated for strength before OTP is sent.
- Phone numbers are formatted to E.164 format for Supabase phone auth.

## Dependencies

- `flutter`
- `supabase_flutter`
- `google_fonts`

Enjoy building your trade-and-transport app with TradeMaster!
