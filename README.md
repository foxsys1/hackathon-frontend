<div align="center">
  <img src="assets/icons/koscheck_logo.svg" height="80" alt="KosCheck Logo" />
  <h1>KosCheck</h1>
  <p><b>Your Smart Shield Against Rental Fraud</b></p>
</div>

---

**KosCheck** is a mobile-first Flutter application designed for the GDGoC Hackathon. It helps prospective boarding house (*kos*) renters evaluate the risk level of a listing *before* paying a deposit (DP). By analyzing multiple data points, KosCheck dramatically reduces the chances of falling victim to rental fraud.

## ✨ Why KosCheck?

Finding a safe *kos* shouldn't be a gamble. KosCheck provides an intuitive, step-by-step risk assessment flow that analyzes everything from basic listing details to complex communication patterns. 

## 🚀 Key Features

### 🔍 AI-Powered Risk Assessment (Analisis Risiko)
Our core engine evaluates a listing through a comprehensive 4-step flow:
1. **Basic Information:** Enter essential details like *kos* name, location, price, listing source, and facilities.
2. **Quick Check:** Answer 7 rapid-fire verification questions with optional photo/video evidence.
3. **Deep Check:** Take the analysis to the next level by uploading WhatsApp chat exports and review screenshots.
4. **Smart Overview:** Review and edit your inputs seamlessly before processing.

### 📊 Comprehensive Analysis Results
Once processed through our animated **Analyzing** screen, you receive an in-depth report:
- **Risk & Confidence Scores:** Clear metrics (0-100) indicating the listing's safety and the system's confidence in the result.
- **Red Flag Detection:** Instant identification of suspicious elements.
- **Visual & Communication Analysis:** Deep insights derived from uploaded media and chat transcripts to spot manipulative or inconsistent behavior.
- **Area Price Comparison:** Verify if the requested rent aligns with the neighborhood average.
- **Actionable Recommendations & Smart Chat Templates:** Get tailored advice and pre-written messages to safely communicate with the landlord.

### 🏘️ Explore & Discover (Eksplor Kos)
- Browse verified listings with advanced search, filtering, and sorting capabilities.
- Toggle location settings to find the best options near you.
- **Detail View:** Access comprehensive facility lists, AI-generated listing summaries, and source-linked reviews.

### 📋 History & Tracking (Riwayat)
- Keep track of all your past assessments.
- Searchable and sortable history with a high-level summary of risk levels (Low, Medium, High).
- Dive into full detail views for any past record.

## 🛠️ Tech Stack

We built KosCheck using modern, scalable, and robust technologies:

| Layer            | Technology                                        |
| ---------------- | ------------------------------------------------- |
| **Framework**        | Flutter 3.x (Dart 3.3+)                           |
| **State Management** | `flutter_riverpod` + `riverpod_annotation`        |
| **Routing**          | `go_router` (ShellRoute + Bottom Navigation)      |
| **Data Models**      | `freezed` + `json_serializable`                   |
| **Networking**       | `dio`                                             |
| **Local Storage**    | `shared_preferences`                              |
| **Media & Files**    | `image_picker` + `file_picker`                    |
| **Location**         | `geolocator`                                      |
| **Data Viz**         | `fl_chart`                                        |

## 🏗️ Architecture

KosCheck follows a clean, feature-driven folder structure for optimal maintainability:

```text
lib/
  core/
    constants/     — App constants (base URLs, config)
    network/       — Dio client configuration
    router/        — GoRouter implementation
    theme/         — App colors and theming (light/dark)
  features/
    home/          — Hero section, info cards, quick access
    analysis/      — The core risk assessment engine
      domain/      — Models, Freezed states, Notifiers
      data/        — Repositories and DTOs
      presentation/— 7+ specialized pages for the assessment flow
    history/       — Assessment tracking
    explore/       — Listing discovery and AI summaries
```

## 🗺️ Routing

| Path                   | Page                       |
| ---------------------- | -------------------------- |
| `/`                    | HomePage                   |
| `/explore`             | ExplorePage                |
| `/explore/:id`         | ExploreDetailPage          |
| `/explore/:id/reviews` | ExploreAllReviewsPage      |
| `/history`             | HistoryPage                |
| `/history/:id`         | HistoryDetailPage          |
| `/analyze`             | BasicInfoPage              |
| `/analyze/quick`       | QuickCheckPage             |
| `/analyze/quick-edit`  | QuickCheckPage (edit mode) |
| `/analyze/deep`        | DeepCheckPage              |
| `/analyze/overview`    | OverviewPage               |
| `/analyze/loading`     | AnalyzingPage              |
| `/analyze/result`      | AnalysisResultPage         |
| `/analyze/chat`        | ChatTemplatePage           |

## 🏁 Getting Started

Ready to run KosCheck locally? Follow these steps:

1. **Install Flutter:** Head over to [flutter.dev](https://flutter.dev/docs/get-started/install) if you haven't already.
2. **Fetch Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Generate Code:** (Crucial for Riverpod & Freezed)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Run the App:**
   ```bash
   flutter run -d chrome   # For web preview
   # OR
   flutter run             # For connected device/emulator
   ```

## 🎨 Assets

| File                             | Description                        |
| -------------------------------- | ---------------------------------- |
| `assets/icons/house_bg.svg`      | Hero background house illustration |
| `assets/icons/koscheck_logo.svg` | KosCheck wordmark logo             |

---
*Made with ❤️ by yazid*
