# CommuteAlert

CommuteAlert is a Flutter Android application for discovering local bus and van
routes, reviewing timetables, and saving favorite journeys. It is being
developed as an internship project in separate modules.

This README documents the completed **Module 1–3** implementation. Module 1
provides the application foundation and reference UI, Module 2 adds live
Firestore route data and favorites, and Module 3 adds timer-based journey
alarms and location-based bus-stop alerts.

## Module 1 objectives

- Establish a maintainable Flutter project structure.
- Configure Firebase using the existing FlutterFire configuration.
- Include Cloud Firestore as the planned route-data backend.
- Implement the core CommuteAlert UI and navigation flow.
- Provide responsive layouts for Android screen sizes.
- Create reusable widgets and null-safe Dart models.
- Prepare, but do not populate, the initial Firestore schema.
- Keep future-module features as clearly identified UI placeholders.

## Implemented functionality

### Splash screen

- CommuteAlert branding and bus icon.
- Green gradient background using the project color palette.
- Tagline: **“Your Journey, Our Priority”**.
- Automatic navigation to onboarding after a short delay.

### Onboarding

Three onboarding pages introduce:

1. Bus and van route discovery.
2. Timetables and travel planning.
3. Favorite routes and future travel reminders.

The flow includes page indicators, **Next**, **Skip**, and **Get Started**
actions. Skip and Get Started open the home screen.

### Home screen

- Greeting and notification affordance.
- Route search entry point.
- Quick actions for bus routes, van routes, favorites, and alarms.
- Popular routes section using demonstration route data.
- Bottom navigation for Home, Search, Favorites, and Profile.
- Navigation drawer with application branding and menu items.

### Search routes

- Transport selection for All, Bus, and Van.
- Starting location and destination fields.
- Input validation with user feedback.
- Location swap-ready search form.
- Quick filters: All, Direct, Express, and Popular.
- Search result cards and a no-results empty state.

### Route details and timetable

- Route name, transport type, journey, duration, and stop count.
- Timetable and Stops tabs.
- Favorite toggle in the app bar.
- Save/remove favorite action.
- Demonstration timetable and stop information clearly labeled as sample data.

### Favorites

- Saved route cards.
- Favorite removal functionality.
- Empty state for users who have not saved a route.
- Favorites are maintained locally in memory for Module 1.

### Profile

- Placeholder commuter profile header.
- My Routes, Favorites, Settings, Help & Support, and Log Out UI entries.
- Authentication is intentionally not implemented in this module.

## Module 3: Alarms and advanced features

### Journey timer alarms

- Select a Firestore route and enter or confirm a destination.
- Select a reminder time and repeat days from Monday through Sunday.
- Save, edit, delete, enable, and disable alarms.
- Schedule Android local notifications using
  `flutter_local_notifications`.
- Repeat alarms are scheduled weekly in the device's local timezone.
- Alarms are stored locally with `shared_preferences` and restored when the
  application starts.
- Duplicate alarms are rejected with a user-facing message.

The timer notification message is:

> Your journey reminder is due. Get ready for your selected route.

### Location bus-stop alerts

- Select a route and stop from the existing Firestore `routes` and `stops`
  collections.
- Use the stop's stored `latitude` and `longitude`; no production coordinates
  are hardcoded.
- Select a distance threshold of 100 m, 250 m, 500 m, or 1,000 m.
- Request location permission and check that device location services are
  enabled.
- Calculate distance with `geolocator`.
- Trigger one notification when the user enters the selected threshold.
- Prevent repeated notifications during the same monitoring session.
- Stop monitoring by disabling or removing the alert.

The location notification message is:

> You are approaching your selected bus stop.

Location monitoring is intentionally foreground-oriented. Android may pause
location updates while the app is backgrounded or force-stopped because of
battery and background-execution restrictions. The app does not claim
guaranteed background location tracking.

### Alarm management and notifications

The **My Alarms** screen displays timer and location alarms with route, stop,
time, repeat days, threshold, status, edit, delete, and enable/disable
controls. The notification affordance on the home screen opens the
notifications screen.

Notification setup includes:

- The `commute_alerts` Android notification channel.
- Runtime notification permission requests on supported Android versions.
- Device timezone initialization for scheduled notifications.
- Notification cancellation when an alarm is deleted or disabled.

## Module 3 file organization

```text
lib/
├── models/
│   └── alarm_model.dart
├── screens/
│   ├── alarms_screen.dart
│   ├── timer_alarm_screen.dart
│   ├── location_alarm_screen.dart
│   └── notifications_screen.dart
└── services/
    ├── alarm_service.dart
    ├── location_service.dart
    └── notification_service.dart
```

## Design system

The UI follows the supplied CommuteAlert design direction:

