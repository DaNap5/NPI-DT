# Refactor work packages

Prepared on 2026-11-20 against branch `refactor-pre-PC`. No Jira issue or person has been assigned. These work packages record the agreed migration scope. The [architecture guide](ARCHITECTURE.md) defines the destination and contracts.

## Implementation status

R0–R6 have been implemented on `refactor-pre-PC` in the current working tree. No commit, ticket or NPI-PC repository was created. The package descriptions below retain the original scope and acceptance criteria for review.

The old global `ui`, `data` and `domain` trees and forwarding repository/service chains are removed. Screens use explicitly injected shared LocalStore/EventCatalog/SessionState instances. Input recognition is isolated from feature decisions. The discarded list owns a separate EventsViewModel instance configured with `discardedOnly`, avoiding a duplicate class. Existing preference keys and bundled content are retained; unused account/password code and bcrypt are removed.

Automated validation covers storage/session failures and concurrency, startup/auth, catalogue caching and mutations, stale requests, directions and motion algorithms, and manual event discovery/recovery/reset without sensors. Final checks on 2026-11-20: `fvm flutter analyze` reports no issues; `fvm flutter test` passes all 24 tests. Formatting and obsolete-reference/whitespace checks pass. Android camera, permissions, GPS accuracy/fallback, calibration, gestures and background/resume remain unverified. Run `fvm flutter run -d <android-device-id>` locally for these checks; no APK build was run in Codex.

## Sequence and assignment

| Package | Owner role | Depends on | Can overlap |
|---|---|---|---|
| R0: feature path baseline | Integrator | Shared reviewed baseline | None |
| R1: shared data/session contracts | Foundation owner | R0 | None initially |
| R2: startup, auth and Home | Auth/Home owner | R1 | R3 and R4 with integration coordination |
| R3: events state and persistence | Events owner | R1 | R2 and R4 |
| R4: orientation data and directions | Orientation owner | R1 | R2 and R3 |
| R5: extract mobile movement input | Input owner | R3 and R4 | Only unrelated documentation; touches events and map files |
| R6: final integration and removal | Integrator | R2, R3, R4, R5 | None |

With three people, one can take R0/R1/R2/R6, another R3, and another R4/R5. With fewer people, execute the same packages sequentially. Names are intentionally unassigned. R1 and R3 share an API contract for saved/discarded operations; freeze it before parallel work.

## R0 — Establish feature paths without changing behavior

Scope: current `lib/ui/` feature directories and their imports, tests and documentation. Do not combine semantic rewrites with this move.

- Move `ui/auth`, `ui/home`, `ui/events`, `ui/orientation`, `ui/qr`, `ui/miscellaneous` to the corresponding direct `lib/` folders.
- Update every Dart consumer and test import. Keep internal `widgets`/`view_models` folders temporarily so the move is reviewable; the module packages flatten their own files afterward.
- Leave existing `data` and `domain` implementations until their owners migrate their responsibilities. Do not invent replacement wrappers or change algorithms in this package.
- Update the guides' source-path references or record completion so subsequent assignments refer to the moved paths.

Acceptance: no `package:npi/ui/` imports, no missing local imports, unchanged feature behavior, existing tests pass, no new analyzer errors. Record diagnostics against the baseline.

## R1 — Implement shared data and session contracts

Scope: `storage/local_store.dart`, `auth/session_state.dart`, `events/event.dart`, `events/event_catalog.dart`, plus focused tests. The integrator owns any temporary forwarding imports needed by unmigrated consumers.

- Implement the concrete APIs in ARCHITECTURE.md. `LocalStore` receives initialized preferences; `SessionState` receives the store; `EventCatalog` loads the CSV once and shares in-flight loading.
- Move the existing Event/EventCategory model to `events/event.dart`; preserve CSV interpretation, IDs, dates, URLs, categories and labels. Old imports may temporarily re-export this model until consumers migrate.
- Preserve existing preference keys/JSON schemas, guest discarded namespace and existing category preferences. Distinguish persisted data from observable session state.
- Await and serialize collection mutations. Save/discard are idempotent and mutually exclusive for one ID; explicit Home removal is not a discard.
- Session writes update shared in-memory identity only after success. Restore before displaying session-dependent features; make overlapping session changes impossible.
- Keep legacy UserRepository code temporarily for consumers assigned to R2/R3. Do not maintain two live session authorities after root integration.

Acceptance: tests cover existing stored data, restoration, guest/signed-in/logout transitions, saving/discarding/reset sequencing and preservation of the other user's events. Verify failed writes do not report session success and failed catalogue loads can retry. No production authentication or new database.

Handoff: provide exact constructors/method signatures and fixtures showing preference compatibility. R2/R3 must consume these APIs rather than making their own stores/session objects.

## R2 — Migrate startup, auth and Home to one session

