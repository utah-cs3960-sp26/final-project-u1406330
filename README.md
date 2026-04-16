# Gem Factory

Gem Factory is a Roblox idle progression prototype built with Rojo and Luau. The current game loop is about buying geodes, placing them on a player plot, waiting for them to finish, cracking them open, feeding the revealed resources into stations, and earning passive income.

The project is intentionally small and testable right now. Server services own the authoritative gameplay state, shared modules hold deterministic rules and config, and client controllers handle HUD, placement input, and world presentation.

## Start Here

For the fastest context, read these in order:

1. [docs/README.md](docs/README.md) - documentation map and what each doc is for.
2. [docs/current_state.md](docs/current_state.md) - what works now, what is partial, and what should happen next.
3. [docs/gem_factory_design.md](docs/gem_factory_design.md) - current product direction and design principles.
4. [docs/agents.md](docs/agents.md) - collaboration rules for agent-assisted implementation.

Historical planning notes live in [docs/archive](docs/archive). They are useful for understanding where the project came from, but they should not be treated as the source of truth for the current implementation.

## Current MVP Loop

1. Buy a starter geode from the HUD.
2. Place the geode onto your assigned plot.
3. Wait for the geode timer to complete.
4. Click the ready geode in the world to crack it open.
5. Place a starter station on the plot.
6. Let revealed resources auto-slot into available station capacity.
7. Earn passive income online and collect offline rewards later.

## Repo Layout

```text
src/
  client/   Client bootstrap, controllers, HUD, placement input, and presentation.
  server/   Server bootstrap, services, persistence, economy, plots, and world replica.
  shared/   Config, deterministic domain modules, remote names, types, and utilities.

tests/      Deterministic Luau specs for shared gameplay rules.
docs/       Current docs plus archived historical planning notes.
```

Important entry points:

- `src/server/init.server.luau` starts the server bootstrap.
- `src/client/init.client.luau` starts the client bootstrap.
- `default.project.json` maps the Rojo project into Roblox services.
- `src/shared/Net/RemoteNames.luau` defines the remote contract names used across client and server.

## Current Systems

- Shared 8-player cavern map with assigned plots.
- Mock persistence with profile reconciliation.
- Geode shop purchasing and owned geode inventory.
- Grid placement for geodes and starter stations.
- Timed geode lifecycle with ready-to-crack world interaction.
- Weighted geode reward rolls and trait-aware resource instances.
- Station assignment for revealed resources.
- Online passive income and offline reward summaries.
- Daily rewards, hourly shop rotation, HUD panels, and rare reveal announcements.
- Workspace replica for plots, geodes, stations, and displayed resources.

## Build And Verification

Build the Roblox place file with Rojo:

```powershell
rojo build default.project.json -o build-check.rbxlx
```

The repo contains Luau specs under `tests/`, including coverage for economy math, geode lifecycle, placement rules, station assignment, offline math, shop rotation, and remote names. A terminal-integrated test runner is not wired into this repo yet, so the specs are currently intended for Studio-side execution or a future runner setup.

## Working Notes

- Treat [docs/current_state.md](docs/current_state.md) as the live implementation summary.
- Treat [docs/gem_factory_design.md](docs/gem_factory_design.md) as the current product direction, not a promise that every listed future system exists.
- Keep deterministic gameplay logic in `src/shared/Domain` whenever possible.
- Keep server mutation authoritative; the client should request actions and render state.
- After gameplay changes, update docs that describe the affected loop or system.
