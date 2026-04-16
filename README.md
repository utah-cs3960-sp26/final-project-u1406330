# Gem Factory

Gem Factory is a Roblox idle progression prototype built with Rojo and Luau. The current game loop is about mining for coins and geodes, upgrading permanent pickaxes, using the Vault to place or sell geodes and resources, waiting for placed geodes to finish, cracking them open, and growing a personal cave plot.

The project is intentionally small and testable right now. Server services own the authoritative gameplay state, shared modules hold deterministic rules and config, and client controllers handle HUD, placement input, mining input, and world presentation.

## Start Here

For the fastest context, read these in order:

1. [docs/README.md](docs/README.md) - documentation map and what each doc is for.
2. [docs/current_state.md](docs/current_state.md) - what works now, what is partial, and what should happen next.
3. [docs/gem_factory_design.md](docs/gem_factory_design.md) - current product direction and design principles.
4. [agents.md](agents.md) - collaboration rules for agent-assisted implementation.

Historical planning notes live in [docs/archive](docs/archive). They are useful for understanding where the project came from, but they should not be treated as the source of truth for the current implementation.

## Current MVP Loop

1. Equip a pickaxe from the Roblox backpack.
2. Stand inside the mine and click the mine target to earn coins or geodes.
3. Buy permanent pickaxe upgrades from the pickaxe shop with coins.
4. Open the Vault from the bottom-left HUD and place a geode on your assigned plot.
5. Wait for the geode timer to complete.
6. Click the ready geode in the world to crack it open.
7. Place revealed resources on the plot, keep them in the Vault, or sell them.
8. Place a starter station on the plot.
9. Earn passive income online and collect offline rewards later as station flows continue to mature.

## Repo Layout

```text
src/
  client/   Client bootstrap, controllers, HUD, mining input, placement input, and presentation.
  server/   Server bootstrap, services, persistence, economy, mining, plots, and world replica.
  shared/   Config, deterministic domain modules, remote names, types, and utilities.

tests/      Deterministic Luau specs for shared gameplay rules and server service behavior.
docs/       Current docs plus archived historical planning notes.
```

Important entry points:

- `src/server/init.server.luau` starts the server bootstrap.
- `src/client/init.client.luau` starts the client bootstrap.
- `default.project.json` maps the Rojo project into Roblox services.
- `src/shared/Net/RemoteNames.luau` defines the remote contract names used across client and server.

## Current Systems

- Shared 8-player cavern map with assigned plots.
- Mine on a no-plot side of the world plate.
- Pickaxe shop on the opposite end of the world plate.
- Mock persistence with profile reconciliation.
- Large bottom-left coin counter and Vault button as the primary player-facing HUD.
- Permanent one-time pickaxe purchases, all currently coin-priced.
- Server-owned pickaxe Tools in Roblox `Backpack` and `StarterGear`.
- Server-authoritative mining rewards through `RequestMine`.
- Mining requires the player to stand inside the mine zone.
- Mining rewards grant either coins or owned geode instances stored in the Vault.
- Server-authoritative Vault place/sell actions for geodes and revealed resources.
- Grid placement for geodes, resources, and starter stations.
- Timed geode lifecycle with ready-to-crack world interaction.
- Weighted geode reward rolls and attribute-aware resource instances with independent attribute rarity.
- Bubbly slot-machine style reward popups for uncommon-or-better mining/geode reveal outcomes.
- Three procedural placed-resource visual families with rarity glow and attribute effects.
- Station assignment and passive income systems still exist, but cracked resources now enter the Vault first.
- Online passive income and offline reward summaries.
- Daily rewards, pickaxe shop rotation data, HUD panels, and rare reveal announcements.
- Workspace replica for plots, geodes, placed resources, stations, displayed resources, the mine, and the pickaxe shop.

## Build And Verification

Build the Roblox place file with Rojo:

```powershell
rojo build default.project.json -o build-check.rbxlx
```

The repo contains Luau specs under `tests/`, including coverage for economy math, geode lifecycle, placement rules, station assignment, offline math, shop rotation, mining rewards, mining service behavior, Vault math and service behavior, geode tool cleanup, shop catalog data, and remote names. A terminal-integrated test runner is not wired into this repo yet, so the specs are currently intended for Studio-side execution or a future runner setup.

## Working Notes

- Treat [docs/current_state.md](docs/current_state.md) as the live implementation summary.
- Treat [docs/gem_factory_design.md](docs/gem_factory_design.md) as the current product direction, not a promise that every listed future system exists.
- Keep deterministic gameplay logic in `src/shared/Domain` whenever possible.
- Keep server mutation authoritative; the client should request actions and render state.
- After gameplay changes, update docs that describe the affected loop or system.
