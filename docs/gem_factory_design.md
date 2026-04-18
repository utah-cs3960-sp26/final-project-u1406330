# Gem Factory Design Document

## Overview

Gem Factory is a Roblox idle progression game about turning a rough cave plot into a glowing gem operation. Players mine for coins and geodes, manage finds through a Vault, wait for placed geodes to crack, reveal resources, and reinvest coins into better pickaxes, rarer finds, and better production systems.

The current implementation is a narrow MVP slice of this design. Anything listed as future direction should be treated as product intent, not current behavior. For current behavior, read [current_state.md](current_state.md). For implementation guidance, also read [../agents.md](../agents.md), which requires code comments that explain module ownership and non-obvious flow.

## Core Fantasy

The player starts with a small cave lot and slowly turns it into a richer gem factory filled with crystal displays, rare minerals, glowing machinery, and valuable finds.

The main emotional hooks are:

1. Owning and improving a personal cave-factory.
2. Anticipating a geode reveal.
3. Chasing rare resources and collectible attributes.
4. Watching the plot fill with placed geodes, resources, and stations.
5. Returning to timers, restocks, and offline rewards.

## Current MVP Loop

1. Equip a pickaxe.
2. Mine for coins or geodes.
3. Open the Vault to place or sell an owned geode.
4. Wait for its timer to finish.
5. Crack the ready geode in the world.
6. Store revealed resources in the Vault.
7. Place or sell resources from the Vault.
8. Use station and passive-income systems as those flows expand.

## Current MVP Systems

### Geodes

Geodes are earned through mining, stored in the Vault, placed on the plot, sold, and opened after their timer completes. Players must stand inside the mine to mine. Each geode receives a random numeric size scale when mined. That scale falls into the existing size categories (Tiny, Small, Medium, Large, Huge, or Colossal), with larger ranges being rarer. Size carries over to the revealed resource on cracking and should be visible physically in placement previews, placed world models, and player-facing descriptions. While a geode is cracking on the plot, its world label should show a live countdown until it becomes ready.

### Pickaxes

Pickaxes are purchased from the pickaxe shop as strict upgrades. All current pickaxes cost coins. Better pickaxes improve coin payouts and shift mining geode weights toward rarer geodes, and buying a higher-tier pickaxe replaces the player's current one instead of stacking owned tools. Geode buying through the shop has been removed — geodes now come exclusively from mining. The `RequestBuyGeode` remote returns `geode_shop_removed`.

Implemented geodes:

1. Starter Geode.
2. Crystal Cavern Geode.
3. Moonlit Geode.
4. Ember Glass Geode.
5. Verdant Rift Geode.
6. Aurora Shard Geode.
7. Thunder Core Geode.
8. Fossil Vault Geode.
9. Prism Sun Geode.
10. Sovereign Nova Geode.

Implemented pickaxes:

1. Stone Pickaxe.
2. Copper Pickaxe.
3. Iron Pickaxe.
4. Steel Pickaxe.
5. Gold Pickaxe.
6. Platinum Pickaxe.
7. Emerald Pickaxe.
8. Obsidian Pickaxe.
9. Lunar Pickaxe.
10. Crown Pickaxe.

### Resources

Resources are revealed from geodes and stored in the Vault. Players can place them on their own plot or sell them for coins. Resources enter the Vault first from geode reveals, before any station interaction. Station assignment remains the route for passive income when a station flow claims a resource. The current reveal presentation uses sequential reels: first the base resource, then the attribute if one was rolled, and those labels should stay hidden until each reel resolves.

Resources can also roll an independent attribute. Attributes create distinct collectible finds such as Fiery Quartz or Singularity Star Shard, add a visible effect, and currently increase sell value through a multiplier. Attribute rarity is independent from base resource rarity so even common resources can occasionally become special.

Resources also inherit a numeric size scale from the geode they came from. Six display categories exist — Tiny, Small, Medium, Large, Huge, and Colossal — and each category maps to a numeric scale range defined in `src/shared/Config/Sizes.luau`. Bigger sizes are rarer (Small is the most common, Colossal is the rarest). Size affects placed resource visual scale and sell value through the resolved category multiplier, and size information is surfaced in player-facing descriptions.

