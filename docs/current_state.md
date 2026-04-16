# Current State

## Summary

Gem Factory is at a playable MVP stage in Roblox Studio. The current early loop is inventory-first: players buy geodes, place owned geodes on their plot, wait for them to finish, crack ready geodes in the world, place stations, and earn passive income from revealed resources.

The project is still a prototype. The backend gameplay slice is more complete than the presentation layer, and persistence is still mocked for development.

## What Works

- Rojo project mapping is defined in `default.project.json`.
- Server and client bootstraps are wired through `src/server/init.server.luau` and `src/client/init.client.luau`.
- Shared cavern world supports up to 8 assigned player plots.
- Player profiles load through `MockPersistenceService` and reconcile into the current profile schema.
- Remote names and remote setup are centralized under `src/shared/Net`.
- Shared config exists for resources, geodes, traits, stations, economy, shops, daily rewards, and world settings.
- Deterministic shared domain modules exist for economy, placement, geode state, geode rolling, station assignment, shop rotation, trait rolling, and offline math.
- HUD panels cover shop, geodes, plot state, daily rewards, offline rewards, overview, and announcements.
- Starter geode purchase works from the HUD.
- Bought geodes are stored as owned geodes instead of being auto-placed.
- Players can enter geode placement mode and place geodes onto their own plot grid.
- Placed geodes render in the world and progress toward ready state.
- Ready geodes can be clicked in the world to crack open.
- Cracking a geode grants a resource and removes the geode from placed state.
- Revealed resources auto-assign into available placed stations when possible.
- Starter station placement works, including deterministic first-fit placement when coordinates are not provided.
- Passive income accrues online.
- Offline reward summaries work.
- Offline geode progress preserves finished geodes as ready to open instead of auto-opening them.
- World replica renders plots, stations, displayed resources, and geodes.
- A lightweight local geode reveal effect exists.
- Daily rewards, hourly shop rotation, and rare reveal announcements are represented in the current slice.
- `rojo build default.project.json -o build-check.rbxlx` has succeeded locally.

## Current MVP Loop

1. Buy a starter geode from the HUD.
2. Place the geode onto your plot.
3. Wait for the timer to finish.
4. Click the ready geode on the plot to crack it open.
5. Place the starter station.
6. Let the revealed resource auto-slot into the station.
7. Watch passive income begin.

## Implemented Content

- Geodes: Starter Geode, Crystal Cavern Geode, Moonlit Geode.
- Resources: Quartz, Amethyst, Emerald Cluster, Diamond Core, Star Shard.
- Stations: Crystal Display, Resonance Pedestal.
- Core progression: coins, geode buying, placement, cracking, station assignment, passive income, offline rewards.

## In Progress

- More Studio playtesting is needed for placement, cracking, reconnect, and offline edge cases.
- Placement UX is functional but minimal; it still needs a clearer ghost or preview workflow.
- The reveal effect is client-side and lightweight, not a fuller replicated presentation.
- Specs exist under `tests/`, but a terminal-integrated automated Luau test runner is not wired in yet.
- World visuals are readable for debugging but still need stronger cave/factory art direction.
- Move and upgrade flows are present in the remote plan but not fully built out as complete player-facing systems.

## Next Up

- Playtest the full geode lifecycle in Studio and record reproducible edge cases.
- Add a better placement preview before click confirmation.
- Improve geode cracking feedback so reveals feel more rewarding and readable.
- Add or document a repeatable local way to execute the Luau specs outside manual Studio checks.
- Implement player-facing move and upgrade flows for placed objects.
- Continue replacing debug-style world visuals with richer cave and factory presentation.

## Architecture Notes

- `src/shared` holds deterministic rules, configs, types, remote names, and utility modules.
- `src/server` owns profile mutation, economy, purchases, placement validation, plot assignment, offline progress, and world replication.
- `src/client` owns HUD construction, input controllers, local presentation, and action requests.
- Workspace objects are a projection of authoritative state, not the source of truth.
- The important geode state distinction is owned, placed, ready, and cracked/opened.

## Verification Notes

- Run `rojo build default.project.json -o build-check.rbxlx` after structural changes.
- Useful specs currently live in `tests/`.
- The repo does not yet have a terminal test command, so new deterministic logic should either add specs for future runner use or be accompanied by a small reproducible validation path.
