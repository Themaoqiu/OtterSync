# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OtterSync is a team collaboration and project management platform inspired by Jira Mobile. The client is built with Flutter; work item data is stored in Firebase Cloud Firestore.

## Commands

```bash
flutter pub get       # Install dependencies
flutter run           # Run the app
flutter analyze       # Static analysis (uses flutter_lints)
flutter test          # Run tests
```

Firebase CLI (always use npx to get latest):
```bash
npx -y firebase-tools@latest --version
npx -y firebase-tools@latest deploy
```

Firebase Functions are in `functions/` (TypeScript, Node 24, Genkit AI).

## Architecture

### Data Flow

`main.dart` → Firebase init → `routes/index.dart` (GoRouter + Theme) → Pages → `WorkItemApi` → Firestore

All Firestore access goes through `lib/viewmodels/work_item_api.dart`, the single data access layer. It wraps `FirebaseFirestore.instance` and manages collections: `workspaces`, `workTypes`, `users`, `teams`, `labels`, `workItems`, plus `_meta` for counters. First access auto-seeds demo data.

### Routing

GoRouter with `StatefulShellRoute.indexedStack` for 5-tab bottom navigation:
- `/home` (主页), `/spaces` (空间), `/all-work` (所有工作), `/dashboards` (仪表板), `/notifications` (通知)

Additional routes: `/account`, `/space-details/:spaceId`, `/create-work-item`. All routing is centralized in `lib/routes/index.dart`, which also exposes `getRootWidget()`.

### State Management

No external state management library. Pages use `StatefulWidget` + `setState()`. Theme is managed via `ChangeNotifier` + `InheritedNotifier` (`ThemeControllerScope`).

### Theming

Design tokens in `lib/theme/design_tokens.dart`: `AppPalette`, `AppColors` (light/dark), `AppSpace`, `AppShadows`, `AppDecorations`. Theme built in `routes/index.dart` via `_buildAppTheme()` — Material 3, Jira-inspired blue palette. Default is dark mode.

### Domain Models

- `lib/viewmodels/jira_models.dart` — Core models: `JiraSpace`, `IssueSummary`, `QuickAccessItem`, `BacklogGroup`, etc.
- `lib/viewmodels/work_item_models.dart` — DTOs: `WorkItemCreateRequest`, `WorkItemResponse`, `LookupOption`, etc.

## Folder Conventions

- Pages: `lib/pages/<Feature>/index.dart`
- Reusable components: `lib/components/<Feature>/`
- Routes: `lib/routes/index.dart`
- State: `lib/state/`
- Theme tokens: `lib/theme/`
- ViewModels / data layer: `lib/viewmodels/`

Directory names are PascalCase. Component file names are PascalCase (e.g., `HeroSection.dart`). The `file_names: false` lint rule is intentionally disabled to allow this.

## Development Rules

**Always follow the skills in `skills/` when developing:**
- `skills/ottersync-flutter-style/SKILL.md` — Flutter code style, folder layout, component naming, routing, UI design rules
- `skills/ottersync-flutter-style/references/clean_style.md` — Style baseline
- `skills/firebase-develop/*/SKILL.md` — Firebase workflows (use `npx -y firebase-tools@latest`, MCP server tools, official patterns)

Key style rules from skills:
- Use `package:` imports, not relative
- Prefer UI-oriented component names: `Section`, `Header`, `Card`, `Panel`, `Tile`, `Item`, `Bar`, `Banner`
- Keep widget trees inline and readable; extract to small private helpers (`_buildSections()`) when long
- Read `skills/ottersync-flutter-style/references/DESIGN.md` before any UI work
- Match surrounding file polish level; don't refactor unrelated code for style
- Don't hardcode user-specific or environment-specific values in data/viewmodel code

## Firebase

- Project: `ottersync-24da2`
- Firestore region: `asia-east1`
- Emulators: Auth (9099), Firestore (8080)
- `firestore.rules` currently allows all read/write (expires 2026-05-30)
- Platform configs: `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `macos/Runner/GoogleService-Info.plist`

## UI Language

All user-facing strings are in Simplified Chinese.
