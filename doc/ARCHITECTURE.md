# Architecture agreed for the refactor

Agreed on 2026-11-20. Implemented in the Android application; native device validation remains pending. See [the migration tasks](REFACTOR_PLAN.md) for scope, ownership and acceptance checks.

For an introduction in Spanish with a project walkthrough and practical examples, start with [the team guide](GUIA_ARQUITECTURA.md).

## Purpose and limits

Keep this Flutter Android mock understandable and prepare feature actions for a later Linux kiosk with Leap Motion. Preserve the existing Spanish UI, sample content, working interactions and local data unless a task explicitly describes a correction. Do not add production authentication, a backend, new routes, new gestures or desktop integration during this refactor.

The following decisions are agreed:

- Organize by feature; remove the global `ui`, `data` and `domain` layers.
- Use `ChangeNotifier` viewmodels for substantial screen/flow state. Small visual state may stay in widgets.
- Use concrete classes for actual data or device access. No mandatory repository/service/datasource chain, interface/implementation pair, use-case layer, service locator or dependency-injection package.
- Create shared data/session objects once at the application root and pass dependencies through constructors.
- Give each screen/flow one owner for its viewmodel and temporary resources.
- Keep navigation, dialogs and other Flutter presentation effects in widgets.
- Separate device data/gesture recognition from feature actions. Connect them with callbacks.

## File organization

```text
lib/
  main.dart                         Application entry point
  app.dart                          Shared dependencies, restoration and initial screen
  auth/
    session_state.dart              Shared current session
    language_selection_screen.dart
    sign_in_screen.dart
    sign_in_view_model.dart
    login_page.dart
    login_view_model.dart
    login_form.dart
  home/
    home_screen.dart
    home_view_model.dart
    schedule_item.dart
    sample_schedule.dart
    widgets/
  events/
    event.dart
    event_catalog.dart              CSV access, shared by events and Home
    events_screen.dart
    events_view_model.dart          Concrete owner of visible discovery state
    discarded_events_screen.dart
    swipe_deck_view_model.dart      Touch/animation state, not sensor recognition
    widgets/
  orientation/
    faculty_map_screen.dart
    faculty_map_view_model.dart
    directions_page.dart
    directions_flow_view_model.dart
    origin_map_page.dart
    map_zone.dart
    waypoint.dart
    location_client.dart            Feature-specific location access/decisions
    data/
      floors.dart
      routes.dart
      *_floor_zones.dart
    widgets/
  qr/
    qr_scanner_screen.dart          Shared camera screen returning String?
  miscellaneous/
    miscellaneous_page.dart
    service_option.dart
    service_options.dart
    widgets/
  storage/
    local_store.dart
  input/
    floor_motion_input.dart
    event_tilt_input.dart
    ...                             Recognition/calibration helpers only if useful
assets/
  ...                               Existing CSV and image files
```

This map identifies responsibility and destination; it does not require empty folders or a class for every file. Keep `widgets/` where there are enough substantial components to make it helpful. A small widget used by one screen may be private in that screen file. Per-floor zone files remain separate because they contain substantial editable geometry.

Screens may use another feature's public entry screen, such as Home opening events or directions opening the scanner. Home may use `EventCatalog` and `Event`. Avoid importing another feature's private widgets or viewmodels. If two screens need the same viewmodel state within one flow, pass the existing instance rather than creating another.

## Responsibility rules

| Component | Owns | Does not own |
|---|---|---|
| Screen/widget | Layout, navigation, dialogs, animation, focus, small visual state | CSV parsing, persistence keys, mobile movement recognition |
| ViewModel | Flow state, feature decisions, load/error state, feature actions | BuildContext, Navigator, showDialog, plugin sensor events |
| Model | Named data used by the feature | Storage lookup or device subscriptions |
| Static catalogue | Constant sample classes, plants, zones and routes | Loading state, repository abstractions |
| Access class | Reading/writing data, device connection, necessary conversion | Navigation or screen-specific state |
| Movement input | Sensor subscriptions, calibration, thresholds, recognition and repeated-gesture prevention | Selected floor, event collection, route progression |

Examples:

- A map viewmodel selects a floor and enforces its boundaries. The map widget paints it and plays presentation feedback.
- A directions viewmodel selects the current waypoint and handles arrival decisions. Its widget shows the arrival confirmation dialog.
- A sign-in viewmodel asks `SessionState` to store a mock identity. The widget navigates after success.
- The QR screen owns its camera and returns text; it does not create a session or validate a TUI.

## Shared dependencies and ownership

Create one `LocalStore`, one `EventCatalog` and one `SessionState` at the root. `SessionState` receives `LocalStore`; feature viewmodels receive the shared objects they need. Use explicit constructor arguments, not factories returning global singletons and not fallback construction hidden inside migrated viewmodels.

