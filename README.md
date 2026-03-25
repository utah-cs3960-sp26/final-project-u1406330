# final-project-u1406330

Gem Factory is a Roblox idle progression game built around the same retention-heavy loop as games like Grow A Garden, but themed around geodes, gems, rare minerals, and crystal cavern growth. This repo contains the Rojo project skeleton, shared config modules, bootstrap entrypoints, server foundation, and a HUD-driven first playable loop.

## Current Structure

```text
tests/
src/
  client/
    Bootstrap/
    Controllers/
    UI/
  server/
    Bootstrap/
    Services/
    Systems/
  shared/
    Config/
    Domain/
    Net/
    Types/
    Util/
```

## How To Work In It

- `src/server/init.server.luau` starts the server bootstrap.
- `src/client/init.client.luau` starts the client bootstrap and creates the HUD.
- Shared config and deterministic math live under `src/shared`.
- Server-owned gameplay services live under `src/server`.
- Client presentation and input controllers live under `src/client`.
- `gem_factory_design.md` is the canonical design document.
- `build_a_zoo_design.md` is retained only as a deprecated migration note.

## Current Slice

- The client requests initial state on startup when the server exposes the remotes.
- The HUD shows currency, passive income, geode queue status, daily reward status, hourly shop info, plot info, and announcements.
- Buttons are wired for starter geode purchase, ready geode claiming, starter station placement, daily reward claiming, and offline reward claiming.
- Placing the starter station uses deterministic first-fit placement when the client does not provide coordinates.
- Claiming geodes now auto-slots newly revealed resources into available placed stations so passive income can start immediately.
- Passive income accrues online and offline, and the world replica shows simple displayed resources on placed stations.
- The map now uses a shared central cavern floor with 8 larger player plots per server, low-profile plot markers, and deterministic rock-spike variations for display flavor.
- If the server endpoints are not yet wired, the client falls back to a local preview state so the UI still loads.

## Notes

- The project is intentionally minimal right now.
- The structure is built for a shared-map crystal cavern layout with grid placement, offline geode progression, and mock persistence first.
- The shared domain modules now contain deterministic economy, rotation, placement, station-assignment, and geode-resolution math.
- Player profile creation, reconciliation, mock loading/saving, plot assignment, and offline summary generation are wired into server startup.
- The current world direction is a single shared cavern map sized for 8 players, with larger plots and lighter environmental boundaries so builds can breathe.
- The client slice is intentionally minimal, but it is now functional enough to complete the first loop in Studio: buy a geode, wait, claim it, place the starter station, and watch passive income begin.

## Verification

- `rojo build default.project.json -o build.rbxlx` succeeds locally.
- Deterministic specs live under `tests/`, including new placement-search and station-assignment coverage.
- A dedicated local automated test runner is not wired in this repo yet, so the specs are currently authored for Studio-side or future runner integration rather than executed from the terminal.

## Current MVP Loop

1. Buy a starter geode from the HUD.
2. Wait for the geode timer to finish.
3. Claim ready geodes from the HUD.
4. Place the starter station on the player plot.
5. Let revealed resources auto-slot into the placed station.
6. Watch passive income begin ticking online.

## Theme Direction

- Players collect and break geodes instead of hatching anything zoo-based.
- Rewards are gems, rare minerals, crystals, and other valuable resources.
- Progress should feel like building a richer, busier gem-processing operation inside a magical cavern.
- The long-term fantasy is moving from a tiny starter setup to a high-value gem empire filled with rare finds and premium production upgrades.

