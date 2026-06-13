# 🧬 OmicVerse — Project Log & Session History

> **Purpose**: This is our shared memory. It tracks what we've built, where we left off, key decisions, blockers, and patterns — so we never lose context between sessions.
>
> **How to use**: At the start of any new session, tell me:
> *"Read omicverse_project_log.md and continue where we left off."*

---

## 📊 Overall Progress

| Phase | Name | Status | Started | Completed |
|-------|------|--------|---------|-----------|
| 0 | Pre-requisites (User's manual steps) | ✅ Complete | 2026-06-10 | 2026-06-10 |
| 1 | Project Scaffold | ✅ Complete | 2026-06-10 | 2026-06-10 |
| 2 | Safe Configuration & Secrets | ✅ Complete | 2026-06-10 | 2026-06-10 |
| 3 | Supabase Database & Auth | ✅ Complete | 2026-06-10 | 2026-06-10 |
| 4 | Demo Mode & Home Screen | ✅ Complete | 2026-06-10 | 2026-06-10 |
| 5 | Core API Wrapper | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 6 | Upload Pipeline | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 7 | Variant Module MVP | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 8 | Expression Module MVP | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9A | Genome Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9B | Pathway Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9C | Protein Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9D | Regulatory Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9E | Population Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9F | PRS Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9G | Methylation Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9H | CRISPR Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9I | Cancer Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9J | Evolution Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9K | Splicing Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9L | Drug Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9M | 3D Genome Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 9N | Multi-Omics Module | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 10 | Collaboration (Realtime) | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 11 | Deployment (GitHub Pages) | ✅ Complete | 2026-06-13 | 2026-06-13 |
| 12 | Release Hardening | ✅ Complete | 2026-06-13 | 2026-06-13 |

**Legend**: ⬜ Not started · 🔄 In progress · ✅ Complete · ⚠️ Blocked

---

## 🔖 Where We Left Off

> **Last session**: 2026-06-13
> **Last action**: 🏆 Phase 12 complete — ALL PHASES DONE! CSP meta tag, WCAG AA contrast verification, error boundary widget, a11y utilities, SEO meta tags, 189 total tests passing, 0 errors, 0 warnings. PROJECT COMPLETE.
> **Next step**: 🎉 **SHIP IT!** Push to GitHub and deploy.

---

## 📝 Session History

### Session 1 — 2026-06-10

**What happened**:
- Read the entire 3,120-line blueprint file from `E:\OMICVERSE_BLUEPRINT_FINAL_v8 (1).md`
- Summarized the blueprint structure (16 parts, 12+ phases, 15 modules)
- Clarified: app is NOT demo-only — has live API mode, upload mode, and real research workflows
- Estimated build time: ~55–70 hours (2 weeks full-time, 4–5 weeks part-time)
- Created this project log for persistent tracking

**Decisions made**:
- Will follow phase-by-phase approach from the blueprint
- User will complete Phase 0 manually before we start coding

**Blockers**: None remaining for Phase 0.

---

### Session 2 — 2026-06-10 (continued)

**What happened**:
- Verified Flutter 3.44.1 + Dart 3.12.1 installed at `C:\flutter`
- Added `C:\flutter\bin` to User PATH permanently
- Ran `flutter doctor` — Chrome ✅, Windows ✅, Network ✅
- User created Supabase project (region: auto-selected)
- Created `.gitignore` (BEFORE `.env` — security first)
- Created `.env` with real Supabase URL + anon key
- Created `.env.example` with placeholder values
- Instructed user to set auth redirect URLs in Supabase dashboard

**Decisions made**:
- App directory will be `E:\omicverse\app\` (Flutter project root)
- Skipping Android/iOS toolchains — targeting web (Chrome) first
- Supabase auth redirect URLs configured for localhost:8080

**Blockers**:
- None — ready for Phase 1

---

### Session 3 — 2026-06-10 (Phase 1 Build)

**What happened**:
- Created Flutter project via `flutter create` at `E:\omicverse\app`
- Downloaded 6 fonts from Google Fonts (Orbitron, IBM Plex Sans, JetBrains Mono, Rajdhani)
- Created 10 core source files (theme, navigation, models, providers, services, config)
- Created 9 core widget files (GlowCard, DnaLoader, NeonButton, ModuleHeader, ErrorState, PrivacyUploadBanner, ResearchDisclaimer, FileUploadZone, EvidenceBadge)
- Created main.dart and app.dart per blueprint Sections 8 and 8.2
- Created app_router.dart with 22 routes and styled placeholder screens
- Fixed 4 lint issues (3x prefer_const_constructors, 1x deprecated anonKey→publishableKey)
- Created unit tests for AppError and ChromosomeNormalizer (11 tests)
- **Stop gate results**: `flutter analyze` ✅ 0 issues | `flutter test` ✅ 11/11 pass

**Decisions made**:
- Using variable font files instead of separate weight files (Orbitron, JetBrains Mono)
- Phase 1 packages only — commented out later-phase deps in pubspec.yaml
- Used `publishableKey` instead of deprecated `anonKey` for Supabase 2.14+

**Blockers**:
- None

---

### Session 4 — 2026-06-10 (Phase 3 Build)

**What happened**:
- Created 5 SQL migration files in `supabase/migrations/`:
  - `001_schema.sql`: 11 tables (profiles, projects, bookmarks, variant_analyses, etc.)
  - `002_rls.sql`: RLS enabled on all tables with ownership policies + collaboration access
  - `003_triggers.sql`: Auto-create profile on signup + auto `updated_at` on 6 tables
  - `004_indexes.sql`: 18 performance indexes
  - `005_rpcs.sql`: `delete_user_data()` RPC using `auth.uid()` internally (GDPR safe)
- Created `auth_service.dart` with sign-up, sign-in, sign-out, token refresh, deep link, GDPR delete
- Created `login_screen.dart` with neon-themed sign-in/sign-up toggle + demo mode bypass
- Updated `app_router.dart` to use real LoginScreen on `/login` route
- Fixed 1 lint issue (added `mounted` guard in auth state listener)
- **Stop gate results**: `flutter analyze` ✅ 0 issues | `flutter test` ✅ 19/19 pass

**Decisions made**:
- Auth uses static methods on AuthService class (matches blueprint pattern)
- Login screen auto-shows "Demo Mode" button when Supabase not configured

**⚠️ USER ACTION REQUIRED**:
- Must run SQL migrations in Supabase SQL Editor (001→002→003→004→005 in order)
- Must enable Realtime for collaboration tables in Database → Replication

**Blockers**:
- None (SQL runs independently from Flutter code)

---

### Session 5 — 2026-06-14 (Production API Hardening & JOSS Readiness)

**What happened**:
- Fixed the Hive `CacheService` initialization issue by calling `CacheService.init()` in `main.dart` (prevented late-init exceptions on live API queries).
- Persisted the `isDemoMode` preference to the local Hive `preferences` box, so toggling off Demo Mode saves properly.
- Added proper JSON serialization (toJson/fromJson) for `PopulationVariant` and `GeneInfo` in their respective services and updated their cache retrieval logic to prevent silent fallback to demo mode.
- Hardened the `RegulatoryService` to resolve the actual coordinates of target genes and query the real public ENCODE SCREEN GraphQL API (`https://factorbook.api.wenglab.org/graphql`) for coordinate-based annotations.
- Fixed the `DrugService.searchByTarget` method by performing a real 2-step ChEMBL API search (resolving gene components synonyms to component targets and fetching their mechanisms).
- Hardened the `CancerService` to query Simple Somatic Mutations (SSMs) directly from the NCI Genomic Data Commons (GDC) API, correctly parsing case occurrences and projects.
- Implemented real computational Cas9 guide RNA design in `CrisprService.designGuides` by fetching Ensembl sequences, scanning for `NGG` PAM motifs, filtering out poly-T transcription terminators, and scoring candidates by GC content.
- Added new unit tests verifying the model serialization and guide design algorithms.
- **Verification results**: `flutter analyze` ✅ 0 issues | `flutter test` ✅ 194/194 pass

**Decisions made**:
- Chose GDC API over cBioPortal API because GDC provides stable, direct gene-level mutations search without needing pre-configured study molecular profiles.
- Implemented Cas9 guide RNA design as a real local computational search rather than a static mock database lookup.

**Files created/modified**:
- `app/lib/main.dart`
- `app/lib/core/providers/app_providers.dart`
- `app/lib/features/settings/settings_screen.dart`
- `app/lib/features/population/services/population_service.dart`
- `app/lib/features/genome/services/genome_service.dart`
- `app/lib/features/regulatory/services/regulatory_service.dart`
- `app/lib/features/drug/services/drug_service.dart`
- `app/lib/features/cancer/services/cancer_service.dart`
- `app/lib/features/crispr/services/crispr_service.dart`
- `app/test/production_hardening_test.dart`

---

## 🧠 Key Patterns & Conventions

> Things we've agreed on or discovered that should persist across sessions.

### Blueprint Rules (non-negotiable)
- One phase at a time. Never skip.
- `flutter analyze` + `flutter test` after every phase — zero issues before moving on
- No secrets in Flutter code — ever
- NCBI_API_KEY only in Supabase Edge Function secrets
- `rootNavigatorKey` lives in `app_navigator.dart`, never `main.dart`
- Bundled fonts only — no `GoogleFonts` runtime network calls
- All file parsing in `Isolate.run()`, never main thread
- `delete_user_data()` uses `auth.uid()` internally, no client parameter
- Connectivity check: `results.isEmpty || results.every((r) => r == ConnectivityResult.none)`

### Project Location
- **Project root**: `E:\omicverse\`
- **Blueprint file**: `E:\omicverse\OMICVERSE_BLUEPRINT_FINAL_v8 (1).md`
- **This log**: `E:\omicverse\omicverse_project_log.md`
- **Artifacts backup**: `C:\Users\rafiu\.gemini\antigravity\brain\5ae1b61b-f954-4f25-a87e-4fbc346b7527\`

---

## 🚧 Known Blockers & Issues

| # | Issue | Status | Resolution |
|---|-------|--------|------------|
| 1 | Flutter not in PATH | ✅ Fixed | Added `C:\flutter\bin` to User PATH permanently |
| 2 | Phase 0 incomplete | ✅ Fixed | Flutter installed, Supabase created, .env ready |

---

## 📁 File Registry

> Key files created during the build. Updated as we go.

| File | Phase | Purpose |
|------|-------|---------|
| `OMICVERSE_BLUEPRINT_FINAL_v8 (1).md` | — | Master build specification |
| `omicverse_project_log.md` | — | This session tracker |
| `app/.gitignore` | 0 | Protects .env from git commits |
| `app/.env` | 0 | Real Supabase credentials (NEVER commit) |
| `app/.env.example` | 0 | Safe placeholder for GitHub |
| `app/pubspec.yaml` | 1 | Dependencies and font declarations |
| `app/analysis_options.yaml` | 1 | Strict lint rules |
| `app/lib/main.dart` | 1 | Entry point with dart-define + .env config |
| `app/lib/app.dart` | 1 | App shell with Hive lifecycle |
| `app/lib/core/theme/colors.dart` | 1 | Color system (backgrounds, neons, tiers, gradients) |
| `app/lib/core/theme/typography.dart` | 1 | Font styles (Orbitron, IBMPlexSans, etc) |
| `app/lib/core/animations/animations.dart` | 1 | Duration constants |
| `app/lib/core/models/app_error.dart` | 1 | Sealed error hierarchy |
| `app/lib/core/providers/app_providers.dart` | 1 | appVersionProvider |
| `app/lib/core/navigation/app_navigator.dart` | 1 | rootNavigatorKey |
| `app/lib/core/navigation/app_router.dart` | 1 | 22 routes + placeholder screens |
| `app/lib/core/services/connectivity_service.dart` | 1 | Offline detection |
| `app/lib/core/services/chromosome_normalizer.dart` | 1 | Chr format conversion |
| `app/lib/core/config/app_config.dart` | 1 | Runtime config model |
| `app/lib/core/widgets/*.dart` (9 files) | 1 | GlowCard, DnaLoader, NeonButton, etc. |
| `app/test/core_test.dart` | 1 | 11 unit tests |
| `app/assets/fonts/` (6 files) | 1 | Bundled font files |
| `app/lib/core/config/app_config.dart` | 2 | Enhanced with fromEnvironment factory + safeKeys |
| `app/lib/core/providers/app_providers.dart` | 2 | appConfigProvider + isDemoModeProvider |
| `app/test/config_test.dart` | 2 | 8 config tests |
| `app/supabase/migrations/001_schema.sql` | 3 | 11 database tables |
| `app/supabase/migrations/002_rls.sql` | 3 | Row Level Security policies |
| `app/supabase/migrations/003_triggers.sql` | 3 | Profile creation + updated_at triggers |
| `app/supabase/migrations/004_indexes.sql` | 3 | 18 performance indexes |
| `app/supabase/migrations/005_rpcs.sql` | 3 | delete_user_data() RPC |
| `app/lib/core/services/auth_service.dart` | 3 | Supabase auth wrapper |
| `app/lib/features/auth/login_screen.dart` | 3 | Login/signup UI with demo mode |

---

## 💡 Notes & Reminders

- If context is lost mid-session, tell me: *"Re-read OMICVERSE_BLUEPRINT_FINAL_v8.md and omicverse_project_log.md. Continue Phase N."*
- The blueprint is at: `E:\OMICVERSE_BLUEPRINT_FINAL_v8 (1).md`
- Supabase free tier pauses after ~1 week of inactivity — just click "Restore" in dashboard
- Horvath clock weights CSV only needed at Phase 9G — skip for now
- NCBI API key only needed at Phase 7 — skip for now