The app widget and its route builders can pass dependencies to screens. No dependency container class is required just to bundle them. The root owns and disposes `SessionState` when the app root is disposed. `LocalStore` and `EventCatalog` need no disposal unless their implementation later owns resources.

A stateful screen creates its viewmodel in `initState` and disposes it in `dispose`. A child that receives that viewmodel borrows it and must not dispose it. Feature subscriptions to `SessionState` must be removed by the owner. Async completions must not notify a disposed viewmodel or mutate a newer request/session.

Temporary device inputs are owned by the screen/flow that activates them. Stop subscriptions and timers when leaving it; pause camera/motion input when the app is inactive and resume only when that flow is active. Register and unregister callbacks/listeners in the same ownership scope. A future kiosk-wide Leap connection can have a longer lifetime; that decision is deferred.

## Data contracts

These public responsibilities and names are the integration contract. Additional helpers remain private unless there is a real consumer.

### LocalStore

A concrete class wrapping `SharedPreferences`, JSON encoding and existing keys. It has no `ChangeNotifier` and is not a global event bus. Its constructor receives the initialized `SharedPreferences` instance.

| API | Meaning |
|---|---|
| `String? readUsername()` | Read the persisted nonblank username, or null |
| `Future<void> saveUsername(String username)` | Save a trimmed username and clear guest state |
| `Future<void> saveGuestSession()` | Persist guest mode and clear any username |
| `Future<void> clearSession()` | Remove username and guest state; keep saved events |
| `List<String> readSavedEventIds(String username)` | Read saved IDs, returning an empty list when absent |
| `List<String> readDiscardedEventIds(String username)` | Read discarded IDs, returning an empty list when absent |
| `Future<void> saveEvent(String username, String eventId)` | Save once and remove the same ID from discarded events |
| `Future<void> discardEvent(String username, String eventId)` | Discard once and remove the same ID from saved events |
| `Future<void> removeSavedEvent(String username, String eventId)` | Remove from saved events without implicitly discarding |
| `Future<void> resetEvents(String username)` | Await clearing both collections |
| `List<String> readPreferredCategories(String username)` | Preserve reading existing account preferences during migration |
| Explicit onboarding/tutorial getters and setters | Hide the existing keys; no general key/value API at call sites |

Synchronous reads are intentional with an initialized preferences instance; writes still return futures. Serialize mutations inside `LocalStore` so concurrent read-modify-write operations cannot overwrite each other. For operations changing saved/discarded collections, callers receive completion only after the relevant writes. This does not promise transactional disk storage; report write failures rather than silently claiming success.

Retain these keys and their current encodings: `user_session`, `guest_session`, `user_events`, `discarded_events`, `usuarios`, `language_onboarding_completed`, `has_seen_events_swipe_tutorial`, `inside_orientation_tutorial_completed`. A key/schema change needs an explicit migration, not an app-data reset. Guest discarded events retain the existing `__unregistered__` storage namespace. Do not expose that sentinel as a displayed or signed-in username.

Account registration and password checking have no current consumers. Remove their unused code and `bcrypt` only after preference reads have moved and dependency references have been checked. Do not add a preference editor or new account flow.

### SessionState

A small shared `ChangeNotifier` in `auth/`, not another storage implementation:

- Receives `LocalStore` and exposes `String? username` and `bool isSignedIn`.
- Provides `restore()`, `signIn(String username)`, `continueAsGuest()` and `signOut()`, all returning `Future<void>`.
- Stores changes before publishing the new in-memory session. Failing operations leave the previous published session intact. Prevent overlapping session mutations.
- Only `SessionState` writes session keys after migration. Other viewmodels read the live identity here, not independently from preferences.
- No username means guest-level feature behavior. Onboarding completion remains a separate persisted flag; it is not an authenticated-session flag.

Restore before showing session-dependent Home/events. A saved identity must survive restart consistently in both. Onboarding still shows language followed by access choices on first launch, and later launches open Home. If initialization fails, keep it visible as a startup error with retry rather than silently overwriting stored state as guest.

`SessionState` has no event filters, sensor state or navigation. For mock QR/email access it stores an identity without university verification. Preserve current form validation; a password field is not evidence of real authentication.

### EventCatalog and feature refresh

`EventCatalog.loadEvents()` returns `Future<List<Event>>` by parsing the existing bundled CSV. Cache the loaded catalogue and reuse an in-flight load so cards/Home do not independently reread and parse the entire file. Failed loads must remain retryable. No interface, datasource or second implementation is required.

