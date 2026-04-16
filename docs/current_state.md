# Current State

## Summary

Gem Factory is at a mine-first MVP stage in Roblox Studio. The current early loop is mine-first: players equip a pickaxe, click inside the mine to earn either coins or geodes, place owned geodes on their plot, wait for them to finish, crack ready geodes in the world, place stations, and earn passive income from revealed resources.

The project is still a prototype. The backend gameplay slice is more complete than the presentation layer, and persistence is still mocked for development.

## What Works

- Rojo project mapping is defined in `default.project.json`.
- Server and client bootstraps are wired through `src/server/init.server.luau` and `src/client/init.client.luau`.
- Shared cavern world supports up to 8 assigned player plots.
- Player profiles load through `MockPersistenceService` and reconcile into the current profile schema.
- Remote names and remote setup are centralized under `src/shared/Net`.
- Shared config exists for resources, geodes, traits, stations, economy, shops, pickaxes, daily rewards, and world settings.
- The shared pickaxe catalog defines ten pickaxe tiers, each with coin payouts, geode chance, and weighted geode tables.
- Deterministic shared domain modules exist for economy, placement, geode state, geode rolling, mining rewards, station assignment, shop rotation, trait rolling, and offline math.
- HUD panels cover geodes, plot state, daily rewards, offline rewards, overview, and announcements.
- A mine exists on the west no-plot side of the shared world plate.
- The mine sign is attached to the mine face so it reads as part of the mine facade.
- A roofless pickaxe shop exists on the east no-plot side of the shared world plate and sells pickaxes only.
- The pickaxe shop menu displays the full permanent pickaxe catalog with owned, equip, and buy states.
- Players start with a Stone Pickaxe.
- Owned pickaxes mirror into server-owned Roblox `Tool` instances in `Backpack` and `StarterGear`.
- Mining is server-authoritative through `RequestMine`; the server requires the player to be standing inside the mine zone before valid mining rolls grant either coins or an owned geode instance.
- Pickaxes are permanent one-time purchases and all current pickaxes cost coins.
- Pickaxe tools now include a centered held pickaxe model with a wooden handle and connected catalog-tinted metal head, matching the shop display style.
- Equipped pickaxes play a short local swing animation when the player clicks with one held.
- Unplaced geodes mirror into server-owned Roblox `Tool` instances in `Backpack`, with one tool per geode instance.
- Players can equip a geode tool, see a transparent placement ghost, and place geodes onto their own plot grid.
- Placed geodes render in the world and progress toward ready state.
- Ready geodes can be clicked in the world to crack open.
- Cracking a geode grants a resource and removes the geode from placed state.
- Revealed resources auto-assign into available placed stations when possible.
- Starter station placement works, including deterministic first-fit placement when coordinates are not provided.
- Passive income accrues online.
- Offline reward summaries work.
- Offline geode progress preserves finished geodes as ready to open instead of auto-opening them.
- World replica renders plots, stations, displayed resources, geodes, the mine, and the pickaxe shop.
- A lightweight local geode reveal effect exists.
- Daily rewards, pickaxe shop rotation data, and rare reveal announcements are represented in the current slice.
- `rojo build default.project.json -o build-check.rbxlx` has succeeded locally.

## Current MVP Loop

1. Equip a pickaxe from the Roblox backpack.
2. Click inside the mine to earn coins or geodes.
3. Upgrade pickaxes at the pickaxe shop to improve coin payouts and rare geode odds.
4. Equip a geode tool and place it onto your plot.
5. Wait for the timer to finish.
6. Click the ready geode on the plot to crack it open.
7. Place the starter station.
8. Let the revealed resource auto-slot into the station.
9. Watch passive income begin.

## Implemented Content

- Geodes: Starter Geode, Crystal Cavern Geode, Moonlit Geode, Ember Glass Geode, Verdant Rift Geode, Aurora Shard Geode, Thunder Core Geode, Fossil Vault Geode, Prism Sun Geode, Sovereign Nova Geode.
- Pickaxes: Stone Pickaxe, Copper Pickaxe, Iron Pickaxe, Steel Pickaxe, Gold Pickaxe, Platinum Pickaxe, Emerald Pickaxe, Obsidian Pickaxe, Lunar Pickaxe, Crown Pickaxe.
- Resources: Quartz, Amethyst, Emerald Cluster, Diamond Core, Star Shard.
- Stations: Crystal Display, Resonance Pedestal.
- Core progression: coins, mining, pickaxe buying, geode placement, cracking, station assignment, passive income, offline rewards.

## In Progress

- More Studio playtesting is needed for mining, pickaxe purchases, placement, cracking, reconnect, and offline edge cases.
- Mining click feedback now includes bold center-screen action popups for rewards and important mining prompts.
- Placement UX uses a geode ghost preview, but item art and interaction polish still need playtesting.
- The reveal effect is client-side and lightweight, not a fuller replicated presentation.
- Specs exist under `tests/`, but a terminal-integrated automated Luau test runner is not wired in yet.
- World visuals are readable for debugging but still need stronger cave/factory art direction.
- Move and upgrade flows are present in the remote plan but not fully built out as complete player-facing systems.

## Next Up

- Playtest the full mine-to-geode-to-income lifecycle in Studio and record reproducible edge cases.
- Playtest pickaxe Tool sync and held model alignment across respawn.
- Playtest mine standing-zone validation, mine target hit detection, and reward messages.
- Continue tuning mining feedback timing and presentation after Studio playtests.
- Improve geode cracking feedback so reveals feel more rewarding and readable.
- Add or document a repeatable local way to execute the Luau specs outside manual Studio checks.
- Implement player-facing move and upgrade flows for placed objects.
- Continue replacing debug-style world visuals with richer cave and factory presentation.

## Architecture Notes

- `src/shared` holds deterministic rules, configs, types, remote names, and utility modules.
- `src/server` owns profile mutation, mining rolls, pickaxe purchases, economy, placement validation, plot assignment, offline progress, and world replication.
- `src/client` owns HUD construction, input controllers, local presentation, and action requests.
- Workspace objects are a projection of authoritative state, not the source of truth.
- Mining rewards are rolled on the server; the client only requests mining after a local mine-target click.
- The important geode state distinction is owned, placed, ready, and cracked/opened.

## Verification Notes

- Run `rojo build default.project.json -o build-check.rbxlx` after structural changes.
- Useful specs currently live in `tests/`.
- The repo does not yet have a terminal test command, so new deterministic logic should either add specs for future runner use or be accompanied by a small reproducible validation path.
