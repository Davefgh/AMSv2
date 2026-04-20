# AMSv2 – Attendance Monitoring System (Flutter)

> A mobile-first Flutter application for managing student attendance, class sessions, QR-based check-ins, and academic records across three user roles: **Admin**, **Instructor/Teacher**, and **Student**.

---

## 📱 Screenshots & Features by Role

### 🔐 Authentication
- Glassmorphic login screen with username/email and password fields
- Persistent sessions — stay logged in across app restarts and device reboots
- Automatic role-based routing on startup (Admin → Dashboard, Teacher → Teacher Dashboard, Student → Student Dashboard)
- Automatic session expiry handling: redirects to Login on unauthorized access

---

### 🛡️ Admin Role

| Screen | Description |
|---|---|
| **Dashboard** | Overview with user growth chart, role-based stats (Students, Teachers, Admins), and user table with filter/limit controls |
| **Enrollment** | Enroll students to sections and subjects, drop or re-enroll students |
| **Classes** | Manage Sections, Subjects, Courses, Classrooms, Instructors, and Schedules in a tabbed interface |
| **Users** | View all accounts by role, register new users, bulk import via JSON, and manage user data |
| **Students** | View, edit, soft-delete, restore, and permanently delete student records with swipe actions |
| **Instructors** | View and manage instructor directory with swipe-to-edit/delete |
| **Health Monitor** | Backend health check dashboard (live, ready, and data-integrity status) |

---

### 👨‍🏫 Instructor / Teacher Role

| Screen | Description |
|---|---|
| **Teacher Dashboard** | Welcome card, quick stats (Total Sessions, Students, Sections), and upcoming schedule |
| **Session Dashboard** | Active and upcoming class sessions with start/end session controls and QR code generation |
| **Session Details** | Full session info, attendees list, real-time attendance cutoff timer, and session notes |
| **Attendance** | Browse and filter all attendance records per session |
| **Record Attendance** | Manually record attendance for a specific student in a session |
| **Sections** | View assigned sections and navigate to section student lists |
| **Notifications** | Real-time check-in notification preferences |
| **Profile** | Instructor profile card with personal details |

---

### 🎓 Student Role

| Screen | Description |
|---|---|
| **Student Dashboard** | Welcome card, enrolled subjects overview, and attendance summary cards |
| **QR Scanner** | Scan a session QR code for attendance check-in using the device camera |
| **Profile** | Student profile card with account details |

---

## 🏗️ Project Structure

```
lib/
├── config/
│   ├── routes/
│   │   └── app_routes.dart           # Named route definitions
│   └── theme/
│       └── app_theme.dart            # Light & dark theme config
├── models/
│   ├── app_user.dart
│   ├── attendance_model.dart
│   ├── classroom_model.dart
│   ├── course_model.dart
│   ├── enrollment_model.dart
│   ├── health_status.dart
│   ├── instructor_model.dart
│   ├── schedule_model.dart
│   ├── section_model.dart
│   ├── session_model.dart
│   ├── student_model.dart
│   ├── student_subject_detail.dart
│   ├── subject_model.dart
│   └── user_profile.dart
├── providers/
│   └── app_provider.dart             # Role & theme state management
├── screens/
│   ├── admin/
│   │   ├── classes/                  # Sections, Subjects, Schedules, etc.
│   │   ├── dashboard/
│   │   ├── enrollment/
│   │   ├── health/
│   │   ├── instructors/
│   │   ├── students/
│   │   └── users/
│   ├── shared/
│   │   ├── auth/                     # Login screen
│   │   ├── profile/                  # Profile & edit profile
│   │   └── settings/                 # Settings & notifications
│   ├── student/
│   │   ├── student_dashboard_screen.dart
│   │   └── student_scan_screen.dart
│   └── teacher/
│       ├── attendance_screen.dart
│       ├── record_attendance_screen.dart
│       ├── session_dashboard_screen.dart
│       ├── session_details_screen.dart
│       ├── teacher_dashboard_screen.dart
│       ├── teacher_notification_screen.dart
│       └── teacher_sections_screen.dart
├── services/
│   ├── api_service.dart              # REST API client with 401 auto-logout
│   └── storage_service.dart         # SharedPreferences wrapper
├── utils/
│   ├── constants.dart               # API URL, storage keys, pagination
│   ├── responsive.dart              # Breakpoint helpers
│   └── sizing_utils.dart            # Fluid scaling utility (Sizing.w/h/sp/r)
├── widgets/
│   └── main_scaffold.dart           # Shared layout with header + bottom/rail nav
└── main.dart
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0 <4.0.0`
- Dart SDK
- Android Studio or VS Code with Flutter extension
- A running backend (REST API — see [API Base URL](#configuration))

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Davefgh/AMSv2.git
cd AMSv2

# 2. Install dependencies
flutter pub get

# 3. Run in debug mode
flutter run
```

### Configuration

Update the API base URL in `lib/utils/constants.dart`:

```dart
class AppConstants {
  static const String apiBaseUrl = 'https://your-backend-url.com';
}
```

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management (role, loading state) |
| `http` | REST API requests |
| `shared_preferences` | Persistent local storage (token, role) |
| `intl` | Date & number formatting |
| `uuid` | Unique ID generation for QR codes |
| `connectivity_plus` | Network connectivity checks |
| `logger` | Structured debug logging |
| `flutter_slidable` | Swipe-to-action on list items |
| `qr_flutter` | QR code generation for sessions |
| `mobile_scanner` | Camera-based QR code scanning for students |

---

## 🎨 Design System

- **Theme**: Premium dark UI with `#0F172A` base, `#38BDF8` accent, and glassmorphic cards
- **Scaling**: Fluid, mobile-first sizing via `Sizing.w()`, `Sizing.h()`, `Sizing.sp()`, and `Sizing.r()` — all values are proportional to a 375px design width
- **Responsive**: Mobile uses `BottomNavigationBar`; tablets use a `NavigationRail` with a max-width constraint (800px) for content
- **Fonts**: System default / Material You
- **Animations**: Smooth transitions, `BackdropFilter` blur effects, and `BouncingScrollPhysics`

---

## 🏛️ Architecture

- **Pattern**: Feature-first folder structure
- **State**: `Provider` with `ChangeNotifier`
- **Auth**: JWT Bearer token stored in `SharedPreferences`, auto-refreshed on startup, global 401 interceptor for session expiry
- **API**: Centralized `ApiService` with typed response handling and field-level validation error parsing

---

## 📱 Building for Release

### Android
```bash
flutter build apk --release
# or for app bundle:
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

---

## 🪪 License

This project is licensed under the MIT License.