Scope: `main.dart`, new `app.dart`, `auth/`, `home/`, QR test integration. Root/import edits are coordinated with the integrator.

- Construct one initialized LocalStore, EventCatalog and SessionState at the root and pass them to screens/viewmodels. Restore session and read onboarding state before choosing the initial screen; make startup failure visible with retry.
- Convert sign-in/login to SessionState actions. Keep form validation and mock QR/email identity behavior. Guest choice and logout must clear the previous live identity consistently.
- Move auth screens/viewmodels to their feature root. Keep only viewmodels that manage meaningful state/async actions; language selection may remain a simple stateful screen with its tile private.
- Rename ScheduleScreen/Controller to HomeScreen/ViewModel. Move the active ScheduleItem model and sample class/guest-event lists into their own Home files.
- Home uses shared session identity, not a separately supplied `initialUsername` or its own username truth. Preserve up to four saved catalogue events, day selection, removal confirmation and entrance directions.
- Screen-owned viewmodels dispose their session listeners. Root does not create an unused Home viewmodel during onboarding.
- Preserve QR as the reusable String?-returning camera screen; relocate it from its transitional widgets folder to `qr/qr_scanner_screen.dart` without reintroducing service/repository/model layers.

Acceptance: first launch language -> access -> Home; signed-in cold restart is consistent in Home/events; guest restart stays guest; logout does not erase saved events. Cancelled/blank QR does not create a session. Existing tests are adapted, and restoration/ownership behavior gets focused coverage.

Do not redesign auth labels or enable the currently unsupported languages. Coordinate events-screen constructor changes with R3; the integrator resolves the final Home entry call.

## R3 — Give the event catalogue one state owner

Scope: `events/`, its tests and feature-owned input call sites, but not extraction of sensor algorithms yet.

- EventsScreen creates one concrete EventsViewModel. Discovery controls and card widgets borrow that instance. Remove the duplicate parent/child discovery viewmodels and UniqueKey refresh reconstruction.
- DiscardedEventsScreen owns a separate viewmodel for its own list. Replace the old abstract EventsViewModel contract with plain widget data/callback arguments; coordinate renaming to avoid two declarations with the same name.
- Use the shared EventCatalog, SessionState and LocalStore. Eliminate independent session reads and hidden singleton construction.
- Await save/discard/reset/recovery before updating visible data; expose busy/error state and prevent repeated commits while a write is pending. Make reset completion explicit.
- Preserve preferred-category ordering, time filters, signed-in bookmark behavior and guest restrictions. Share category parsing/sorting in feature-local functions where it removes actual duplication.
- Refresh discovery on return from recovery. Provide Home an ordinary return point for refresh; no new global event bus.
- Simplify bookmark/list APIs so model/state declarations do not require a viewmodel to import widget implementation files. Keep visual states only where they represent behavior actually shown.
- Keep touch animation/drag logic in presentation. Leave mobile tilt behavior intact until R5; expose `saveCurrentEvent()` / `discardCurrentEvent()` for that later adapter and make async completion/error handling explicit.

Acceptance: single catalogue load/state owner, save/discard/recovery/reset and failure/retry tests, correct guest behavior, session-change stale results ignored. Returning to Home refreshes saved events. Existing removed detail/sharing/MyEvents flows stay removed.

## R4 — Simplify orientation data and directions

Scope: `orientation/`, current location repository/service and feature tests. Coordinate Home's location-type import/constructor update with R2 through the integrator.

- Rename InsideView to FacultyMapScreen and InsideViewModel to FacultyMapViewModel; put screens/viewmodels at the feature root. Preserve selection and exploration modes and existing map geometry.
- Move floor names/assets/zones into `data/floors.dart`, preserving indices (basement 0, ground 1, second floor 3). Move indoor/outdoor waypoint constants into `data/routes.dart`.
- Remove SensorSnapshot and its unused values, unused Waypoint floor/manual-validation fields/getter and obsolete qrOrigin stage/chooseQrOrigin method. Confirm references again before removal.
- Keep MapZone and Waypoint in the feature; preserve colors, offsets, icons, GPS coordinates/radii and images that the UI uses. No pure-domain duplicate models.
- Consolidate location access/decisions in concrete LocationClient with public feature results. Take coordinates/radius rather than requiring a global repository to import a UI Waypoint. Keep real permission, accuracy, timeout and fallback behavior.
- Let the directions viewmodel expose whether GPS tracking applies; remove the copy of that route condition from the widget.
- Trigger arrival dialogs/location overlays from a listener, not build. Preserve stale-request guards, one prompt per waypoint, manual navigation and cleanup.
- Fold trivial NavigationControls into WaypointGuide if it has no other consumer. Keep substantive map painting, zone panel, guide and animated warning components.
- Leave recognition/calibration inside the renamed map viewmodel only until R5. Do not tune or remove mobile gesture behavior in this package.

