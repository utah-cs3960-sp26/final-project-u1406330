# Gem Factory

Gem Factory is a Roblox idle progression prototype built with Rojo and Luau. The current game loop is about mining for coins and geodes, upgrading permanent pickaxes, using the Vault to place or sell geodes and resources, waiting for placed geodes to finish, cracking them open, and growing a personal cave plot.

The project is intentionally small and testable right now. Server services own the authoritative gameplay state, shared modules hold deterministic rules and config, and client controllers handle HUD, placement input, mining input, and world presentation. The source tree is also being kept agent-friendly: non-trivial modules should carry brief purpose comments so future contributors can trace intent quickly.

## Week 14

The final version of Gem Factory is still very similar to the original proposal in terms of the main idea. It is still a Roblox idle/progression game focused on geodes, rare rewards, and building up your own area over time. The overall design and theme stayed mostly the same, but a lot of the smaller gameplay details changed during development.

Compared to what I proposed a couple weeks earlier, I ended up reworking a lot of the gameplay mechanics and refining the gameplay loop quite a bit. My original proposal was more of a rough plan than a detailed feature list, so as I actually built the game I had to figure out what worked, what did not work, and what would make the game more fun and interesting. I also changed the models, improved the presentation, and tried to polish the game as much as I could within the time I had.

So overall, I would say the final product matches the original proposal in its core concept, but not in every exact mechanic. The game ended up being a more developed and polished version of the same idea, with changes made throughout development to make the gameplay better and more interesting.

https://www.youtube.com/watch?v=2LFV2AdMyIo

Above is the video link.

You can play the game here, 

https://www.roblox.com/games/71249680786295/Gem-Factory

## Start Here

For the fastest context, read these in order:

1. [docs/README.md](docs/README.md) - documentation map and what each doc is for.
2. [docs/current_state.md](docs/current_state.md) - what works now, what is partial, and what should happen next.
3. [docs/gem_factory_design.md](docs/gem_factory_design.md) - current product direction and design principles.
4. [agents.md](agents.md) - collaboration rules for agent-assisted implementation, including the repo's code-commenting expectations.

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
            Controllers/ has AppController, mining, placement, geode interaction, vault, shop,
            HUD, sprint, notifications, and daily rewards controllers.
            UI/ has Components/, Screens/, and Theme/ for panel layout and palette.
  server/   Server bootstrap, services, persistence, economy, mining, plots, and world replica.
            Services/ includes 16 service modules covering player data, economy, mining, geodes,
            geode queue, vault, placement, stations, pickaxe tools, shop, daily rewards, and offline.
            Systems/ has RareAnnouncementSystem. Util/ has PickaxeModelBuilder.
  shared/   Config, deterministic domain modules, remote names, types, and utilities.
            Config/ covers resources, geodes, pickaxes, traits, sizes, stations, economy, shops,
            daily rewards, and world settings. Domain/ has 15 deterministic gameplay/presentation modules.

tests/      22 Luau spec files for deterministic gameplay rules and server service behavior.
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
- Mock persistence with profile reconciliation (schema version 2; players start with 250 coins and 10 gems).
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
- Numeric size values assigned to geodes when mined, resolved into Tiny/Small/Medium/Large/Huge/Colossal categories, carried over to resources on cracking, affecting visual scale and sell value.
- Vault rows display size information for geodes and resources, and placement ghosts/world replicas use the resolved size for physical scale.
- Rarity-scaled mining discovery popups plus staged geode cracking/resource reveal presentation with hidden-until-resolved resource and attribute labels.
- Live countdown labels above cracking geodes until they become ready to open.
- Procedural placed-resource visuals across gemstone, cluster, artifact, ingot, and eldritch families, with rarity glow, attribute effects, and rolled size scaling.
- Station assignment and passive income systems still exist, but cracked resources now enter the Vault first.
- Online passive income and offline reward summaries.
- Daily rewards, pickaxe shop rotation data, HUD panels, and rare reveal announcements.
- Workspace replica for plots, geodes, placed resources, stations, displayed resources, the mine, and the pickaxe shop. `GeodeQueueService` manages server-side geode queue lifecycle (distinct from `GeodeService`).

## Build And Verification

Build the Roblox place file with Rojo:

```powershell
rojo build default.project.json -o build-check.rbxlx
```

The repo contains 22 Luau spec files under `tests/`: EconomyMath, GeodeLifecycle, GeodePresentation, GeodeRoller, GeodeState, GeodeToolService, MiningRewards, MiningService, OfflineMath, PlacementRules, RemoteNames, Resources, ResourceVisuals, RewardPresentation, ShopCatalog, ShopRotation, SizeRoller, SizeRules, StationAssignment, VaultMath, VaultService, and WorldLabelPresentation. A terminal-integrated test runner is not wired into this repo yet, so the specs are currently intended for Studio-side execution or a future runner setup.

## Working Notes

- Treat [docs/current_state.md](docs/current_state.md) as the live implementation summary.
- Treat [docs/gem_factory_design.md](docs/gem_factory_design.md) as the current product direction, not a promise that every listed future system exists.
- Keep deterministic gameplay logic in `src/shared/Domain` whenever possible.
- Keep server mutation authoritative; the client should request actions and render state.
- Keep module comments and tricky-flow comments current so the codebase stays legible to future agents.
- After gameplay changes, update docs that describe the affected loop or system.
