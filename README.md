# AMS Flutter — BBOTS Management System

A complete Flutter port of the AMS Normal Auth Flow web application.

## Project Structure

```
lib/
├── main.dart                        # App root + state machine
├── theme.dart                       # Color tokens + ThemeData
├── data.dart                        # AUTH101, AUTH103, seed queue data
├── models/
│   └── models.dart                  # Data models (Auth101Config, QueueEntry, AppState)
├── widgets/
│   └── widgets.dart                 # Shared widgets: AmsBadge, AmsPill, AmsButton,
│                                    #   AmsCard, AmsField, AmsTextInput, AmsDropdown,
│                                    #   AmsTopBar, AmsTopStepper, AmsIdentityHeader,
│                                    #   AmsSubmitBar, showAmsToast
└── screens/
    ├── login_screen.dart            # Screen 1: Login (dark glassmorphism)
    ├── select_type_screen.dart      # Screen 2: Transaction vs Non-Transaction picker
    ├── tran_entry_screen.dart       # Screen 3A: Transaction Entry (Amount + AUTH103)
    ├── nontran_entry_screen.dart    # Screen 3B: Non-Transaction Entry
    └── modal_queue_direct.dart      # Decision Modal + Screen 4 Queue + Screen 5 Direct Save
```

## Screens & Flow

```
Login  →  Select Type  →  Transaction Entry  →  Decision Modal  →  Pending Queue
                      ↘  Non-Transaction Entry  ↗                →  Direct Save
```

| Screen | Description |
|--------|-------------|
| Login | Dark gradient UI with org/user/password validation |
| Select Type | T vs N pick cards with live AUTH101 data |
| Transaction Entry | Sections A–G, AUTH103 live amount validation, program-specific fields |
| Non-Transaction Entry | Teal-themed, no amount, KYC → direct save path |
| Decision Modal | AUTH101 APPROVALREQ check, route to queue or direct |
| Pending Queue | Stats grid, searchable DataTable, badges |
| Direct Save | Animated success card with timeline |

## Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0

### Install dependencies
```bash
flutter pub get
```

### Run on desktop (recommended for wide layout)
```bash
flutter run -d macos     # macOS
flutter run -d windows   # Windows
flutter run -d linux     # Linux
```

### Run on web
```bash
flutter run -d chrome
```

### Run on mobile
```bash
flutter run -d android
flutter run -d ios
```

### Build release
```bash
# Web
flutter build web

# macOS
flutter build macos

# Android APK
flutter build apk

# iOS
flutter build ios
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `google_fonts` | ^6.1.0 | Space Grotesk + JetBrains Mono |
| `intl` | ^0.19.0 | Date formatting |

## Design Notes

- Colors faithfully ported from CSS custom properties
- Blue (`#1447E6`) = Transaction path
- Teal (`#0B7A6E`) = Non-Transaction path  
- Green (`#0A8A55`) = Done / Direct Save
- All AUTH101/AUTH103 data is static in `lib/data.dart`
- State is managed in `AmsRoot` via `AppState` (no external state manager needed)
- Responsive layout via `LayoutBuilder` + `Wrap`