Implemented resources:

1. Quartz.
2. Rose Quartz.
3. Smoky Quartz.
4. Jade Fragment.
5. Copper Nugget.
6. Amethyst.
7. Moonstone.
8. Garnet Node.
9. Topaz Vein.
10. Silver Ingot.
11. Emerald Cluster.
12. Ruby Cluster.
13. Sapphire Spire.
14. Peridot Bloom.
15. Gold Ingot.
16. Diamond Core.
17. Black Opal.
18. Aetherite Relic.
19. Mythril Ingot.
20. Voidglass Core.
21. Star Shard.
22. Phoenix Amber.
23. Astral Reliquary.
24. Worldseed.
25. Celestium Ingot.

Implemented visual families:

1. Gemstone.
2. Cluster.
3. Artifact.
4. Ingot.
5. Eldritch.

Implemented resource attributes:

1. None.
2. Fiery.
3. Frosted.
4. Verdant.
5. Radiant.
6. Prismatic.
7. Celestial.
8. Void-Touched.
9. Starlit.
10. Cosmic.
11. Singularity.

### Stations

Stations hold resources and multiply or enable passive income. In the current slice, station systems exist, but the player-facing reveal path now sends resources to the Vault before any later station flow uses them.

Implemented stations:

1. Crystal Display.
2. Resonance Pedestal.

### Passive And Offline Progress

Passive income should continue to matter even when the player is away. The current slice supports online passive income and offline reward summaries through the existing station economy. Finished offline geodes remain ready to open instead of being auto-opened.

### Mine, Shop, And Daily Hooks

The current project includes a geode mine, pickaxe shop, shop rotation data, and daily reward systems. Daily rewards include coins, geodes, boosts, tokens, gems, and resources across a 7-day streak cycle with a 48-hour reset window. These are meant to create recurring reasons to check in without requiring deep mechanics yet.

## Design Principles

### Idle Progression

Players should feel progress continuing while they are not actively playing. Offline rewards should be understandable and should avoid surprising state changes, especially around geode reveals.

### Variable Rewards

Geode rewards should use weighted pools. Attribute rolls should make ordinary resources occasionally feel special, and reward presentation should clearly communicate when a player found something above Common.

### Timed Scarcity

Hourly rotations, daily rewards, and future event geodes should give players reasons to return.

### Visible Growth

The cave should physically improve as the player gains better geodes, resources, attributes, stations, and production capacity. Placed Vault resources should make progress visible even before deeper station flows are polished, using distinct visual models and effects for different resource and attribute rarities.

### Server Authority

The server owns purchases, reward rolls, placement validation, profile mutation, and offline calculation. The client presents state and requests actions.

## Future Direction

The following systems are design targets, not all current implementation:

- More geode categories such as biome, premium, event, and achievement geodes.
- More resources, attributes, and rarity tiers.
- Station upgrades and specialized station roles.
- Refinement or duplicate-combining systems.
- Cave zone unlocks.
- Prestige with permanent bonuses.
- Weekly events and limited geode pools.
- Stronger social comparison through nearby plots, leaderboards, and rare reveal announcements.
- Real persistence, migration tooling, analytics, and admin/debug tools.

## Technical Direction

### Server Responsibilities

1. Validate purchases, mining, and placement.
2. Roll mining rewards and geode outcomes.
3. Mutate player profiles.
4. Calculate online and offline rewards.
5. Maintain plot assignment.
6. Replicate authoritative world state.
7. Prevent duplication exploits.
8. Manage geode queue lifecycle and timed geode completion.

### Client Responsibilities

1. Build and update HUD.
2. Handle placement input and local previews.
3. Request actions through remotes.
4. Render local presentation effects.
5. Display timers, rewards, announcements, and shop state.
6. Handle sprint input.

### Shared Responsibilities

1. Static config.
2. Deterministic math.
3. Type definitions.
4. Remote names.
5. Small reusable utilities.

## MVP Priorities

The most important near-term work is:

1. Make the first mine-to-Vault-to-reveal loop stable and easy to understand.
2. Improve placement clarity.
3. Make geode reveals feel rewarding.
4. Add repeatable automated verification for deterministic specs.
5. Keep profile, economy, placement, and offline logic testable.