Each events screen has one concrete viewmodel for its visible list. Discovery controls and cards use that same owner; the swipe viewmodel may separately own animation/touch state. The discarded screen owns a separate EventsViewModel instance with `discardedOnly: true`; the same concrete implementation handles filtering and mutations without a parallel class. A common abstract viewmodel solely for rendering a list is unnecessary: pass `events`, flags and callbacks to list/card widgets.

Await persistence before confirming save/discard/reset. During the mutation, prevent repeated gestures/buttons from committing the same action. Update/reload the visible list explicitly on success; retain it and expose an error on failure. Keep current ordering, future-event filters, category preferences, guest restrictions and the four-saved-event Home limit. Remove duplicate IDs when interpreting existing collections.

Home reloads saved events after returning from the event catalogue; discovery reloads after returning from discarded-event recovery. Session changes trigger the relevant feature refresh. Do not use a singleton notifier or `UniqueKey` subtree reconstruction as the data synchronization mechanism. Guard old in-flight results when a session changes.

### Location

Location remains feature-specific in `orientation/location_client.dart`. A concrete client can combine the current service/repository responsibilities without adding another interface. Its public proximity results must not expose Geolocator `Position` or permission types.

Accept waypoint coordinates/radius rather than importing a screen/model into a global data layer. Preserve current permission handling, timeouts, 750 m near/far accuracy checks, GPS arrival confirmation and manual fallback. A fixed kiosk origin is future behavior, not part of this Android refactor.

## Movement input contract

Use separate concrete `FloorMotionInput` and `EventTiltInput` objects because the current interactions have different algorithms. Share lower-level sampling helpers only if both actually need them. Keep raw sensor types and algorithm thresholds inside `input/`.

- `FloorMotionInput`: up/down callbacks; owns calibration and detection state. It may expose observable calibration progress/feedback for its tutorial. Floor limits belong to the map viewmodel, not this input.
- `EventTiltInput`: save/discard callbacks and normalized progress/cancel feedback needed for the existing animated card interaction. It must not own the event list or pixel layout.
- Both provide explicit start/stop/dispose lifecycle operations. Construction alone does not start sensor capture. Stop/dispose cancel pending emissions and timers.
- Unsupported/unavailable sensors leave manual controls usable and do not launch mandatory calibration. Do not report unconditional support.
- Mobile-specific tutorial widgets can stay with the consuming feature's widgets, but receive input calibration state rather than requiring the complete map/events viewmodel.

The screen/flow connects callbacks to actions such as `nextFloor()`, `previousFloor()`, `saveCurrentEvent()` and `discardCurrentEvent()`. Touch dragging/animations stay in feature presentation code. Sensor recognition and its equivalent thresholds move out intact before any tuning.

Do not introduce a universal input interface, global event bus or gesture enum covering every platform. A later Leap client receives native data over the legacy local WebSocket, then its recognizer invokes the same feature actions. It is not implemented by this migration.

## Async results, errors and presentation effects

- Async operations return `Future<T>` or `Future<void>`, not `async void`, except synchronous callback signatures required by Flutter. Handle failures of futures launched from callbacks.
- Return data directly. Use nullable results for user cancellation, not for operational errors.
- Loading screens expose `isLoading` and a nullable user-facing error message. Use an enum when stages are truly exclusive, such as the directions flow.
- Do not introduce a general Result type or sealed class hierarchy for every load/save operation.
- Load methods capture errors into screen state and allow retry. User-triggered mutation methods can propagate failures to their widget, which shows the message. Always reset busy state in `finally`.
- Access classes translate technical failures where useful. Widgets should not need to interpret raw socket errors or persistence keys.
- Show dialogs, navigate and manage overlays from explicit callbacks/listeners, not as a side effect of `build`. Guard duplicate presentation and stale async results.

## Acceptance rules

A refactor must preserve visible behavior except for the documented corrections above: consistent restored session, awaited writes, duplicate prevention and reliable ownership. Keep existing Spanish labels and English code/documentation.

Use focused tests for state restoration, persistence sequencing, stale requests, flow transitions and extracted gesture algorithms where they protect behavior. Do not create tests for every trivial widget or constant. Existing QR tests remain valid after import/dependency adaptation. Fake tests do not prove Android camera, GPS or sensor compatibility.

For application changes run from `npi/`:

```bash
fvm flutter analyze
fvm flutter test
```

Report pre-existing diagnostics separately. Do not add analyzer errors or suppressions to conceal regressions. Do not upgrade Flutter/dependencies as part of moves. Do not run APK builds inside Codex; provide device commands for local execution when needed.

The refactor is complete when active code uses this structure, old layers/bridges are removed, one live session is used everywhere, feature ownership is explicit, and manual feature actions work without mobile sensor input. Linux packaging, Leap hardware verification, NPI-PC repository creation and cross-repository sharing are separate follow-up decisions.
