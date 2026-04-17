# Current State

## Summary

Gem Factory is at a mine-first MVP stage in Roblox Studio. The current early loop is mine-first: players equip a pickaxe, click inside the mine to earn either coins or geodes, open the Vault to place or sell owned geodes, wait for placed geodes to finish, crack ready geodes in the world, store revealed resources in the Vault, and either place or sell those resources.

The project is still a prototype. The backend gameplay slice is more complete than the presentation layer, and persistence is still mocked for development.

## What Works

- Rojo project mapping is defined in `default.project.json`.
- Server and client bootstraps are wired through `src/server/init.server.luau` and `src/client/init.client.luau`.
- Shared cavern world supports up to 8 assigned player plots.
- Player profiles load through `MockPersistenceService` and reconcile into the current profile schema (schema version 2). New players start with 250 coins and 10 gems.
- Remote names and remote setup are centralized under `src/shared/Net`.
- Shared config exists for resources, geodes, traits, stations, economy, shops, pickaxes, daily rewards, and world settings.
- The shared pickaxe catalog defines ten pickaxe tiers, each with coin payouts, geode chance, weighted geode tables, rarity tier, display color, and per-tier `cooldownSeconds`.
- Deterministic shared domain modules exist for economy, placement, geode state, geode rolling, mining rewards, station assignment, shop rotation, trait rolling, Vault sell values, and offline math.
- HUD panels cover plot state, daily rewards, offline rewards, overview, and announcements, with a large bottom-left coin counter and Vault button as the primary player-facing HUD. The legacy Geode Inventory panel remains in the UI shell but is currently hidden.
- A mine exists on the west no-plot side of the shared world plate.
- The mine sign is attached to the mine face so it reads as part of the mine facade.
- A roofless pickaxe shop exists on the east no-plot side of the shared world plate and sells pickaxes only.
- The pickaxe shop menu displays the full pickaxe catalog with equipped, upgrade, and locked lower-tier states.
- Players start with a Stone Pickaxe.
- The currently owned pickaxe mirrors into a server-owned Roblox `Tool` instance in `Backpack` and `StarterGear`.
- Mining is server-authoritative through `RequestMine`; the server requires the player to be standing inside the mine zone before valid mining rolls grant either coins or an owned geode instance.
- Pickaxe upgrades replace the player's current pickaxe instead of accumulating multiple owned pickaxes, and all current pickaxes cost coins.
- Pickaxe tools now include a centered held pickaxe model with a wooden handle and connected catalog-tinted metal head, matching the shop display style.
- Equipped pickaxes play a short local swing animation when the player clicks with one held.
- Players can sprint by holding Left Shift, which increases walk speed from 16 to 28. Speed resets on release or respawn.
- Geodes and revealed resources live in the Vault instead of the Roblox backpack.
- Players can choose a Vault geode or resource, see a transparent placement ghost, and place it onto their own plot grid.
- Vault rows now show size information for both geodes and resources, including the display category and numeric scale multiplier.
- Vault selling is server-authoritative and awards coins from deterministic geode/resource sell value math.
- Placed geodes render in the world and progress toward ready state. Cracking geodes now show a live countdown above the world model until they become ready.
- Ready geodes can be clicked in the world to crack open.
- Cracking a geode grants a resource into the Vault and removes the geode from placed state.
- Revealed resources can now roll independent collectible attributes (see full list under Implemented Content). Attributes are stored on the resource instance through `traitId` and increase resource sell value through deterministic multiplier math.
- Geodes receive a random numeric size scale when mined. That scale resolves into the existing size categories (Tiny, Small, Medium, Large, Huge, Colossal), carries over to the resource on cracking, and now makes geode/resource placement ghosts plus placed geodes/resources physically larger or smaller in the world. Placed resources now scale their actual root world part from that size value instead of only scaling decorative child visuals.
- Placed resources render directly on the player's plot.
- Placed resource nameplates now stay hidden until the player's mouse is hovering that specific placed resource, and hover labels reliably show the resolved resource name even if the world marker needs to rebuild from replicated attributes.
- Placed resources now use five procedural visual families chosen per resource definition: gemstone, cluster, artifact, ingot, and eldritch. Gemstone/cluster/artifact resources keep the crystal-ore language inspired by `reference/Blue_Crystal_Ore.webp`, while ingots read as dense raw trade materials and eldritch resources read as otherworldly relics. All resource visuals scale by a `sizeId` field (tiny/small/medium/large/huge/colossal) defined in `src/shared/Config/Sizes.luau`.
- Placed resource clusters and their placement ghosts now sit on the plot surface instead of hovering above it, keeping the rock base grounded like the `reference/modo.png` target.
- Starter station placement works, including deterministic first-fit placement when coordinates are not provided.
- Station assignment and passive income systems still exist, but geode cracking now puts revealed resources in the Vault first instead of immediately auto-slotting them.
- Passive income accrues online.
- Offline reward summaries work.
- Offline geode progress preserves finished geodes as ready to open instead of auto-opening them.
- World replica renders plots, stations, displayed resources, placed resources, geodes, the mine, and the pickaxe shop.
- A lightweight local geode reveal effect exists. Mining geode drops show a rarity-scaled discovery popup (bigger, bolder, longer duration at higher rarities) without rolling. Cracking a geode now bursts open into a floating crystal-ore reveal model that reuses the resource silhouette language instead of the old placeholder orb, then triggers two sequential single-reel rolls: first the resource reel spins and lands on the base resource, then the attribute reel spins and lands if a non-none attribute was rolled. Resource and attribute names stay hidden until their reel finishes so the outcome is not revealed early. The click-to-continue pause between these rolls now advances on left click or touch while the prompt is visible, and the prompt text has dedicated layout space instead of being clipped at the popup edge. The Geode Inventory HUD panel is hidden.
- Daily rewards, pickaxe shop rotation data, and rare reveal announcements are represented in the current slice.
- `rojo build default.project.json -o build-check.rbxlx` has succeeded locally.

