# Current State

## Summary

Gem Factory is at a mine-first MVP stage in Roblox Studio. The current early loop is mine-first: players equip a pickaxe, click inside the mine to earn either coins or geodes, open the Vault to place or sell owned geodes, wait for placed geodes to finish, crack ready geodes in the world, store revealed resources in the Vault, and either place, pick up, or sell those resources.

The project is still a prototype. The backend gameplay slice is more complete than the presentation layer, persistence is still mocked for development, and the repo is being documented for agent-friendly maintenance through synchronized docs plus concise module comments in the Luau source tree.

## What Works

- Rojo project mapping is defined in `default.project.json`.
- Server and client bootstraps are wired through `src/server/init.server.luau` and `src/client/init.client.luau`.
- Shared cavern world supports up to 8 assigned player plots.
- Player profiles load through `MockPersistenceService` and reconcile into the current profile schema (schema version 3). New players start with 250 coins and 10 gems.
- Remote names and remote setup are centralized under `src/shared/Net`.
- Shared config exists for resources, geodes, traits, stations, economy, shops, pickaxes, daily rewards, and world settings.
- The shared pickaxe catalog defines ten pickaxe tiers, each with coin payouts, scaled geode chance, weighted geode tables, rarity tier, display color, and per-tier `cooldownSeconds`. The catalog now uses a steeper coin-price ladder tuned around expected mining income, and a shared config scale makes geodes roughly half as common as the previous live tuning while preserving each pickaxe's relative rarity ladder.
- Deterministic shared domain modules exist for economy, placement, geode state, geode rolling, mining rewards, station assignment, shop rotation, trait rolling, Vault sell values, and offline math.
- HUD panels cover plot state, daily rewards, offline rewards, overview, and announcements, with a large bottom-left coin counter and Vault button as the primary player-facing HUD. A bubbly bottom-right Resource Guide button now opens a large two-tab guide: a visible color-coded rarity chart derived from the actual mining path for the currently equipped pickaxe, plus a collection page with one slot per resource ordered by rarity, shadowed unknown finds, and hover details for discovered resource attributes. The legacy Geode Inventory panel remains in the UI shell but is currently hidden.
- Players can also open the Vault from a server-authored world prompt by pressing `E` at a lightweight shared-world Vault marker, without replacing the existing HUD Vault button or relying on a physical Vault prop.
- A mine exists on the west no-plot side of the shared world plate.
- The mine sign is attached to the mine face so it reads as part of the mine facade, its billboard copy now reads `Mine here to gather Geodes!`, and that callout hides for the nearby player while they are standing inside or right up on the mine.
- A roofless pickaxe shop exists on the east no-plot side of the shared world plate and sells pickaxes only.
- The pickaxe shop world callout now reads `Buy pickaxes here!` and hides for the nearby player when they walk up to the forge instead of staying in their face at close range.
- The mine and pickaxe shop facades now include extra server-authored seam fillers that close the visible cave-wall gaps behind those structures without moving ownership out of `WorldReplicaService`.
- The shared baseplate now reads as grassy terrain, the lighting and skybox lean into a brighter galaxy mood with planets, a denser starfield, and shooting-star dressing, and cave-like perimeter walls with even more embedded crystals now frame the play space without the oversized nebula bubbles.
- The pickaxe shop menu displays the full pickaxe catalog with equipped, upgrade, and locked lower-tier states, using a bubblier kid-friendly card layout that matches the coin counter, Vault, and Resource Guide more closely than the older utilitarian pass. The shop list and tier ladder now share one vertical scroll path, the clipped card-border and bottom-tier issues have been corrected for shorter screens, and each pickaxe card uses a distinct tier mark instead of the old repeated `POW` placeholder.
- Players start with a Stone Pickaxe.
- The currently owned pickaxe mirrors into a server-owned Roblox `Tool` instance in `Backpack` and `StarterGear`.
- Mining is server-authoritative through `RequestMine`; the server requires the player to be standing inside the mine zone before valid mining rolls grant either coins or an owned geode instance.
- Pickaxe upgrades replace the player's current pickaxe instead of accumulating multiple owned pickaxes, and all current pickaxes cost coins.
- Pickaxe tools now include a centered held pickaxe model with a wooden handle and connected catalog-tinted metal head, matching the shop display style.
- Equipped pickaxes play a short local swing animation when the player clicks with one held.
- Players can sprint by holding Left Shift, which increases walk speed from 16 to 28. Speed resets on release or respawn.
- Geodes and revealed resources live in the Vault instead of the Roblox backpack.
- Players can choose a Vault geode or resource, see a transparent model-style placement ghost that better matches the item being placed, and place it onto their own plot grid.
- Plot surfaces now include an invisible server-authored collider aligned to the visible trim layer, so players stand on the plot floor instead of falling through the thin decorative surface.
- Plots now include several extra cave-styled display stands, shelves, and alcove benches that make the buildable area feel fuller without changing the authoritative placement plane or hover/placement targeting rules. Those decorative stands now render slightly above the visible plot trim instead of clipping into it, their layered top materials are vertically separated so the short stands no longer show seam/z-fighting artifacts, their old neon/glowy accents were replaced with more grounded cave-factory materials, and the visible line strips on the raised platforms have been removed.
- Vault rows now show size information for both geodes and resources, including the display category and numeric scale multiplier.
- Vault selling is server-authoritative and awards coins from deterministic geode/resource sell value math.
- Placed resources can now be picked back up into the Vault through a server-authoritative Vault action, which clears their occupied plot cells without relying on client-only world state.
- Placed geodes render in the world and progress toward ready state. Cracking geodes now show a live countdown above the world model until they become ready, using a 30-second common baseline that ramps up through clean stepped waits to a 200-second capstone at the rarest tier.
- Ready geodes can be clicked in the world to crack open.
- Cracking a geode grants a resource into the Vault and removes the geode from placed state.
- Revealed resources can now roll independent collectible attributes (see full list under Implemented Content). Attributes are stored on the resource instance through `traitId` and increase resource sell value through deterministic multiplier math.
- Resource Guide collection progress is now server-authoritative and persisted in profile data. Players permanently record which base resources they have found and which non-none attributes they have discovered on each resource, with tracking updated from geode opens and daily resource rewards.
- Geodes receive a random numeric size scale when mined. That scale resolves into the existing size categories (Tiny, Small, Medium, Large, Huge, Colossal), carries over to the resource on cracking, and now makes geode/resource placement ghosts plus placed geodes/resources physically larger or smaller in the world. Placed resources now scale their actual root world part from that size value instead of only scaling decorative child visuals, and resource visuals apply a shared 3x baseline multiplier on top of the rolled size so default finds read much larger without changing size bucket odds, labels, or sell math.
- Placed resources render directly on the player's plot.
- Placed resources and their placement ghosts now ground against the visible plot trim/collider instead of the lower base slab, preventing the slight floor clipping that used to show through the thin transparent plot layer. The ghost now reuses the deterministic placed-resource visual profile/layout path so the preview stays visible, grounded, and silhouette-matched with the final placed object.
- Placed resource nameplates now stay hidden until the player's mouse is hovering that specific placed resource, and hover labels reliably show the resolved resource name even when the player is hovering decorative child parts instead of the root world part.
- Placed resources now use deterministic procedural visual families chosen per resource definition: gemstone, cluster, artifact, ingot, eldritch, and a dedicated moonstone family. Gemstone/cluster/artifact resources keep the crystal-ore language inspired by `reference/Blue_Crystal_Ore.webp`, ingots read as dense raw trade materials, eldritch resources read as otherworldly relics, and Moonstone now reads as a tiny iridescent moon. All resource visuals scale by a `sizeId` field (tiny/small/medium/large/huge/colossal) defined in `src/shared/Config/Sizes.luau`.
- Resource ghost and world-replica builders now prefer deterministic procedural layout data from `src/shared/Domain/ResourceVisuals.luau` when that API is present, while still falling back cleanly to the current shard-definition helpers during the transition.
- Placed resource clusters and their placement ghosts now sit on the plot surface instead of hovering above it, keeping the rock base grounded like the `reference/modo.png` target.
- Trait-bearing placed resources now use stronger world-space presentation, including clearer aura/band/crest silhouettes and more attribute-matched particles so rolled attributes read at a glance.
- Starter station placement works, including deterministic first-fit placement when coordinates are not provided.
- Station assignment and passive income systems still exist, but geode cracking now puts revealed resources in the Vault first instead of immediately auto-slotting them.
- Passive income accrues online.
- Offline reward summaries work.
- Offline geode progress preserves finished geodes as ready to open instead of auto-opening them.
- World replica renders plots, stations, displayed resources, placed resources, geodes, the mine, and the pickaxe shop.
- A lightweight local geode reveal effect exists. Mining geode drops show a rarity-scaled discovery popup (bigger, bolder, longer duration at higher rarities) without rolling, while coin rewards now pop as lighter text-only `+x coins` bursts with a wider center-screen spread instead of stacking in a narrow lane or using a boxed background. Cracking a geode now bursts open into a floating crystal-ore reveal model that reuses the resource silhouette language instead of the old placeholder orb, then triggers two sequential single-reel rolls: first the resource reel spins and lands on the base resource, then the attribute reel spins and lands if a non-none attribute was rolled. Resource and attribute names stay hidden until their reel finishes so the outcome is not revealed early, and the reel palette now flashes through the currently displayed rarity or attribute colors instead of revealing the final tone ahead of time. The geode shell and reveal effect now stay alive until the active celebration popup and any queued follow-up reel finish, so the crack animation no longer fades out before the roll sequence resolves. The click-to-continue handoff footer now appears only after the current reel finishes, no longer expands into a giant empty panel, and resource-to-attribute handoffs auto-advance after a short delay while still accepting an immediate click or touch. Local HUD audio now adds small discovery and reveal chimes tied to geode-find rarity plus cracked-resource and attribute reel reveals. The Geode Inventory HUD panel is hidden.
- Daily rewards, pickaxe shop rotation data, and rare reveal announcements are represented in the current slice.
- `rojo build default.project.json -o build-check.rbxlx` has succeeded locally.

