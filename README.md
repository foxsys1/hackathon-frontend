# KosCheck — Frontend

KosCheck is a mobile-first Flutter application built for GDGoC Hackathon. It helps prospective boarding house (kos) renters assess the risk level of a listing before paying a deposit (DP), reducing the chances of rental fraud.

## Features

- **Beranda (Home)** — Hero section with house background illustration and quick access to start analysis
- **Analisis Risiko** — 4-step guided flow:
  1. **Informasi Dasar** — Fill in kos name, location, price, source listing, and facilities
  2. **Quick Check** — Answer 7 verification indicator questions (tri-state: Ya / Tidak / Tidak Tahu) with optional photo/video uploads
  3. **Deep Check** _(optional)_ — Upload WhatsApp chat export and testimoni screenshots for deeper analysis
  4. **Overview** — Review all inputs before submission; edit-in-place supported
- **Analyzing** — Animated loading screen simulating backend analysis with step-by-step status
- **Hasil Analisis** — Risk score (0–100), risk label, red flags, recommendations, area price comparison, and chat templates
- **Eksplor Kos** — Browse listings with search, filters, sorting, and location toggle
- **Detail Kos** — Listing detail, facilities, AI summary, and reviews with source link
- **Riwayat** — Searchable and sortable history list with activity summary (total, rendah, sedang, tinggi)
- **Riwayat Detail** — Full detail view for each past analysis record

## Tech Stack

| Layer            | Technology                                        |
| ---------------- | ------------------------------------------------- |
| Framework        | Flutter 3.x (Dart 3.3+)                           |
| State Management | flutter_riverpod + riverpod_annotation (code-gen) |
| Routing          | go_router                                         |
| Data Models      | freezed + json_serializable                       |
| Networking       | dio                                               |
| Local Storage    | shared_preferences                                |
| Media & Files    | image_picker + file_picker                        |
| Location         | geolocator                                        |
| External Links   | url_launcher                                      |
| SVG Rendering    | flutter_svg                                       |
| Dev Preview      | device_preview                                    |

## Architecture

Feature-driven folder structure:

```
lib/
  core/
    constants/     — AppConstants (base URL, app name)
    network/       — Dio client provider
    router/        — GoRouter with ShellRoute + bottom nav
    theme/         — AppColors, AppTheme (light/dark)
  features/
    home/          — HomePage (hero + info cards)
    analysis/
      domain/      — AnalysisState (Freezed), AnalysisStateNotifier
      data/        — Repository impl (stub)
      presentation/
        pages/     — BasicInfoPage, QuickCheckPage, DeepCheckPage,
                      OverviewPage, AnalyzingPage, AnalysisResultPage,
                      ChatTemplatePage
        widgets/   — StepProgressBar
    history/
      domain/      — HistoryRecord model, RiskLevel enum
      data/        — Mock history data (12 records)
      presentation/
        pages/     — HistoryPage, HistoryDetailPage
    explore/
      domain/      — Kos listing models, filter state
      data/        — Listing data + location providers
      presentation/
        pages/     — ExplorePage, ExploreDetailPage, ExploreAllReviewsPage
        widgets/   — Listing cards, filter sheet
```

## Routes

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

## Getting Started

1. **Install Flutter** — [flutter.dev](https://flutter.dev/docs/get-started/install)

2. **Get dependencies**

   ```bash
   flutter pub get
   ```

3. **Run code generation** (required for Riverpod + Freezed)

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run -d chrome   # web
   flutter run              # connected device
   ```

## Assets

| File                             | Description                        |
| -------------------------------- | ---------------------------------- |
| `assets/icons/house_bg.svg`      | Hero background house illustration |
| `assets/icons/koscheck_logo.svg` | KosCheck wordmark logo             |

---

made by yazid