## Current MVP Loop

1. Equip a pickaxe from the Roblox backpack.
2. Click inside the mine to earn coins or geodes.
3. Upgrade pickaxes at the pickaxe shop to improve coin payouts and rare geode odds; each upgrade replaces the previous pickaxe.
4. Open the Vault and place a geode onto your plot, or sell extra geodes.
5. Wait for the timer to finish.
6. Click the ready geode on the plot to crack it open.
7. Keep the revealed resource in the Vault, place it on the plot, or sell it.
8. Place the starter station.
9. Watch station and passive income flows continue to mature.

## Implemented Content

- Geodes: Starter Geode, Crystal Cavern Geode, Moonlit Geode, Ember Glass Geode, Verdant Rift Geode, Aurora Shard Geode, Thunder Core Geode, Fossil Vault Geode, Prism Sun Geode, Sovereign Nova Geode.
- Pickaxes: Stone Pickaxe, Copper Pickaxe, Iron Pickaxe, Steel Pickaxe, Gold Pickaxe, Platinum Pickaxe, Emerald Pickaxe, Obsidian Pickaxe, Lunar Pickaxe, Crown Pickaxe.
- Resources:
  Quartz, Rose Quartz, Smoky Quartz, Jade Fragment, Copper Nugget,
  Amethyst, Moonstone, Garnet Node, Topaz Vein, Silver Ingot,
  Emerald Cluster, Ruby Cluster, Sapphire Spire, Peridot Bloom, Gold Ingot,
  Diamond Core, Black Opal, Aetherite Relic, Mythril Ingot, Voidglass Core,
  Star Shard, Phoenix Amber, Astral Reliquary, Worldseed, Celestium Ingot.
- Resource attributes: None, Fiery, Frosted, Verdant, Radiant, Prismatic, Celestial, Void-Touched, Starlit, Cosmic, Singularity.
- Sizes: Numeric scale values bucketed into Tiny, Small, Medium, Large, Huge, and Colossal.
- Stations: Crystal Display, Resonance Pedestal.
- Core progression: coins, mining, pickaxe buying, Vault storage, item selling, geode/resource placement, cracking, station assignment, passive income, offline rewards.

## In Progress