| Design token | Value | Usage |
| --- | --- | --- |
| Primary Green | `#0D6E4B` | App bars, primary buttons, transport icons |
| Secondary Green | `#2E7D6B` | Secondary theme accents |
| Background | `#F4F7F9` | Screen background |
| Text | `#1F2937` | Main text and headings |
| Accent Orange | `#F59E0B` | Favorite and attention accents |

Common UI conventions:

- White rounded cards with subtle elevation.
- Rounded corners generally between 14 and 18 pixels.
- Consistent Material icons.
- Green primary actions with readable contrast.
- Empty states for missing search and favorite data.
- Responsive rows using `Expanded` and constrained text to avoid overflow.

The centralized theme is defined in
[lib/theme/app_theme.dart](lib/theme/app_theme.dart).

## Project structure

```text
lib/
├── main.dart
├── firebase_options.dart
├── theme/
│   └── app_theme.dart
├── models/
│   ├── alarm_model.dart
│   ├── route_model.dart
│   ├── stop_model.dart
│   └── timetable_model.dart
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   ├── search_screen.dart
│   ├── route_details_screen.dart
│   ├── favorites_screen.dart
│   ├── profile_screen.dart
│   ├── alarms_screen.dart
│   ├── timer_alarm_screen.dart
│   ├── location_alarm_screen.dart
│   └── notifications_screen.dart
├── services/
│   ├── firebase_service.dart
│   ├── favorites_service.dart
│   ├── alarm_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
└── widgets/
    ├── custom_bottom_nav.dart
    ├── custom_drawer.dart
    ├── empty_state.dart
    ├── primary_button.dart
    ├── route_card.dart
    ├── search_field.dart
    └── section_heading.dart
```

### Responsibility of each layer

- **Screens**: Page-level layout, state, and navigation.
- **Widgets**: Reusable presentation components.
- **Models**: Typed route, stop, and timetable structures.
- **Services**: Firestore access, favorites, alarm persistence, notifications,
  and location monitoring.
- **Theme**: Shared colors, typography, shapes, and Material theme behavior.

## Firebase configuration

Firebase is initialized in
[lib/main.dart](lib/main.dart) with the existing
[lib/firebase_options.dart](lib/firebase_options.dart) configuration.

Configured dependencies:

- `firebase_core`
- `cloud_firestore`
- `shared_preferences`
- `flutter_local_notifications`
- `geolocator`
- `timezone`
- `flutter_timezone`

The Firebase project configuration was preserved and not regenerated. The app
does not seed, update, or delete production Firestore data in Module 1. The
`FirebaseService` class provides the typed route-stream abstraction that can be
connected to real route documents in a later module.

Firebase API keys in `firebase_options.dart` are client configuration values,
not server credentials. Production access must still be protected with
Firestore Security Rules and appropriate authentication before release.

## Firestore schema

The following collections are prepared for future route-data integration.
Field names and types should remain stable when real transport data is added.

### `routes`

| Field | Type | Description |
| --- | --- | --- |
| `routeId` | string | Stable route identifier |
| `routeName` | string | Display name |
| `transportType` | string | `bus` or `van` |
| `startLocation` | string | Origin name |
| `destination` | string | Destination name |
| `totalStops` | number | Number of stops |
| `estimatedDuration` | string | Display duration |
| `isDirect` | boolean | Whether the route is direct |
| `isExpress` | boolean | Whether the route is express |
| `isPopular` | boolean | Whether to show in popular routes |

### `stops`

Each `stops` document contains:

| Field | Type | Description |
| --- | --- | --- |
| `stopId` | string | Stable stop identifier |
| `routeId` | string | Related route identifier |
| `stopName` | string | Stop display name |
| `stopOrder` | number | Position along the route |
| `latitude` | number | Stop latitude |
| `longitude` | number | Stop longitude |

### `timetables`

Each `timetables` document contains:

| Field | Type | Description |
| --- | --- | --- |
| `timetableId` | string | Stable timetable identifier |
| `routeId` | string | Related route identifier |
| `departureTime` | string | Planned departure time |
| `arrivalTime` | string | Planned arrival time |
| `operatingDays` | array of strings | Days on which the timetable applies |

## Demonstration data notice

The sample routes and timetable entries displayed by the Module 1 UI are
demonstration data only. They are not verified transport schedules and must not
be treated as official bus or van timings.

Real route information should be reviewed and approved before being uploaded
to Firestore or shown as live commuter information.

Location alarms require real stop coordinates in Firestore. Stops without both
latitude and longitude cannot be used for location alerts.

## Dependencies

The main dependencies used by Modules 1–3 are:

```yaml
flutter:
  sdk: flutter
cupertino_icons: ^1.0.8
firebase_core: ^5.1.0
cloud_firestore: ^7.1.0
shared_preferences: ^2.5.3
flutter_local_notifications: ^19.4.2
geolocator: ^14.0.2
timezone: ^0.10.1
flutter_timezone: ^5.0.0
```