## Current MVP Loop

1. Equip a pickaxe from the Roblox backpack.
2. Click inside the mine to earn coins or geodes.
3. Upgrade pickaxes at the pickaxe shop to improve coin payouts and rare geode odds; each upgrade replaces the previous pickaxe.
4. Open the Vault and place a geode onto your plot, or sell extra geodes.
5. Wait for the timer to finish.
6. Click the ready geode on the plot to crack it open.
7. Keep the revealed resource in the Vault, place it on the plot, pick it back up later, or sell it.
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
- Mining click feedback now includes bubbly Fredoka-style center-screen action popups for rewards and important mining prompts. Geode discoveries use a rarity-scaled popup (size, text, duration, and border all grow with rarity) instead of slot-machine reels, while coin payouts now use larger text-only popups with light center-screen variance. Slot-machine reels are reserved for geode cracking and resource reveals.
- Placement UX uses transparent geode and resource ghost previews that reflect rolled size and now mimic the placed item silhouettes more closely, but final art and interaction polish still need playtesting.
- The reveal effect is client-side and lightweight, while placed-resource visuals are replicated through the server world projection.
- Specs exist under `tests/`, but a terminal-integrated automated Luau test runner is not wired in yet.
- The static world now has a stronger cave/factory presentation pass, but still needs Studio playtesting and taste-tuning for final art direction.
- Move and upgrade flows are present in the remote plan but not fully built out as complete player-facing systems. `RequestMovePlacedObject` and `RequestUpgradeStation` remotes exist but currently return `not_implemented`. `RequestBuyGeode` returns `geode_shop_removed`; geodes now come only from mining.
- Vault sell values, resource placement and pickup, remote names, and geode tool cleanup have focused specs, but need Studio playtesting for the final UI feel.

