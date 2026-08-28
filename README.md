# Mobile Tow Booking System

A Flutter + Firebase prototype built for **CSE6214 Software Engineering
Fundamentals** (Tutorial T14L, Dr Patrick) — assigned title *"Mobile Tow
Booking System."* Covers the brief's three modules (**Admin, User, Insurance
Agent**) as one app that branches by role after login, and all of its key
processes: registration & authentication for Users and Insurance Agents, a
vehicle insurance information database, a free-towing eligibility check, a
distance-based tow charge calculation, booking confirmation, and real-time
tracking of the tow vehicle's arrival.

## Key processes → where they live

| Brief's key process | Implementation |
|---|---|
| User & Insurance Agent registration/authentication | `lib/screens/auth/`, `lib/services/auth_service.dart` |
| Vehicle insurance information database | `lib/models/vehicle.dart`, `insurance_policy.dart`, `lib/screens/agent/manage_policies_screen.dart`, `lib/screens/user/vehicles_screen.dart` |
| Free towing eligibility check + distance-based tow charge | `lib/services/tow_calculation_service.dart` (pure logic, unit tested in `test/`) |
| Tow service booking confirmation | `lib/screens/user/request_tow_screen.dart` |
| Real-time tracking of tow vehicle arrival | `lib/services/tow_tracking_simulator.dart`, `lib/screens/user/booking_tracking_screen.dart` |
| Admin module | `lib/screens/admin/` (users, repair centers, all bookings, default tow rate) |

## Architecture

- **Flutter** (Dart), single codebase for Android/iOS. `provider` for state
  (`lib/app_state.dart` holds the signed-in user's profile).
- **Firebase**: Auth (email/password) + Cloud Firestore. See `lib/services/`
  for the data-access layer — screens never call `cloud_firestore` directly.
- **Maps**: `flutter_map` + OpenStreetMap tiles (no Google Maps API key/
  billing needed). Distance is computed as straight-line (Haversine, see
  `lib/utils/distance_utils.dart`) rather than routed distance — a
  deliberate, documented simplification for a student prototype.
- **Real-time tracking**: fully simulated client-side (`TowTrackingSimulator`)
  — a marker animates from a randomized nearby start point to the pickup
  location over ~75s once a booking is confirmed, driving the booking through
  `pending → confirmed → en route → arrived → completed`. No real device GPS
  required to demo it.
- One app, three roles: `users/{uid}.role` is `user`, `agent`, or `admin`;
  `lib/screens/role_router.dart` sends the signed-in user to the matching
  home shell after login.

## One-time setup

Flutter, the Android SDK, and an emulator (`tow_booking_emulator`) are
already installed on this machine (`C:\src\flutter`, `C:\Android`). The one
piece that still needs *your* Google account is Firebase — it can't be
scripted:

1. **Create/log into Firebase**: `firebase login` (opens a browser).
2. From this project's root, run **`flutterfire configure`** and pick or
   create a Firebase project. This overwrites `lib/firebase_options.dart`
   (currently a placeholder with `REPLACE_ME` values) and registers the
   Android app — accept the default `applicationId`
   (`com.towbooking.mobile_tow_booking_system`).
3. In the Firebase console, enable **Authentication → Email/Password** and
   create a **Cloud Firestore** database (test mode is fine to start).
4. Deploy the included security rules: `firebase deploy --only firestore:rules`
   (rules are in `firestore.rules` — Users/Agents can only touch their own
   data; Admin has broader access; see the file for the exact model).
5. **Seed the first Admin account**: register normally through the app as a
   "User", then in the Firestore console open that user's document under
   `users/{uid}` and change `role` from `user` to `admin`. Admin isn't
   self-registerable by design (see the plan).
6. **Seed at least one repair center**: log in as Admin → Centers tab → add
   one (needed before any User can request a tow).

## Running

```
flutter emulators --launch tow_booking_emulator
flutter run
```

## Testing

```
flutter test
```

`test/tow_calculation_service_test.dart` covers the eligibility/charge logic
end to end: fully within the free radius, exactly at the radius, beyond it,
no linked policy (falls back to the Admin-set default rate), an expired
policy, and a cancelled policy.

## Project structure

```
lib/
  main.dart              entry point, Firebase init, MaterialApp
  app_state.dart          signed-in user session (Provider)
  firebase_options.dart   flutterfire-generated config (placeholder until configured)
  models/                 plain Dart data classes (Firestore-serializable)
  services/                AuthService, FirestoreService, TowCalculationService, TowTrackingSimulator
  screens/
    auth/                  login, register
    user/                  dashboard, vehicles, request tow, live tracking, history
    agent/                 manage policies
    admin/                 manage users, repair centers, all bookings, settings
    role_router.dart       sends the signed-in user to the right module
test/                     unit tests for the calculation logic
```