Acceptance: floor display/polygon selection unchanged; classroom origin confirmation and any-QR mock origin work; indoor/outdoor/combined route order preserved; combined entrance appears once; back navigation and stale location results are safe; GPS failure keeps manual controls usable. Focus tests on flow logic, not coordinates that merely repeat constants.

## R5 — Extract mobile input while preserving recognition

Scope: `input/`, former mobile sensor repositories/services, former motion use cases/models, map/events viewmodels, their owners and tutorial widgets. This package deliberately follows R3/R4 to avoid concurrent edits to the same files.

- Extract FloorMotionInput and EventTiltInput using the callbacks/lifecycle contract in ARCHITECTURE.md. Construction does not start listening.
- Move sensor sampling, calibration, recognition thresholds, cooldowns and timers out of feature viewmodels. Preserve numerical behavior before changing algorithms.
- Keep map floor bounds and selected-floor state in FacultyMapViewModel. Keep event list mutations and touch/animation state in the events feature. Normalized gesture progress is input data; card offsets/rotation belong to presentation.
- Rewire tutorials to the appropriate input's calibration/feedback state. A map opened with manual input must not require phone calibration.
- Remove obsolete gyro/accelerometer/tilt interface -> implementation -> service forwarding chains once consumers are rewired. Move/rename useful algorithms instead of deleting them because they were called use cases.
- Handle unsupported/erroring sensors explicitly. Stop input while inactive or disposed; no delayed gesture callbacks after leaving a screen.
- Wire callback invocations to futures safely so an async save/discard error is handled and no new gesture is committed during a pending mutation.

Acceptance: manual actions work with no sensors; focused algorithm tests preserve existing gesture sequences/threshold behavior and cover stop/dispose; Android checks exercise calibration, gestures, tutorial and background/resume. No Leap implementation, SDK upgrade, input bus or universal interface.

## R6 — Integrate and remove the transitional architecture

Scope: root integration, leftover old paths/bridges, `miscellaneous/`, manifests, README, guides and final validation.

- Integrate the agreed screen constructors. Check that routes share one root session/catalogue/store and each screen disposes only resources it owns.
- Move ServiceOption and service_options catalogue into miscellaneous; flatten its screen files where useful. Preserve its current links/content.
- Move remaining swipe/tutorial presentation helpers into events and useful sensor helpers into input. Remove the old domain README rather than retaining contradictory guidance.
- Remove all temporary bridges and old `ui`, `data`, `domain` directories once no active consumer remains. Check declarations as well as import reachability; do not remove active features solely because a file has an unusual name.
- Remove unused registration/password-checking code only after legacy preference reading is available. Remove bcrypt if no remaining code requires it; regenerate the lockfile/plugin registration with FVM. Do not upgrade unrelated dependencies.
- Check no singleton UserRepository, private preference-key literals outside LocalStore, duplicate discovery state, mobile recognition in feature viewmodels or obsolete old imports remain.
- Update the README map to the implemented structure and mark package status in this plan based on actual work. Durable decisions stay in ARCHITECTURE.md; Jira status belongs in Jira when tasks are explicitly created.

Acceptance: all applicable tests pass, no analyzer errors/regressions, obsolete-reference and local-link checks pass, and the integrator records a manual Android smoke-check result or clearly lists it as unverified. No APK builds inside Codex.

## Validation and task handoff template

For each implementation package run from `npi/`:

```bash
fvm flutter analyze
fvm flutter test
```

Add meaningful focused tests for changed decisions, async ordering and resource cleanup. The existing four QR tests are a minimum baseline, not complete feature coverage. Manual checks use `fvm flutter run -d <android-device-id>` locally; camera, location and sensor compatibility cannot be established by fake tests. Documentation-only work uses link and diff checks.

Copy this instruction when assigning a package:

> Read ARCHITECTURE.md and package Rn in REFACTOR_PLAN.md. Implement only that package against the agreed baseline. Preserve existing user changes and Spanish UI, follow the public contracts, and coordinate files owned by another package with the integrator. Do not introduce new layers or unrelated upgrades. Record moved/deleted files, any temporary bridge and its removal owner, behavior corrections, actual check results and native behavior still unverified. Update NEXT.md when finishing.

## Deferred work and remaining decisions

- Person assignments and Jira keys remain unassigned; no tickets were created by writing this plan.
- The Linux distribution/driver compatibility and legacy Leap WebSocket connection still need a separate hardware probe.
- Create/configure NPI-PC only after this migration and the probe are reviewed. Do not create its repository or placeholder integration as part of R0-R6.
- Decide cross-repository code sharing and kiosk UI/gestures with actual PC requirements; do not pre-extract a package framework during the Android refactor.
