# 🏛️ JharUdyam Citizen Mobile App (Flutter)
> **Smart India Hackathon SIH26043** — Civic Issue Reporting & AI Triage Platform for the Government of Jharkhand

JharUdyam empowers citizens to photograph civic problems (potholes, garbage accumulation, broken streetlights, water leakages, hazardous wires), automatically structures and categorizes them with AI (generating title, description, category, priority, and department routing), captures precise GPS coordinates, and publishes them to a shared Supabase backend.

---

## 🌟 Key Features

- **⚡ Zero-Login Paradigm**: No registration or login required. Citizens enter the feed immediately. A persistent local device UUID (`deviceId`) tracks reports in the "My Reports" tab seamlessly.
- **👁️ AI Vision Triage (Google Gemini 3.6 Flash)**: Instant multimodal photo analysis generating concise titles, hazard assessments, priority ratings (`critical`, `high`, `medium`, `low`), and strict routing to one of the 8 official Jharkhand departments.
- **📍 GPS Auto-Tagging & Manual Location**: Captures device GPS coordinates with reverse-geocoding, with full support for manual address editing.
- **🗄️ Supabase Cloud Integration**: Direct database persistence with PostgreSQL triggers auto-generating ticket numbers (e.g. `JU-26-0001`) and image uploads to Supabase Storage (`problem-images`).
- **🗺️ Interactive Map & Deep Links**: Mini-map powered by `flutter_map` (OpenStreetMap) with one-tap Google Maps external navigation.
- **🎨 Sal Forest Green Aesthetic**: High-trust civic UI with status pills, priority badges, and an interactive lifecycle stepper.

---

## 📂 Project Structure

```
lib/
├── main.dart                       # Entry point, Supabase initialization, MultiProvider
├── constants/
│   ├── app_constants.dart          # Supabase credentials, Gemini API key, 8 departments
│   └── app_theme.dart              # Sal Forest Green palette, Priority & Status styling
├── models/
│   └── problem_model.dart          # Problem data class with JSON serialization & relative timestamps
├── services/
│   ├── device_service.dart         # Persistent UUID generation via SharedPreferences
│   ├── supabase_service.dart       # Supabase client wrapper
│   ├── problem_repository.dart     # Feed queries, image upload & submission operations
│   ├── ai_service.dart             # Multimodal Gemini vision analysis
│   ├── location_service.dart       # GPS fetching & reverse geocoding
│   └── image_service.dart          # Camera/gallery capture & JPEG compression
├── providers/
│   ├── problems_provider.dart      # Feed state, category filtering & search
│   └── report_provider.dart        # Multi-step wizard state & submission
├── screens/
│   ├── home_screen.dart            # All Issues / My Reports tabs, filters, FAB
│   ├── problem_detail_screen.dart  # Pinch-to-zoom photo, lifecycle tracker, map
│   └── create_report_screen.dart   # 5-step wizard (Capture → AI → Review → Submit)
└── widgets/
    ├── problem_card.dart           # Feed issue card widget
    ├── category_chips.dart         # Horizontal category filter chips
    ├── priority_badge.dart         # Colored priority level indicator
    ├── status_indicator.dart       # Lifecycle status pill with icons
    ├── lifecycle_tracker.dart      # Visual 4-step custody tracker
    ├── location_card.dart          # FlutterMap OSM tile card
    └── success_dialog.dart         # Celebratory ticket confirmation dialog
```

---

## 🏛️ Predefined Jharkhand Departments

1. **Public Works** (Roads, potholes, bridges, flyovers, dividers, footpaths)
2. **Water Supply & Sanitation** (Pipeline leaks, broken public taps, open drainage)
3. **Electricity** (Dangling wires, damaged electric poles, dark streetlights)
4. **Municipal Solid Waste** (Dumpster overflow, illegal dumping, garbage heaps)
5. **Health** (Stagnant water, mosquito breeding, dead animals, sanitary hazards)
6. **Transport** (Damaged bus stops, broken signals, parking obstructions)
7. **Urban Development** (Public parks, encroachments, dilapidated toilets)
8. **Environment & Forests** (Illegal tree felling, fallen trees, forest fires)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.19+ or higher)
- Android Studio / VS Code with Flutter extension
- An Android or iOS device / emulator

### Installation & Run

1. Clone the repository:
   ```bash
   git clone -b application https://github.com/nonsense3/JharUdyam.git
   cd JharUdyam
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run on connected device:
   ```bash
   flutter run
   ```

4. Build Release APK:
   ```bash
   flutter build apk --release
   ```
