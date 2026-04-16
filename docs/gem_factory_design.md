# Gem Factory Design Document

## Overview

Gem Factory is a Roblox idle progression game about turning a rough cave plot into a glowing gem operation. Players mine for coins and geodes, manage finds through a Vault, wait for placed geodes to crack, reveal resources, and reinvest coins into better pickaxes, rarer finds, and better production systems.

The current implementation is a narrow MVP slice of this design. Anything listed as future direction should be treated as product intent, not current behavior. For current behavior, read [current_state.md](current_state.md).

## Core Fantasy

The player starts with a small cave lot and slowly turns it into a richer gem factory filled with crystal displays, rare minerals, glowing machinery, and valuable finds.

The main emotional hooks are:

1. Owning and improving a personal cave-factory.
2. Anticipating a geode reveal.
3. Chasing rare resources and traits.
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

Geodes are earned through mining, stored in the Vault, placed on the plot, sold, and opened after their timer completes. Players must stand inside the mine to mine.

### Pickaxes

Pickaxes are permanent one-time purchases from the pickaxe shop. All current pickaxes cost coins. Better pickaxes improve coin payouts and shift mining geode weights toward rarer geodes.

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

Resources are revealed from geodes and stored in the Vault. Players can place them on their own plot or sell them for coins. Station assignment remains the route for passive income when a station flow claims a resource.

Implemented resources:

1. Quartz.
2. Amethyst.
3. Emerald Cluster.
4. Diamond Core.
5. Star Shard.

### Stations

Stations hold resources and multiply or enable passive income. In the current slice, station systems exist, but the player-facing reveal path now sends resources to the Vault before any later station flow uses them.

Implemented stations:

1. Crystal Display.
2. Resonance Pedestal.

### Passive And Offline Progress

Passive income should continue to matter even when the player is away. The current slice supports online passive income and offline reward summaries through the existing station economy. Finished offline geodes remain ready to open instead of being auto-opened.

### Mine, Shop, And Daily Hooks

The current project includes a geode mine, pickaxe shop, shop rotation data, and daily reward systems. These are meant to create recurring reasons to check in without requiring deep mechanics yet.

## Design Principles

### Idle Progression

Players should feel progress continuing while they are not actively playing. Offline rewards should be understandable and should avoid surprising state changes, especially around geode reveals.

### Variable Rewards

Geode rewards should use weighted pools. Trait rolls should make ordinary resources occasionally feel special.

### Timed Scarcity

Hourly rotations, daily rewards, and future event geodes should give players reasons to return.

### Visible Growth

The cave should physically improve as the player gains better geodes, resources, stations, and production capacity. Placed Vault resources should make progress visible even before deeper station flows are polished.

### Server Authority

The server owns purchases, reward rolls, placement validation, profile mutation, and offline calculation. The client presents state and requests actions.

## Future Direction

The following systems are design targets, not all current implementation:

- More geode categories such as biome, premium, event, and achievement geodes.
- More resources, traits, and rarity tiers.
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

### Client Responsibilities

1. Build and update HUD.
2. Handle placement input and local previews.
3. Request actions through remotes.
4. Render local presentation effects.
5. Display timers, rewards, announcements, and shop state.

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