## Next Up

- Playtest the full mine-to-Vault-to-geode-to-resource lifecycle in Studio and record reproducible edge cases.
- Playtest pickaxe Tool sync and held model alignment across respawn.
- Playtest mine standing-zone validation, mine target hit detection, and reward messages.
- Playtest Vault place/pick-up/sell actions, especially resource placement on plot edges, occupied cells, and after reconnect.
- Continue tuning mining feedback timing and presentation after Studio playtests, especially the new wider coin-popup spread on different aspect ratios.
- Continue tuning the upgraded geode cracking feedback after Studio playtests, especially the auto-advance timing and overall handoff feel between the resource and attribute reels.
- Add or document a repeatable local way to execute the Luau specs outside manual Studio checks.
- Implement player-facing move and upgrade flows for placed objects.
- Continue replacing debug-style world visuals with richer cave and factory presentation.

## Architecture Notes

- `src/shared` holds deterministic rules, configs, types, remote names, and utility modules.
- Resource attribute odds, multipliers, and presentation metadata live in `src/shared/Config/Traits.luau`; deterministic reveal classification helpers live in `src/shared/Domain/RewardPresentation.luau`.
- Resource Guide chart rows, collection-slot ordering, equipped-pickaxe probability labels, and persisted collection helpers live in `src/shared/Domain/ResourceGuide.luau` so the HUD does not hard-code rarity data or collection progression rules.
- Geode countdown text and staged reveal visibility rules live in `src/shared/Domain/GeodePresentation.luau`.
- Size bucket definitions (weights, numeric scale ranges, default scales, sell multipliers, and the shared resource-visual baseline multiplier) live in `src/shared/Config/Sizes.luau`; range resolution lives in `src/shared/Domain/SizeRules.luau`; the weighted roller lives in `src/shared/Domain/SizeRoller.luau`.
- Shared reveal visual profiles for floating crack reveals live in `src/shared/Domain/ResourceVisuals.luau`.
- Placed-resource consumers on the client and server are now structured to accept future deterministic procedural layout tables from `ResourceVisuals` without moving placement grounding or other server-authoritative world projection decisions into shared or client-only code.
- `src/server` owns profile mutation, mining rolls, pickaxe purchases, economy, placement validation, plot assignment, offline progress, and world replication.
- `WorldReplicaService` (`src/server/Services/`) now layers decorative plot display surfaces onto each plot, authors the shared-world cave shell/sky dressing plus the prompt-led Vault marker, and keeps placement and hover interactions pinned to the existing server-authored plot surface collider.
- `GeodeQueueService` (`src/server/Services/`) manages geode queue cache sync, claimable entries, and auto-open flows.
- `RareAnnouncementSystem` (`src/server/Systems/`) handles rare reveal broadcasts to all players.
- `PickaxeModelBuilder` (`src/server/Util/`) constructs held pickaxe models with catalog-tinted heads.
- `src/client` owns HUD construction, input controllers, local presentation, and action requests.
- Client UI is organized under `UI/Components/Panel.luau`, `UI/Screens/RootScreen.luau`, and `UI/Theme/Palette.luau`.
- `SprintController` (`src/client/Controllers/`) manages Left Shift sprint behavior.
- `VaultController` (`src/client/Controllers/`) now handles both the HUD Vault flow and the server-authored `E` prompt at the shared-world Vault marker.
- `NotificationsController` (`src/client/Controllers/`) drives center-screen action popups for rewards and prompts.
- Non-trivial Luau modules are expected to carry short purpose comments so future agents can identify ownership and trace data flow without re-reading the entire repo first.
- Workspace objects are a projection of authoritative state, not the source of truth.
- Mining rewards are rolled on the server; the client only requests mining after a local mine-target click.
- Vault sell, placement, and pickup requests are validated by the server before profile mutation.
- Geode and resource Vault placement both reuse shared grid occupancy rules through server placement services.
- The important geode state distinction is owned, placed, ready, and cracked/opened.

## Verification Notes

- Run `rojo build default.project.json -o build-check.rbxlx` after structural changes.
- Twenty-six spec files currently live in `tests/`: EconomyMath, GeodeLifecycle, GeodePresentation, GeodeRoller, Geodes, GeodeState, GeodeToolService, MiningRewards, MiningService, OfflineMath, PlacementRules, RemoteNames, ResourceGuide, ResourceGuideTracking, Resources, ResourceVisuals, RewardPresentation, ShopCatalog, ShopRotation, SizeRoller, SizeRules, StationAssignment, VaultMath, VaultService, WorldLabelPresentation, and WorldReplicaService.
- The repo does not yet have a terminal test command, so new deterministic logic should either add specs for future runner use or be accompanied by a small reproducible validation path.
