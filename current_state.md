# Current State

## Summary

Gem Factory is currently at a playable MVP stage. The main early loop works in Studio: buy a geode, place it on your plot, wait for it to finish, click it open, place a starter station, and begin passive income. The project is now centered around an inventory-first geode flow instead of the old auto-placement flow.

## Done

- Shared cavern world with up to 8 player plots is in place.
- Player profiles load through the mock persistence layer and reconcile into the current schema.
- Server bootstrap, client bootstrap, remotes, and state sync are wired.
- Shared deterministic modules exist for economy, placement, geode state, geode rolling, station assignment, shop rotation, and offline math.
- HUD panels exist for shop, geodes, plot, daily rewards, offline rewards, overview, and announcements.
- Starter geode purchase works from the HUD.
- Bought geodes are stored as owned geodes instead of auto-placing immediately.
- Players can enter geode placement mode and place geodes onto their own plot by clicking a grid cell.
- Placed geodes visibly exist on the plot and progress toward ready state.
- Ready geodes can be clicked on the plot to crack open.
- Cracking a geode grants a resource and removes the geode from owned/placed state.
- Revealed resources auto-assign into available placed stations when possible.
- Starter station placement works with deterministic first-fit behavior when coordinates are not provided.
- Passive income works online.
- Offline reward summaries work.
- Offline geode progress now preserves finished geodes as ready to open instead of auto-opening them.
- World replica renders plots, stations, displayed resources, and geodes.
- A lightweight local reveal effect exists for geode cracking: shell split, bounce, and shine.
- README has been updated to reflect the current loop.
- README now includes a more casual Week 13 section covering what works, next-week plans, and Codex usage.
- `rojo build default.project.json -o build-check.rbxlx` succeeds.

## In Progress

- The new geode flow has been implemented, but it still needs more Studio playtesting to shake out interaction edge cases.
- The placement UX works, but it is still minimal and not yet polished with a proper ghost/preview workflow.
- The geode reveal effect is present, but it is still a simple client-side effect rather than a fuller replicated presentation.
- Deterministic specs have been updated/added for the new lifecycle, but the repo still does not have a terminal-integrated automated test runner.
- README now includes a `Proposal` section describing the intended game features and the agentic feedback loop for development quality, plus a more casual Week 13 section.

## Next Up

- Playtest the full geode lifecycle in Studio and capture any edge cases around placement, opening, and reconnect/offline flow.
- Add a better placement preview so geode placement feels clearer before click confirmation.
- Improve geode/world feedback so cracking feels more rewarding and readable.
- Add a proper automated way to execute the specs locally outside Studio.
- Implement move/upgrade flows for placed objects.
- Continue replacing debug-style world visuals with stronger cave/factory presentation.

## Current MVP Loop

1. Buy a starter geode from the HUD.
2. Place the geode onto your plot.
3. Wait for the timer to finish.
4. Click the ready geode on the plot to crack it open.
5. Place the starter station.
6. Let the revealed resource auto-slot into the station.
7. Watch passive income begin.

## Notes

- `gem_factory_design.md` is still the canonical design reference.
- The implemented project slice is intentionally narrower than the full design vision.
- The most important current architectural split is:
  - `src/shared` for deterministic rules and state logic
  - `src/server` for authority and profile mutation
  - `src/client` for HUD, input, and presentation
- There is now an important distinction between stored geodes, placed geodes, and ready-to-open geodes.
- The repo currently has active uncommitted work related to this geode flow update and supporting docs/tests.
