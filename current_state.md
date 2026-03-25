# Current State

## Project Snapshot

Gem Factory is currently a playable Roblox MVP built around a shared cavern map, owned geodes, manual plot placement, timed cracking, and passive income from placed stations. The project is structured as deterministic shared gameplay/domain modules plus thin server services and client controllers.

The canonical design direction is still `gem_factory_design.md`, but the implemented game slice is intentionally smaller and focused on proving the main early loop.

## What Works Right Now

- Players load into a shared cavern map with up to 8 plots.
- Player profiles are created/reconciled through the mock persistence layer.
- The client requests initial state from the server and updates from server remotes.
- The HUD shows shop, currencies, plot info, geode info, daily rewards, offline rewards, and announcements.
- Players can buy a starter geode from the HUD.
- Bought geodes are now stored as owned inventory geodes instead of auto-placing immediately.
- Players can place a geode onto their own plot by entering placement mode and clicking a grid cell.
- Placed geodes continue their timer and become ready on the plot.
- Ready geodes can be clicked in-world to crack open.
- Opening a geode grants a rolled resource and removes the geode from owned state and plot occupancy.
- Newly revealed resources auto-assign into available placed stations when possible.
- The starter station can be placed with deterministic first-fit placement when no coordinates are provided.
- Passive income runs online and offline.
- Offline progress now preserves finished geodes as ready-to-open instead of auto-opening them.
- The world replica renders plots, placed stations, displayed resources, and placed geodes.
- Ready geode opening now plays a local client-side crack/reveal effect with shell split, bounce, and shine.

## Current Core Loop

1. Buy a starter geode.
2. Place it on your plot.
3. Wait for the timer to finish.
4. Click the ready geode on the plot to crack it open.
5. Place the starter station.
6. Let the revealed resource auto-slot into the station.
7. Watch passive income begin.

## Recent Changes

- Reworked geodes from an auto-placed flow to an inventory-first flow.
- Added explicit server remotes for geode placement and cracking.
- Added client geode interaction handling for plot-click placement and in-world cracking.
- Added shared owned-geode lifecycle state via `geodesById` and `geodeOrder`.
- Updated offline reward behavior so completed timers do not silently convert into resources.
- Updated docs/specs to reflect the new geode lifecycle.

## Important Implementation Notes

- `src/shared` contains the deterministic math and lifecycle logic that should remain the source of truth for rules.
- `src/server` owns validation, profile mutation, placement, economy, and world replication.
- `src/client` is still intentionally lightweight and mostly HUD/input driven.
- There is now a meaningful distinction between:
  - stored geodes in inventory
  - owned geodes placed on the plot
  - finished geodes ready to open
- The visual cracking/reveal animation is client-side polish layered on top of server-authoritative open results.

## Verification State

- `rojo build default.project.json -o build-check.rbxlx` succeeds locally.
- Deterministic specs exist under `tests/`.
- A proper local automated test runner is still not wired into the repo, so specs are authored but not being executed from the terminal yet.

## Known Gaps / Next Follow-Through

- Geode placement is currently click-to-cell placement, but it is still a minimal UX and does not yet include a richer placement preview/ghost.
- The reveal animation is local-only polish and not yet a fully replicated cinematic sequence.
- The world replica is still simple geometry and debug-friendly visuals rather than final art direction.
- There is still no terminal-integrated automated spec runner.
- Movement/upgrading of placed objects remains unimplemented.
- The repo currently has active uncommitted changes related to this geode flow update and supporting docs/tests.
