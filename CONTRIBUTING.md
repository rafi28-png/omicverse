# Contributing to OmicVerse

Thank you for your interest in contributing to OmicVerse! This document provides
guidelines and information for contributors.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.32+)
- A modern web browser (Chrome, Firefox, Edge)
- Git

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/rafi28-png/omicverse.git
cd omicverse/app

# Install dependencies
flutter pub get

# Run locally (opens in browser)
flutter run -d chrome

# Run tests
flutter test
```

### Environment Variables (Optional)

For Supabase integration, create `app/.env`:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

Without these, the app runs in demo mode with bundled sample data.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/rafi28-png/omicverse/issues) first
2. Use the bug report template
3. Include: browser, OS, steps to reproduce, expected vs actual behavior
4. Include console output if available (F12 → Console)

### Suggesting Features

1. Open a [GitHub Discussion](https://github.com/rafi28-png/omicverse/discussions) or Issue
2. Describe the use case and expected behavior
3. If proposing a new omics module, specify the data source/API

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run tests (`flutter test`) — all must pass
5. Run analysis (`flutter analyze`) — no errors allowed
6. Commit with a descriptive message
7. Push to your fork and open a Pull Request

### Code Style

- Follow [Dart style guidelines](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter analyze` before committing
- Keep widgets focused and reusable
- Add tests for new models and services

### Adding a New Omics Module

1. Create a new directory under `lib/features/your_module/`
2. Add a screen widget extending the app's design system
3. Create data models in `lib/core/models/`
4. Add demo data for offline/fallback mode
5. Register the route in `lib/core/navigation/app_router.dart`
6. Add the module card to `home_screen.dart`
7. Write tests in `test/`

## Project Structure

```
app/
├── lib/
│   ├── core/           # Shared infrastructure
│   │   ├── config/     # App configuration
│   │   ├── models/     # Data models
│   │   ├── navigation/ # Router and navigation
│   │   ├── providers/  # Riverpod state management
│   │   ├── services/   # API, cache, auth services
│   │   ├── theme/      # Colors, typography
│   │   ├── utils/      # Utilities (safe_hive, etc.)
│   │   └── widgets/    # Reusable UI components
│   ├── features/       # Feature modules (one per omics layer)
│   ├── app.dart        # Root widget
│   └── main.dart       # Entry point
├── test/               # Unit and widget tests
└── web/                # Web-specific files (index.html)
```

## Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## Questions?

Open an issue or start a discussion on GitHub. We welcome contributions from
researchers, students, and developers at all levels.