- `GeodeQueueService` manages geode queue cache sync, claimable entries, and timed geode lifecycle management on the server.
- More Studio playtesting is needed for mining, pickaxe purchases, placement, cracking, reconnect, and offline edge cases.
- Mining click feedback now includes bubbly Fredoka-style center-screen action popups for rewards and important mining prompts. Geode discoveries use a rarity-scaled popup (size, text, duration, and border all grow with rarity) instead of slot-machine reels. Slot-machine reels are reserved for geode cracking and resource reveals.
- Placement UX uses transparent geode and resource ghost previews that reflect rolled size, but item art and interaction polish still need playtesting.
- The reveal effect is client-side and lightweight, while placed-resource visuals are replicated through the server world projection.
- Specs exist under `tests/`, but a terminal-integrated automated Luau test runner is not wired in yet.
- World visuals are readable for debugging but still need stronger cave/factory art direction.
- Move and upgrade flows are present in the remote plan but not fully built out as complete player-facing systems. `RequestMovePlacedObject` and `RequestUpgradeStation` remotes exist but currently return `not_implemented`. `RequestBuyGeode` returns `geode_shop_removed`; geodes now come only from mining.
- Vault sell values, resource placement, remote names, and geode tool cleanup have focused specs, but need Studio playtesting for the final UI feel.

## Next Up

- Playtest the full mine-to-Vault-to-geode-to-resource lifecycle in Studio and record reproducible edge cases.
- Playtest pickaxe Tool sync and held model alignment across respawn.
- Playtest mine standing-zone validation, mine target hit detection, and reward messages.
- Playtest Vault place/sell actions, especially resource placement on plot edges, occupied cells, and after reconnect.
- Continue tuning mining feedback timing and presentation after Studio playtests.
- Continue tuning the upgraded geode cracking feedback after Studio playtests, especially shell timing, hover motion, and trait readability.
- Add or document a repeatable local way to execute the Luau specs outside manual Studio checks.
- Implement player-facing move and upgrade flows for placed objects.
- Continue replacing debug-style world visuals with richer cave and factory presentation.

## Architecture Notes

- `src/shared` holds deterministic rules, configs, types, remote names, and utility modules.
- Resource attribute odds, multipliers, and presentation metadata live in `src/shared/Config/Traits.luau`; deterministic reveal classification helpers live in `src/shared/Domain/RewardPresentation.luau`.
- Geode countdown text and staged reveal visibility rules live in `src/shared/Domain/GeodePresentation.luau`.
- Size bucket definitions (weights, numeric scale ranges, default scales, sell multipliers) live in `src/shared/Config/Sizes.luau`; range resolution lives in `src/shared/Domain/SizeRules.luau`; the weighted roller lives in `src/shared/Domain/SizeRoller.luau`.
- Shared reveal visual profiles for floating crack reveals live in `src/shared/Domain/ResourceVisuals.luau`.
- `src/server` owns profile mutation, mining rolls, pickaxe purchases, economy, placement validation, plot assignment, offline progress, and world replication.
- `GeodeQueueService` (`src/server/Services/`) manages geode queue cache sync, claimable entries, and auto-open flows.
- `RareAnnouncementSystem` (`src/server/Systems/`) handles rare reveal broadcasts to all players.
- `PickaxeModelBuilder` (`src/server/Util/`) constructs held pickaxe models with catalog-tinted heads.
- `src/client` owns HUD construction, input controllers, local presentation, and action requests.
- Client UI is organized under `UI/Components/Panel.luau`, `UI/Screens/RootScreen.luau`, and `UI/Theme/Palette.luau`.
- `SprintController` (`src/client/Controllers/`) manages Left Shift sprint behavior.
- `NotificationsController` (`src/client/Controllers/`) drives center-screen action popups for rewards and prompts.
- Workspace objects are a projection of authoritative state, not the source of truth.
- Mining rewards are rolled on the server; the client only requests mining after a local mine-target click.
- Vault sell and placement requests are validated by the server before profile mutation.
- Geode and resource Vault placement both reuse shared grid occupancy rules through server placement services.
- The important geode state distinction is owned, placed, ready, and cracked/opened.

## Verification Notes

- Run `rojo build default.project.json -o build-check.rbxlx` after structural changes.
- Twenty-two spec files currently live in `tests/`: EconomyMath, GeodeLifecycle, GeodePresentation, GeodeRoller, GeodeState, GeodeToolService, MiningRewards, MiningService, OfflineMath, PlacementRules, RemoteNames, Resources, ResourceVisuals, RewardPresentation, ShopCatalog, ShopRotation, SizeRoller, SizeRules, StationAssignment, VaultMath, VaultService, and WorldLabelPresentation.
- The repo does not yet have a terminal test command, so new deterministic logic should either add specs for future runner use or be accompanied by a small reproducible validation path.
