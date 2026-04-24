# DSGet Agent Guide

## Scope

This file applies to the whole repository. Local instructions here take priority
over external examples. Use Dimillian's public SwiftUI apps as reference material,
but adapt the patterns to DSGet instead of copying code or reshaping unrelated
features.

Dimillian references checked on 2026-04-24:

- `Dimillian/IceCubesApp`: modern multiplatform SwiftUI, feature packages,
  environment-injected services, explicit router and sheet destinations,
  reusable design-system views, enum-based loading/error states.
- `Dimillian/CodexSkillManager`: macOS SwiftUI app using `NavigationSplitView`,
  root-owned stores injected into the environment, native commands, toolbar items,
  focused feature folders, and a strict build-after-change rule.
- `Dimillian/ReviseApp`: `AGENTS.md` points to `CLAUDE.md`; uses SwiftUI,
  SwiftData, `@Observable` controllers, feature-local state, availability gates,
  and purposeful animations/accessibility.
- `Dimillian/ConflictMonitor` and `Dimillian/Mac-Monitor`: keep transport and
  state transitions in clients/stores, keep view files render-focused, use safe
  git behavior, and validate with the canonical build/run flow.
- `Dimillian/RunewordsApp` and `Dimillian/AppRouter`: small SwiftUI feature
  folders, search/filter flows, explicit routing, and focused package tests.

## Project Snapshot

DSGet is a SwiftUI client for Synology Download Station across iOS and macOS,
with widgets, watch support, localized strings, and shared domain/service code.

Current layout:

- `DSGet/App`: app entry points, dependency container, constants, quick actions,
  platform-specific macOS support.
- `DSGet/Views`: SwiftUI screens and shared UI components.
- `DSGet/ViewModels`: screen state and user-action orchestration for the current
  architecture.
- `DSGetCore/Sources/DSGetCore`: domain models, API clients, services, and
  protocols shared by app targets and tests.
- `DSGetTests` and `DSGetUITests`: unit and UI coverage.
- `DSGetWidgets` and `iDSGet Watch App`: companion surfaces.

## SwiftUI Architecture Rules

1. Read the nearest existing DSGet view, view model, or service before adding a
   new pattern.
2. Keep views render-focused. Networking, persistence, Synology API calls, and
   session mutations belong in services, clients, or view models/stores.
3. Keep state ownership narrow: `@State` for local UI, `@Binding` for parent-owned
   values, environment injection for app-wide services, and view models/stores
   only when they own real screen behavior.
4. Prefer modern SwiftUI and async/await: `.task`, `.task(id:)`, `.refreshable`,
   cancellation, and debounced search/filter work where appropriate.
5. For new complex flows, prefer enum-driven routing/sheet/content state over
   several unrelated Boolean flags.
6. Build small views named after their primary type. Split a file when it mixes
   layout, formatting, networking, routing, and unrelated helper types.
7. Use semantic system colors, materials, SF Symbols, localized strings, and
   existing DSGet support helpers before inventing custom styling.
8. Preserve accessibility identifiers and add them for new interactive controls
   used by UI tests.

## Content State Rules

All list/detail/search surfaces must distinguish these states explicitly:

- loading or refreshing
- offline or connectivity blocked
- permission/session/authentication problem
- server/API error with a retry path
- truly empty data set
- no results caused by the current search, filter, or scope

Do not show the same copy or icon for "there are no tasks" and "this filter has
no matching tasks". Keep recovery actions specific: clear filter, retry, open
settings, sign in again, or test the connection.

## Login And Settings Rules

Login and settings should make server trust visible:

- Show the current server and session status when available.
- Keep "Test Connection" available where credentials/server configuration are
  edited or inspected.
- Validate required fields inline before network work starts.
- Preserve recent server history and make switching explicit.
- Treat logout, session refresh, and failed authentication as first-class states,
  not generic errors.

## iOS And macOS Rules

Keep behavior consistent, but use platform-native structure:

- iOS can favor compact navigation, bottom/tab affordances, sheets, and touch
  ergonomics.
- macOS should favor `NavigationSplitView`, stable sidebar selection, native
  settings scenes, toolbars, commands, keyboard shortcuts, contextual menus, and
  pointer-friendly hit targets.
- Do not hide important macOS actions behind touch-only gestures.
- Let macOS sidebars and split views use system appearance by default; reserve
  custom surfaces for detail cards or focused content.
- Keep `DSGetMacSupport` responsible for desktop-specific scene/settings polish.

## Routing And Placement

Use these placement defaults:

- Synology API behavior: `DSGetCore/Sources/DSGetCore/Services` and protocol
  files beside the related service.
- App/session/server coordination: `DSGet/ViewModels/AppViewModel.swift`,
  `LoginViewModel.swift`, and auth services as appropriate.
- Task list/detail UI: `DSGet/Views/Tasks` plus `TasksViewModel` or
  `TaskDetailViewModel`.
- Feed list/detail UI: `DSGet/Views/Feeds` plus `FeedsViewModel` or
  `FeedDetailViewModel`.
- Cross-screen states/components: `DSGet/Views/Shared` or a narrow support file.
- macOS-only UI: `DSGet/App/DSGetMacSupport.swift` or a macOS-scoped view.

## Validation

After Swift or project changes, run the smallest useful validation first, then
broaden when behavior crosses targets.

Build commands:

```bash
xcodebuild -project DSGet.xcodeproj -scheme DSGet -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
xcodebuild -project DSGet.xcodeproj -scheme DSGetMac -destination 'platform=macOS' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

Run relevant unit/UI tests when changing service behavior, view models, routing,
login/session handling, filters/search, or accessibility identifiers.

## Git And Safety

- Prefer safe inspection commands: `git status`, `git diff`, `git log`.
- Do not reset, revert, or overwrite unrelated user changes.
- Keep edits scoped to the requested behavior.
- Fix root causes instead of masking state bugs with UI-only workarounds.
- Documentation should describe current behavior only.