Development tooling includes `flutter_test` and `flutter_lints`.

## Setup and run

### Requirements

- Flutter 3.44.8 or a compatible SDK with Dart SDK `^3.12.2`.
- Android SDK and an Android emulator or physical device.
- A configured Firebase project for the existing application.
- Android application identifier `com.example.commutealert_app`.
- Firestore route and stop data, including coordinates for location alerts.

### Commands

Run from the project root:

```shell
flutter pub get
flutter analyze
flutter run
```

On the first run, grant notification and location permissions when prompted.
For a location alert, ensure device GPS is enabled and select a stop that has
valid Firestore coordinates.

To build a debug Android APK:

```shell
flutter build apk --debug
```

The generated APK is written to:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Android permissions and configuration

The Android manifest declares only the permissions required by Module 3:

- `POST_NOTIFICATIONS`: allows timer and location alert notifications on
  Android versions that require runtime notification permission.
- `ACCESS_COARSE_LOCATION`: allows approximate location access.
- `ACCESS_FINE_LOCATION`: allows accurate distance calculations near a stop.

Background location permission is not requested because the implementation
does not provide guaranteed background tracking. The Android app also enables
core library desugaring required by `flutter_local_notifications`.

If a permission is permanently denied, open the app's system settings and
enable it manually. If GPS is disabled, enable Location Services before
starting a location alert.

## Validation completed

The implementation was validated with:

- `flutter pub get` — successful.
- `dart format .` — completed.
- `flutter analyze` — no issues found.
- `flutter build apk --debug` — successful.
- `flutter test` — the existing starter counter smoke test fails because it
  still expects the removed template counter UI; no Module 3 test failure was
  reported.

Timer creation, editing, deletion, repeat-day selection, notification
permission prompts, foreground/background notification behavior, physical
location testing, and app-restart testing require an Android emulator or
device and were not executed in this environment.

The Android build emitted a non-blocking warning about a dependency applying
the Kotlin Gradle Plugin. It does not currently prevent the debug APK from
building; dependency upgrades should be reviewed before a future Flutter
toolchain migration.

## Known limitations and scope

The following limitations remain:

- Real user authentication.
- Offline synchronization.
- Full Firestore CRUD administration.
- Verified production timetable data.
- Production Firestore rules and user-specific data permissions.
- Guaranteed background location tracking while the app is force-stopped.
- Exact alarm delivery guarantees under Android battery optimization.

Timer notifications are delegated to Android's local notification scheduler.
Delivery can still be affected by device power-saving policies, notification
settings, or vendor-specific background restrictions.

## Suggested next steps

1. Confirm and document Firestore Security Rules.
2. Add verified route, stop, and timetable documents with valid coordinates.
3. Test alarm behavior on supported Android devices and battery settings.
4. Add widget and integration tests for alarm workflows.

## Module 2 implementation

Module 2 now reads active routes from the `routes` collection, route stops from
`stops`, and schedules from `timetables`. Search filters are applied
case-insensitively to Firestore route data; the app does not fall back to demo
routes when Firestore is empty or unavailable.

Expected fields include:

- `routes`: `routeId`, `routeName`, `transportType`, `startLocation`,
  `endLocation` (or `destination`), `departureTime`, `arrivalTime`, `fare`,
  `stops`, `isActive`, `isDirect`, `isExpress`, `isPopular`.
- `stops`: `stopId`, `routeId`, `stopName`, `stopOrder`, `latitude`,
  `longitude`, `address`.
- `timetables`: `timetableId`, `routeId`, `departureTime`, `arrivalTime`,
  `operatingDays`, `scheduleStatus`.

Cloud Firestore persistence is enabled during startup. The app displays a
cached-data banner when Firestore reports that the current snapshot is from
cache. Data that has never been fetched is not presented as offline data.

Firebase Authentication is not configured in this project, so favorites use
the local device's `shared_preferences` storage. They persist across restarts
but are not synchronized between devices or users.

### Demo Firestore seed

When the `routes` collection is empty, the app attempts a one-time demo seed
for routes, their stops with sample coordinates, and timetable documents. On
startup it also adds three sample popular routes when those route IDs are
missing. The seed never overwrites existing route documents. The coordinates
are sample data for development only and must be replaced with verified stop
coordinates before real commuter use.

Because this seed writes from the mobile client, Firestore Security Rules must
temporarily allow the write or the seed will be rejected. The app logs the
Firestore error and continues starting; it does not bypass Security Rules.
For production, use an authenticated admin tool or Firebase Console instead of
leaving public client writes enabled.

Before testing with real data, create the three collections and configure
Firestore Security Rules in the Firebase Console. Do not use public write
access in production. A suitable authenticated-user policy should be selected
once Firebase Authentication is added; the current client only requires
read access to route data.
4. Add authentication before storing user-specific favorites.
