# Copilot Instructions for AI Agents

## Project Overview
- **PSMMS** is a Flutter app for managing preachers, activities, and payments in religious organizations.
- Core modules: Officer (activity management, approvals), Preacher (activity participation, evidence submission), Payment (request, approval, history).
- Uses Firebase (Auth, Firestore, Storage) for backend, Google Maps for location, Provider for state management.

## Key Architecture & Patterns
- **lib/models/**: Data models (e.g., `activity.dart`, `payment.dart`).
- **lib/viewmodels/**: Business logic using Provider (e.g., `officer_activity_view_model.dart`).
- **lib/views/**: UI screens, organized by feature (activity, payment, officer/preacher subfolders).
- **lib/firebase_options.dart**: Firebase config (auto-generated, do not edit manually).
- **Google Maps**: Integrated via `google_maps_flutter`, with setup in `GOOGLE_MAPS_SETUP.md`.

## Developer Workflows
- **Build & Run**: `flutter pub get` then `flutter run` (see README for setup steps).
- **Testing**: Place tests in `test/`, run with `flutter test`.
- **Firebase/Maps Setup**: Follow `GOOGLE_MAPS_SETUP.md` and README for API keys and config files. Never commit secrets.
- **Platform Support**: Android, iOS, Web, Windows, macOS, Linux (see respective folders).

## Project-Specific Conventions
- **Photos**: Preacher evidence requires minimum 3 photos per activity.
- **Urgency**: Activities can be marked as Normal/Urgent.
- **Location**: All evidence is GPS-verified; map picker is used for location selection.
- **Approval Flows**: Officer must approve/reject preacher submissions and payment requests.
- **State Management**: Use Provider for all business logic; avoid setState in views.
- **Sensitive Files**: `google-services.json`, `GoogleService-Info.plist`, and API keys must NOT be committed (see .gitignore).

## Integration & Dependencies
- **Firebase**: Auth, Firestore, Storage (see `pubspec.yaml` for versions).
- **Google Maps**: Requires API key setup per platform.
- **Geolocator/Geocoding**: Used for GPS and address lookup.
- **Provider**: For dependency injection and state management.

## Examples
- To add a new activity type, update `lib/models/activity.dart` and relevant viewmodels/views.
- To add a payment feature, see `lib/models/payment.dart`, `lib/viewmodels/payment_view_model.dart`, and `lib/views/payment/`.
- For map/location features, see `lib/views/activity/widgets/` and follow Google Maps setup docs.

## References
- [README.md](../README.md): Full setup, features, and structure.
- [GOOGLE_MAPS_SETUP.md](../GOOGLE_MAPS_SETUP.md): Google Maps API setup.
- `pubspec.yaml`: Dependency versions and Flutter config.

---
If any workflow or pattern is unclear, please request clarification or examples from maintainers.
