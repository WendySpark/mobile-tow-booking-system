# Mobile Tow Booking System

A Flutter + Firebase prototype built for *"Mobile Tow
Booking System."* Covers the brief's three modules (**Admin, User, Insurance
Agent**) as one app that branches by role after login, and all of its key
processes: registration & authentication for Users and Insurance Agents, a
vehicle insurance information database, a free-towing eligibility check, a
distance-based tow charge calculation, booking confirmation, and real-time
tracking of the tow vehicle's arrival. A fourth role, **Workshop**, was added
beyond the brief (see below).

## Beyond the brief

Five additions that go past the minimum key processes:

- **Workshop as a 4th entity** — panel repair centers are no longer just
  Admin-seeded map pins. A Workshop is a real, self-registering role that
  sets its own location (map picker) and **manages its own fleet of tow
  truck drivers** (add/remove, toggle available/busy/offline). Users choose
  which workshop to use themselves: the Request Tow picker lists every
  workshop sorted by distance from the pickup pin, defaulting to the User's
  **preferred workshop** (★ toggle, saved on their profile) if they've set
  one, otherwise the nearest. See `lib/screens/workshop/`.
- **Road-following real-time tracking** — the tow truck marker no longer
  cuts a straight line to the user like an early prototype would. It follows
  an actual driving route fetched from OSRM (`RoutingService`), animated at
  constant speed along the real road polyline (`RouteResult.pointAt`,
  distance-weighted, not point-index-weighted) — the same idea as Grab/Uber's
  driver tracking.

- **Payment gating + invoices** — a chargeable tow isn't just calculated, it
  has to actually be paid. A new **Payments** tab lists every chargeable
  booking and lets the User settle it (simulated card/online-banking/e-wallet
  sheet); Admin can record a cash payment instead. **Requesting a new tow is
  blocked while any past charge is unsettled** — `PaymentGateService` checks
  this before the booking screen even opens. Every booking gets a formatted
  **Invoice** (itemized distance breakdown, payment status/method/timestamp),
  reachable from History, Payments, and Admin's booking list.
- **Multi-driver ETA comparison** — instead of one hardcoded tow truck,
  `DriverDispatchService` simulates 2–3 nearby drivers per pickup point and
  sorts them by ETA; the user picks one before confirming, and that choice
  drives the tracking simulation's start point.
- **Admin analytics dashboard** — revenue collected vs. outstanding, a 7-day
  booking-volume chart, free-vs-chargeable split, and bookings-by-repair-center,
  all computed from bookings already in Firestore (`BookingAnalyticsService`,
  charted with `fl_chart`).

## Key processes → where they live

| Brief's key process | Implementation |
|---|---|
| User & Insurance Agent registration/authentication | `lib/screens/auth/`, `lib/services/auth_service.dart` |
| Vehicle insurance information database | `lib/models/vehicle.dart`, `insurance_policy.dart`, `lib/screens/agent/manage_policies_screen.dart`, `lib/screens/user/vehicles_screen.dart` |
| Free towing eligibility check + distance-based tow charge | `lib/services/tow_calculation_service.dart` (pure logic, unit tested in `test/`) |
| Tow service booking confirmation | `lib/screens/user/request_tow_screen.dart` (includes driver ETA comparison) |
| Real-time tracking of tow vehicle arrival | `lib/services/tow_tracking_simulator.dart`, `lib/screens/user/booking_tracking_screen.dart` |
| Admin module | `lib/screens/admin/` (users, repair centers, all bookings, analytics, default tow rate) |
| *(beyond brief)* Workshop module + driver fleet | `lib/screens/workshop/`, `lib/models/driver.dart` |
| *(beyond brief)* Payment collection + invoicing | `lib/services/payment_gate_service.dart`, `lib/screens/user/payments_screen.dart`, `lib/screens/invoice_screen.dart` |

## Architecture

- **Flutter** (Dart), single codebase for Android/iOS. `provider` for state
  (`lib/app_state.dart` holds the signed-in user's profile).
- **Firebase**: Auth (email/password) + Cloud Firestore. See `lib/services/`
  for the data-access layer — screens never call `cloud_firestore` directly.
- **Maps**: `flutter_map` + OpenStreetMap tiles (no Google Maps API key/
  billing needed). The tow-charge *distance* is still straight-line
  (Haversine, see `lib/utils/distance_utils.dart`) — a deliberate,
  documented simplification kept stable/tested for the billing math — but
  the *tracking animation* now follows real roads (see below).
- **Real-time tracking**: `RoutingService` fetches an actual road route from
  OSRM's public routing API once a booking is confirmed (falling back to a
  straight line if the network call fails), and `TowTrackingSimulator`
  animates a marker along it at constant speed (distance-weighted
  interpolation, not point-index) over ~75s, driving the booking through
  `pending → confirmed → en route → arrived → completed`. No real device GPS
  required to demo it.
- One app, four roles: `users/{uid}.role` is `user`, `agent`, `admin`, or
  `workshop`; `lib/screens/role_router.dart` sends the signed-in user to the
  matching home shell after login.

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
6. **Register at least one Workshop and driver** so a User has somewhere to
   book: register with role "Workshop", set its location in the My Workshop
   tab, then add a driver in the Drivers tab. (Admin can also seed a bare
   repair center from the Centers tab, but it won't have any drivers unless
   a matching Workshop account manages it.)

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
policy, and a cancelled policy. `test/payment_gate_service_test.dart`,
`test/driver_dispatch_service_test.dart`, `test/booking_analytics_service_test.dart`,
and `test/route_result_test.dart` cover the "beyond the brief" additions the
same way — pure logic, no Firebase or network needed to run them.

## Project structure

```
lib/
  main.dart              entry point, Firebase init, MaterialApp
  app_state.dart          signed-in user session (Provider)
  firebase_options.dart   flutterfire-generated config (placeholder until configured)
  models/                 plain Dart data classes (Firestore-serializable)
  services/                AuthService, FirestoreService, TowCalculationService,
                            TowTrackingSimulator, RoutingService, PaymentGateService,
                            DriverDispatchService, BookingAnalyticsService
  screens/
    auth/                  login, register
    user/                  dashboard, vehicles, request tow, live tracking, history, payments
    agent/                 manage policies
    admin/                 manage users, repair centers, all bookings, analytics, settings
    workshop/               workshop profile/location, manage drivers, its bookings
    invoice_screen.dart    shared invoice view (User + Admin)
    role_router.dart       sends the signed-in user to the right module
test/                     unit tests for all pure/calculation logic
```
